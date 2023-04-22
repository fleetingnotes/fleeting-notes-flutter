import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/models/url_metadata.dart';
import 'package:hive/hive.dart';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/Note.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/crypt.dart';
import 'package:collection/collection.dart';

enum SubscriptionTier { freeSub, basicSub, premiumSub, unknownSub }

enum RecoveredSessionEvent { noStoredSession, failed, succeeded }

class StoredSession {
  Session? session;
  String? subscriptionTier;
  StoredSession(this.session, this.subscriptionTier);
}

class SupabaseDB extends SyncTerface {
  SupabaseClient get client => Supabase.instance.client;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  StreamSubscription<AuthState>? authSubscription;
  StreamController<AuthChangeEvent?> authChangeController =
      StreamController<AuthChangeEvent?>.broadcast();
  final StreamController<NoteEvent> noteStreamController =
      StreamController.broadcast();
  @override
  Stream<NoteEvent> get noteStream => noteStreamController.stream;
  SupabaseDB() {
    prevUser = client.auth.currentUser;
    authSubscription?.cancel();
    authSubscription =
        client.auth.onAuthStateChange.listen(handleAuthStateChange);
  }
  User? get currUser => client.auth.currentUser;
  User? prevUser; // used for authStateChange
  SubscriptionTier? subTier;
  String? get userId =>
      (currUser?.userMetadata ?? {})['firebaseUid'] ?? currUser?.id;
  @override
  bool get canSync => currUser != null;

  // auth stuff
  Future<void> handleAuthStateChange(AuthState state) async {
    Session? session = state.session;
    if (prevUser?.id != session?.user.id) {
      authChangeController.add(state.event);
      if (session != null) {
        setSession();
      }
    }
    prevUser = session?.user;
  }

