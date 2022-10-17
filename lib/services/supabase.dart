import 'dart:async';
import 'dart:typed_data';

import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/Note.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/crypt.dart';

class SupabaseDB {
  final SupabaseClient client = Supabase.instance.client;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  StreamController<User?> authChangeController = StreamController<User?>();
  SupabaseDB() {
    client.auth.onAuthStateChange((event, session) {
      authChangeController.add(session?.user);
    });
  }
  User? get currUser => client.auth.currentUser;
  String? get userId =>
      (currUser?.userMetadata ?? {})['firebaseUid'] ?? currUser?.id;
  bool get canSync => currUser != null;

  // auth stuff
  Future<bool> login(String email, String password) async {
    await client.auth.signIn(
      email: email,
      password: password,
    );
    if (currUser == null) {
      throw FleetingNotesException('Login Failed');
    }
    return true;
  }

  Future<bool> register(String email, String password) async {
    final res = await client.auth.signUp(
      email,
      password,
    );
    if (res.user == null) throw FleetingNotesException('Registration failed');
    return true;
  }

  Future<bool> logout() async {
    await client.auth.signOut();
    return true;
  }

  Future<void> resetPassword(String email) async {
    await client.auth.api.resetPasswordForEmail(email);
  }

  Future<String> getSubscriptionTier() async {
    if (currUser == null) return 'free';
    var retrievedTier = await client
        .from('stripe')
        .select('subscription_tier')
        .eq('id', currUser?.id)
        .single();
    return (retrievedTier ?? {})['subscription_tier'] ?? 'free';
  }

  // get, update, & delete notes
  Future<List<Note>> getAllNotes(
      {String? partition, DateTime? modifiedAfter}) async {
    var baseFilter = client.from('notes').select().neq('deleted', true);
    baseFilter = (partition == null)
        ? baseFilter.in_('_partition', [userId, currUser?.id])
        : baseFilter.eq('_partition', partition);

    List<dynamic> supaNotes = (modifiedAfter == null)
        ? (await baseFilter)
        : (await baseFilter.gt('modified_at', modifiedAfter.toIso8601String()));
    String? encryptionKey = await getEncryptionKey();
    List<Note> notes = supaNotes
        .map((supaNote) =>
            fromSupabaseJson(supaNote, encryptionKey: encryptionKey))
        .toList();
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
    String? encryptionKey = await getEncryptionKey();
    var supaNotes = notes
        .map((note) => toSupabaseJson(note, encryptionKey: encryptionKey))
        .toList();
    var res = await client.from('notes').upsert(supaNotes);
    // TODO: create a cache to store unsaved notes and attempts to save the note next time they try to save
    if (res?.error != null) {
      print(res.error);
      throw FleetingNotesException("Failed to upsert note");
    }
    return true;
  }

  // storage
  // TODO; double check this works
  Future<String> addAttachment(String filename, Uint8List? fileBytes) async {
    if (fileBytes == null || fileBytes.isEmpty) {
      throw FleetingNotesException('File is empty');
    }
    var isPaying = await getSubscriptionTier() != 'free';
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
      await client.from('user_data').insert({'encryption_key', hashedKey});
    } else if (supabaseHashedKey != hashedKey) {
      throw FleetingNotesException('Encryption key does not match');
    }
    await secureStorage.write(key: 'encryption-key-$userId', value: key);
  }

  Future<String?> getHashedKey() async {
    if (currUser == null) return null;
    // TODO: update stripe to reflect this
    // TODO: double check that this works!
    var userData = await client
        .from('user_data')
        .select('encryption_key')
        .eq('id', currUser?.id)
        .single();
    return userData['encryption_key'];
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
      'modified_at': DateTime.now().toIso8601String(),
      'deleted': note.isDeleted,
      '_partition': userId,
      'shared': note.isShareable,
      'encrypted': isEncrypted,
    };
  }
}
