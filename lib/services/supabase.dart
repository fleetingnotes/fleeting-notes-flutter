import 'dart:async';
import 'dart:typed_data';
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

enum MigrationStatus {
  supaFireLogin,
  supaLoginOnly,
  fireLoginOnly,
  noLogin,
}

enum SubscriptionTier { freeSub, basicSub, premiumSub, unknownSub }

class SupabaseDB {
  SupabaseClient get client => Supabase.instance.client;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  StreamSubscription<AuthState>? authSubscription;
  StreamController<User?> authChangeController =
      StreamController<User?>.broadcast();
  SupabaseDB() {
    currUser = client.auth.currentUser;
    authSubscription?.cancel();
    authSubscription = client.auth.onAuthStateChange.listen((state) {
      if (currUser?.id != state.session?.user.id) {
        authChangeController.add(state.session?.user);
      }
      currUser = state.session?.user;
    });
  }
  User? currUser;
  String? get userId =>
      (currUser?.userMetadata ?? {})['firebaseUid'] ?? currUser?.id;
  bool get canSync => currUser != null;

  // auth stuff
  Future<User?> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      currUser = res.user ?? currUser;
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
    await client.auth.signOut();
    return true;
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // TODO: use a join table to only make 1 request
  Future<SubscriptionTier> getSubscriptionTier() async {
    if (currUser == null) return SubscriptionTier.freeSub;
    try {
      var subscriptionTier = await getSubscriptionTierFromTable('stripe');
      if (subscriptionTier == 'free') {
        subscriptionTier = await getSubscriptionTierFromTable('apple_iap');
      }
      switch (subscriptionTier) {
        case 'basic':
          return SubscriptionTier.basicSub;
        case 'premium':
          return SubscriptionTier.premiumSub;
        default:
          return SubscriptionTier.freeSub;
      }
    } catch (e) {
      debugPrint(e.toString());
      return SubscriptionTier.unknownSub;
    }
  }

  Future<String> getSubscriptionTierFromTable(String table) async {
    List<dynamic> tableSubTier = await client
        .from(table)
        .select('subscription_tier')
        .eq('id', currUser?.id);

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

  Future<void> refreshSession() async {
    if (currUser == null) return;
    try {
      int threeDaySec = 259200;
      int? tokenExpiresIn = client.auth.currentSession?.expiresIn;
      if (tokenExpiresIn != null && tokenExpiresIn < threeDaySec) {
        await client.auth.refreshSession();
      }
    } on AuthException catch (e) {
      debugPrint("${e.statusCode} ${e.message}");
    }
  }

  // get, update, & delete notes
  Future<List<Note>> getAllNotes(
      {String? partition, DateTime? modifiedAfter}) async {
    var baseFilter = client.from('notes').select().neq('deleted', true);
    baseFilter = (partition == null)
        ? baseFilter.in_('_partition', [userId, currUser?.id])
        : baseFilter.eq('_partition', partition);

    await upsertNotes([]); // pushes cached notes if any
    List<dynamic> supaNotes = (modifiedAfter == null)
        ? (await baseFilter)
        : (await baseFilter.gt('modified_at', modifiedAfter.toIso8601String()));
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
    return fromSupabaseJson(supaNote);
  }

  Future<bool> deleteNotes(List<Note> notes) async {
    var deletedNotes = notes.map((note) {
      note.modifiedAt = DateTime.now().toUtc().toIso8601String();
      note.isDeleted = true;
      return note;
    }).toList();
    return await upsertNotes(deletedNotes);
  }

  Future<bool> upsertNotes(List<Note> notes) async {
    // recent notes override unsaved cache notes
    var notesCache = await getNotesCache();
    notesCache.addAll({for (var note in notes) note.id: note});
    notes = notesCache.values.toList();
    if (notes.isEmpty) return true;

    // attempt to upsert notes to supabase
    String? encryptionKey = await getEncryptionKey();
    var supaNotes = notes
        .map((note) => toSupabaseJson(note, encryptionKey: encryptionKey))
        .toList();
    try {
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
    return true;
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

  Future<void> saveNotesCache(List<Note> notes) async {
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
    List<Note> allNotes = await getAllNotes();
    await deleteNotes(allNotes);
    // TODO: add option to delete account (rather than just logging out)
    await logout();
  }

  Note fromSupabaseJson(dynamic supaNote, {String? encryptionKey}) {
    bool isEncrypted = supaNote['encrypted'] ?? false;
    DateTime dt = DateTime.parse(supaNote['created_at']);
    String title = supaNote['title'];
    String content = supaNote['content'];
    String source = supaNote['source'];
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
    }
    return Note(
      id: supaNote['id'],
      title: title,
      content: content,
      source: source,
      partition: supaNote['_partition'],
      isDeleted: supaNote['deleted'],
      isShareable: supaNote['shared'],
      createdAt: dt.toIso8601String(),
    );
  }

  Map<String, dynamic> toSupabaseJson(Note note, {String? encryptionKey}) {
    bool isEncrypted = encryptionKey != null;
    String title = note.title;
    String content = note.content;
    String source = note.source;
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
    }
    return {
      'id': note.id,
      'title': title,
      'content': content,
      'source': source,
      'created_at': note.createdAt,
      'modified_at': note.modifiedAt,
      'deleted': note.isDeleted,
      '_partition': userId,
      'shared': note.isShareable,
      'encrypted': isEncrypted,
    };
  }
}