  Future<User?> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user;
    } on AuthException catch (e) {
      throw FleetingNotesException(e.message);
    }
  }

  Future<User> register(String email, String password,
      {String? firebaseUid}) async {
    try {
      var userMetadata =
          (firebaseUid == null) ? null : {"firebaseUid": firebaseUid};
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
      );
      var newUser = res.user;
      if (newUser == null) {
        throw FleetingNotesException('Registration failed');
      } else {
        return newUser;
      }
    } on AuthException catch (e) {
      throw FleetingNotesException('Registration failed: ${e.message}');
    }
  }

  Future<bool> logout() async {
    await clearSession();
    await client.auth.signOut();
    subTier = null;
    return true;
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // TODO: use a join table to only make 1 request
  Future<SubscriptionTier> getSubscriptionTier() async {
    SubscriptionTier? subscriptionTier = subTier;
    if (currUser == null) return SubscriptionTier.freeSub;
    if (subscriptionTier != null) return subscriptionTier;
    try {
      var subscriptionTierStr = await getSubscriptionTierFromTable('stripe');
      if (subscriptionTierStr == 'free') {
        subscriptionTierStr = await getSubscriptionTierFromTable('apple_iap');
      }
      switch (subscriptionTierStr) {
        case 'basic':
          subscriptionTier = SubscriptionTier.basicSub;
          break;
        case 'premium':
          subscriptionTier = SubscriptionTier.premiumSub;
          break;
        default:
          subscriptionTier = SubscriptionTier.freeSub;
      }
      subTier = subscriptionTier;
      return subscriptionTier;
    } catch (e) {
      debugPrint(e.toString());
      return SubscriptionTier.unknownSub;
    }
  }

  Future<String> getSubscriptionTierFromTable(String table,
      {String? userId}) async {
    userId ??= currUser?.id;
    List<dynamic> tableSubTier =
        await client.from(table).select('subscription_tier').eq('id', userId);

    var subscriptionTier =
        (tableSubTier.firstOrNull ?? {})['subscription_tier'] as String? ??
            'free';
    return subscriptionTier.isEmpty ? 'free' : subscriptionTier;
  }

  Future<UrlMetadata?> getUrlMetadata(String url) async {
    try {
      final res =
          await client.functions.invoke('get-metadata', body: {"url": url});
      final status = res.status;
      final ok = status != null && status >= 200 && status < 300;
      if (!ok) return null;
      Map<String, dynamic> json = res.data;
      return UrlMetadata(
        url: url,
        title: json['ogTitle'],
        description: json['ogDescription'],
        imageUrl: (json['ogImage'] != null) ? json['ogImage']['url'] : null,
      );
    } catch (e) {
      return null;
    }
  }

  // get, update, & delete notes
  Future<List<Note>> getAllNotes(
      {String? partition, DateTime? modifiedAfter}) async {
    var baseFilter = client.from('notes').select();
    baseFilter = (partition == null)
        ? baseFilter.in_('_partition', [userId, currUser?.id])
        : baseFilter.eq('_partition', partition);

    await upsertNotes([]); // pushes cached notes if any
    List<dynamic> supaNotes = (modifiedAfter == null)
        ? (await baseFilter)
        : (await baseFilter.gt(
            'modified_at', modifiedAfter.toUtc().toIso8601String()));
    String? encryptionKey = await getEncryptionKey();
    List<Note> notes = supaNotes
        .map((supaNote) =>
            fromSupabaseJson(supaNote, encryptionKey: encryptionKey))
        .toList();
    // TODO: intention is to refresh everytime user opens the app
    refreshSession();
    return notes;
  }

  Future<Note?> getNoteById(String id) async {
    var supaNote = await client.from('notes').select().eq('id', id).single();
    var encryptionKey = await getEncryptionKey();
    return fromSupabaseJson(supaNote, encryptionKey: encryptionKey);
  }

  @override
  Future<Iterable<Note?>> getNotesByIds(Iterable<String> ids) async {
    List<dynamic> supaNotes =
        await client.from('notes').select().in_('id', ids.toList());
    String? encryptionKey = await getEncryptionKey();
    Iterable<Note> notes =
        supaNotes.map((n) => fromSupabaseJson(n, encryptionKey: encryptionKey));
    return notes;
  }

  @override
  Future<void> deleteNotes(Iterable<String> ids) async {
    await client.from('notes').update({
      'modified_at': DateTime.now().toUtc().toIso8601String(),
      'deleted': true,
    }).in_('id', ids.toList());
  }

  @override
  Future<void> upsertNotes(Iterable<Note> notes) async {
    // recent notes override unsaved cache notes
    var notesCache = await getNotesCache();
    notesCache.addAll({for (var note in notes) note.id: note});
    notes = notesCache.values.toList();
    if (notes.isEmpty) return;

    // attempt to upsert notes to supabase
    try {
      String? encryptionKey = await getEncryptionKey();
      var supaNotes = notes
          .map((note) => toSupabaseJson(note, encryptionKey: encryptionKey))
          .toList();
      var res = await client.from('notes').upsert(supaNotes);
      if (res?.error != null) {
        throw FleetingNotesException("Failed to upsert note");
      }
      // clear note cache if successful
      await clearNotesCache();
    } catch (e) {
      // if failed http request
      debugPrint(e.toString());
      await saveNotesCache(notes);
      if (e is FleetingNotesException) rethrow;
    }
  }

  // cache for offline support
  Future<Box?> getNotesCacheBox() async {
    var currUserId = currUser?.id;
    if (currUserId != null) {
      return await Hive.openBox("$currUserId-notes-cache");
    }
    return null;
  }

  Future<Map<String, Note>> getNotesCache() async {
    var box = await getNotesCacheBox();
    Map<String, Note> mapping = {
      for (var note in box?.values ?? []) note.id: note
    };
    return mapping;
  }

  Future<void> saveNotesCache(Iterable<Note> notes) async {
    var box = await getNotesCacheBox();
    Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
    box?.putAll(noteIdMap);
  }

  Future<void> clearNotesCache() async {
    var box = await getNotesCacheBox();
    box?.clear();
  }

  // storage
  // TODO; double check this works
  Future<String> addAttachment(String filename, Uint8List? fileBytes) async {
    if (fileBytes == null || fileBytes.isEmpty) {
      throw FleetingNotesException('File is empty');
    }
    var isPaying = await getSubscriptionTier() != SubscriptionTier.freeSub;
    // TODO: add settings from remote config
    int maxSize = (isPaying) ? 25 : 10;
    if (fileBytes.lengthInBytes / 1000000 > maxSize) {
      throw FleetingNotesException('File cannot be larger than $maxSize MB');
    }
    final mimeType = lookupMimeType(filename, headerBytes: fileBytes);
    try {
      await client.storage.from('attachments').uploadBinary(filename, fileBytes,
          fileOptions: FileOptions(contentType: mimeType));

      final publicUrl =
          client.storage.from('attachments').getPublicUrl(filename);
      return publicUrl;
    } on StorageException catch (e) {
      if (e.error == "Invalid key") {
        throw FleetingNotesException('Invalid filename');
      }
      rethrow;
    }
  }

  // helpers
  Future<String?> getEncryptionKey() async {
    if (userId != null) {
      return await secureStorage.read(key: 'encryption-key-$userId');
    }
    return null;
  }

  // attempt to recover session from secure storage
  Future<void> clearSession() async {
    await secureStorage.write(key: 'session', value: null);
  }

  Future<void> refreshSession() async {
    if (currUser == null) return;
    try {
      int fiveDaySec = 432000;
      int? tokenExpiresIn = client.auth.currentSession?.expiresIn;
      if (tokenExpiresIn != null && tokenExpiresIn < fiveDaySec) {
        await client.auth.refreshSession();
      }
    } on AuthException catch (e) {
      debugPrint("${e.statusCode} ${e.message}");
    }
  }

  Future<RecoveredSessionEvent> recoverSession(Session session) async {
    try {
      var res = await client.auth.recoverSession(session.persistSessionString);
      if (res.session != null) return RecoveredSessionEvent.succeeded;
    } on AuthException catch (e) {
      debugPrint("${e.statusCode} ${e.message}");
    }
    await secureStorage.write(key: 'session', value: null);
    return RecoveredSessionEvent.failed;
  }

  Future<StoredSession?> getStoredSession() async {
    try {
      var sessionStr = await secureStorage.read(key: 'session');
      if (sessionStr == null) return null;
      Map<String, dynamic> json = jsonDecode(sessionStr);

      return StoredSession(
        Session.fromJson(json['currentSession']),
        json['subscriptionTier'],
      );
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<void> setSession() async {
    try {
      var session = client.auth.currentSession;
      if (session == null) {
        return await secureStorage.write(key: 'session', value: null);
      }
      Map<String, dynamic> json = jsonDecode(session.persistSessionString);
      var subscriptionTier = await getSubscriptionTier();
      json['subscriptionTier'] =
          (subscriptionTier == SubscriptionTier.freeSub) ? 'free' : null;
      await secureStorage.write(key: 'session', value: jsonEncode(json));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> setEncryptionKey(String key) async {
    String hashedKey = sha256Hash(key);
    String? supabaseHashedKey = await getHashedKey();
    if (supabaseHashedKey == null) {
      await client.from('user_data').upsert({
        'id': currUser?.id,
        'encryption_key': hashedKey,
      });
    } else if (supabaseHashedKey != hashedKey) {
      throw FleetingNotesException('Encryption key does not match');
    }
    await secureStorage.write(key: 'encryption-key-$userId', value: key);
  }

  Future<String?> getHashedKey() async {
    if (currUser == null) return null;
    try {
      var userData = await client
          .from('user_data')
          .select('encryption_key')
          .eq('id', currUser?.id)
          .single();
      return userData['encryption_key'];
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAccount() async {
    await Future.wait([
      client.functions.invoke('delete-user').then((res) {
        if (res.status != 200) {
          throw FleetingNotesException('Failed to delete account');
        }
      }),
      logout(),
    ]);
  }

  Note fromSupabaseJson(dynamic supaNote, {String? encryptionKey}) {
    bool isEncrypted = supaNote['encrypted'] ?? false;
    DateTime createdDt = DateTime.parse(supaNote['created_at']);
    DateTime modifiedDt = DateTime.parse(supaNote['modified_at']);
    String title = supaNote['title'];
    String content = supaNote['content'];
    String source = supaNote['source'];
    String? sourceTitle = supaNote['source_title'];
    String? sourceDescription = supaNote['source_description'];
    String? sourceImageUrl = supaNote['source_image_url'];
    if (isEncrypted) {
      if (encryptionKey == null) {
        throw FleetingNotesException(
            'Note decryption failed - Add encryption key in settings');
      }
      if (title.isNotEmpty) {
        title = decryptAESCryptoJS(title, encryptionKey);
      }
      if (content.isNotEmpty) {
        content = decryptAESCryptoJS(content, encryptionKey);
      }
      if (source.isNotEmpty) {
        source = decryptAESCryptoJS(source, encryptionKey);
      }
      if (sourceTitle != null && sourceTitle.isNotEmpty) {
        sourceTitle = decryptAESCryptoJS(sourceTitle, encryptionKey);
      }
      if (sourceDescription != null && sourceDescription.isNotEmpty) {
        sourceDescription =
            decryptAESCryptoJS(sourceDescription, encryptionKey);
      }
      if (sourceImageUrl != null && sourceImageUrl.isNotEmpty) {
        sourceImageUrl = decryptAESCryptoJS(sourceImageUrl, encryptionKey);
      }
    }
    var note = Note(
      id: supaNote['id'],
      title: title,
      content: content,
      source: source,
      partition: supaNote['_partition'],
      isDeleted: supaNote['deleted'],
      isShareable: supaNote['shared'],
      createdAt: createdDt.toIso8601String(),
      sourceTitle: sourceTitle,
      sourceDescription: sourceDescription,
      sourceImageUrl: sourceImageUrl,
    );
    note.modifiedAt = modifiedDt.toIso8601String();
    return note;
  }

  Map<String, dynamic> toSupabaseJson(Note note, {String? encryptionKey}) {
    bool isEncrypted = encryptionKey != null;
    String title = note.title;
    String content = note.content;
    String source = note.source;
    String? sourceTitle = note.sourceTitle;
    String? sourceDescription = note.sourceDescription;
    String? sourceImageUrl = note.sourceImageUrl;
    if (isEncrypted) {
      if (note.title.isNotEmpty) {
        title = encryptAESCryptoJS(note.title, encryptionKey);
      }
      if (note.content.isNotEmpty) {
        content = encryptAESCryptoJS(note.content, encryptionKey);
      }
      if (note.source.isNotEmpty) {
        source = encryptAESCryptoJS(note.source, encryptionKey);
      }
      if (sourceTitle != null && sourceTitle.isNotEmpty == true) {
        sourceTitle = encryptAESCryptoJS(sourceTitle, encryptionKey);
      }
      if (sourceDescription != null && sourceDescription.isNotEmpty == true) {
        sourceDescription =
            encryptAESCryptoJS(sourceDescription, encryptionKey);
      }
      if (sourceImageUrl != null && sourceImageUrl.isNotEmpty == true) {
        sourceImageUrl = encryptAESCryptoJS(sourceImageUrl, encryptionKey);
      }
    }
    return {
      'id': note.id,
      'title': title,
      'content': content,
      'source': source,
      'source_title': sourceTitle,
      'source_description': sourceDescription,
      'source_image_url': sourceImageUrl,
      'created_at': note.createdAt,
      'modified_at': note.modifiedAt,
      'deleted': note.isDeleted,
      '_partition': userId,
      'shared': note.isShareable,
      'encrypted': isEncrypted,
    };
  }

  @override
  Future<void> init({Iterable<Note> notes = const Iterable.empty()}) async {
    // Notes are initialized in database.dart `initNotes()` function
    // maybe look into moving that here?

    // setup stream here (will always be two way)
    await client.removeAllChannels();
    client.channel('public:notes').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: '*', schema: 'public', table: 'notes'),
      (payload, [ref]) async {
        String? encryptionKey = await getEncryptionKey();
        var eventType = payload['eventType'];
        Note note =
            fromSupabaseJson(payload['new'], encryptionKey: encryptionKey);
        if (eventType == 'UPDATE' || eventType == 'INSERT') {
          if (note.isDeleted == true) {
            noteStreamController.add(NoteEvent([note], NoteEventStatus.delete));
          } else {
            noteStreamController.add(NoteEvent([note], NoteEventStatus.upsert));
          }
        }
      },
    ).subscribe();
  }
}
