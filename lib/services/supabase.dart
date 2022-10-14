import 'package:fleeting_notes_flutter/models/exceptions.dart';
import '../models/Note.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/crypt.dart';
import 'package:supabase/supabase.dart';

class SupabaseDB {
  final _supabaseUrl = "https://yixcweyqwkqyvebpmdvr.supabase.co";
  final _supabaseKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeGN3ZXlxd2txeXZlYnBtZHZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQ4MDMyMTgsImV4cCI6MTk4MDM3OTIxOH0.awfZKRuaLOPzniEJ2CIth8NWPYnelLfsWrMWH2Bz3w8";
  late final SupabaseClient client;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  SupabaseDB() {
    client = SupabaseClient(_supabaseUrl, _supabaseKey);
  }
  User? get currUser => client.auth.currentUser;
  String? get userId =>
      (currUser?.userMetadata ?? {})['firebaseUid'] ?? currUser?.id;
  bool get canSync => currUser != null;

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

  Future<List<Note>> getAllNotes({DateTime? modifiedAfter}) async {
    var baseFilter = client
        .from('notes')
        .select()
        .neq('deleted', true)
        .in_('_partition', [userId, currUser?.id]);

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
    if (res.error) {
      print(res.error);
      throw FleetingNotesException("Failed to upsert note");
    }
    return true;
  }

  // helpers
  Future<String?> getEncryptionKey() async {
    if (userId != null) {
      return await secureStorage.read(key: 'encryption-key-$userId');
    }
    return null;
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
      'title': title,
      'content': content,
      'source': source,
      'created_at': note.timestamp,
      'modified_at': DateTime.now().toIso8601String(),
      'deleted': note.isDeleted,
      '_partition': currUser!.id,
      'shared': note.isShareable,
      'encrypted': isEncrypted,
    };
  }
}
