import 'dart:async';
import 'dart:typed_data';
import 'package:firedart/auth/exceptions.dart';
import 'package:hive/hive.dart';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/firedart.dart';
import 'package:firedart/auth/user_gateway.dart' as fd;
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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

enum SubscriptionTier { freeSub, basicSub, premiumSub }

class SupabaseDB {
  final SupabaseClient client = Supabase.instance.client;
  final FireDart firedart = FireDart();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  StreamController<User?> authChangeController =
      StreamController<User?>.broadcast();
  SupabaseDB() {
    currUser = client.auth.currentUser;
    client.auth.onAuthStateChange((event, session) {
      if (currUser?.id != session?.user?.id) {
        authChangeController.add(session?.user);
      }
      currUser = session?.user;
    });
  }
  User? currUser;
  String? get userId =>
      (currUser?.userMetadata ?? {})['firebaseUid'] ?? currUser?.id;
  bool get canSync => currUser != null;

  // auth stuff
  Future<User> login(String email, String password) async {
    final res = await client.auth.signIn(
      email: email,
      password: password,
    );
    var user = res.user;
    if (user == null) {
      throw FleetingNotesException('Login failed');
    } else {
      return user;
    }
  }

  Future<User> register(String email, String password,
      {String? firebaseUid}) async {
    try {
      var userMetadata =
          (firebaseUid == null) ? null : {"firebaseUid": firebaseUid};
      final res =
          await client.auth.signUp(email, password, userMetadata: userMetadata);
      var newUser = res.user;
      if (newUser == null) {
        throw FleetingNotesException('Registration failed');
      } else {
        return newUser;
      }
    } on GoTrueException catch (e) {
      throw FleetingNotesException('Registration failed: ${e.message}');
    }
  }

  Future<bool> logout() async {
    await client.auth.signOut();
    return true;
  }

  Future<void> registerFirebase(String email, String password) async {
    try {
      await firedart.register(email, password);
    } on AuthException catch (e) {
      throw FleetingNotesException('Registration failed: ${e.message}');
    } catch (e) {
      throw FleetingNotesException('Registration failed');
    }
  }

  Future<MigrationStatus> loginMigration(String email, String password) async {
    Future<User?> supaLogin(String email, String password) async {
      try {
        return await login(email, password);
      } catch (e) {
        return null;
      }
    }

    Future<fd.User?> fireLogin(String email, String password) async {
      try {
        return await firedart.login(email, password);
      } catch (e) {
        return null;
      }
    }

    var res = await Future.wait([
      supaLogin(email, password),
      fireLogin(email, password),
    ]);
    var supaUser = res[0] as User?;
    var fireUser = res[1] as fd.User?;

    if (supaUser != null && fireUser != null) {
      return MigrationStatus.supaFireLogin;
    } else if (supaUser == null && fireUser != null) {
      try {
        await register(email, password, firebaseUid: fireUser.id);
        supaUser = await login(email, password);
      } on FleetingNotesException catch (e, stack) {
        Sentry.captureException(e, stackTrace: stack);
        throw FleetingNotesException(
            'Failed account migration, check credentials');
      }
      return MigrationStatus.fireLoginOnly;
    } else if (supaUser != null && fireUser == null) {
      return MigrationStatus.supaLoginOnly;
    } else {
      throw FleetingNotesException('Login Failed');
    }
  }

  Future<void> resetPassword(String email) async {
    await client.auth.api.resetPasswordForEmail(email);
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
      return SubscriptionTier.freeSub;
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

  Future<void> refreshSession() async {
    if (currUser == null) return;
    try {
      await client.auth.refreshSession();
    } on GoTrueException catch (e) {
      debugPrint("${e.statusCode} ${e.message}");
      if (e.statusCode == "400") {
        logout();
      }
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
    Map<String, Note> mapping = {for (var note in box!.values) note.id: note};
    return mapping;
  }

  Future<void> saveNotesCache(List<Note> notes) async {
    var box = await getNotesCacheBox();
    Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
    box!.putAll(noteIdMap);
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
    final mimeType = lookupMimeType(filename);
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
      timestamp: dt.toIso8601String(),
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
      'created_at': note.timestamp,
      'modified_at': DateTime.now().toUtc().toIso8601String(),
      'deleted': note.isDeleted,
      '_partition': userId,
      'shared': note.isShareable,
      'encrypted': isEncrypted,
    };
  }
}
