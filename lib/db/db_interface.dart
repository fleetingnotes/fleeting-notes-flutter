import '../models/Note.dart';

abstract class DatabaseInterface {
  String get userId;

  bool isLoggedIn();

  Future<bool> login(String email, String password);

  Future<bool> register(String email, String password);

  Future<bool> logout();

  Future<bool> insertNote(Note note);

  Future<List<Note>> getAllNotes();

  Future<bool> updateNotes(List<Note> notes);

  Future<bool> updateNote(Note note);

  Future<bool> deleteNote(Note note);
}
