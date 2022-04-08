import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Note.dart';

class FirebaseDB {
  User? currUser;
  String userId = 'local';
  late CollectionReference notesCollection;
  FirebaseDB() {
    FirebaseAuth.instance.userChanges().listen((User? user) {
      currUser = user;
      if (user != null) {
        userId = user.uid;
      } else {
        userId = 'local';
      }
    });
    notesCollection = FirebaseFirestore.instance.collection('notes');
  }
  bool isLoggedIn() {
    return currUser != null;
  }

  Future<bool> login(String email, String password) async {
    try {
      UserCredential credentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      currUser = credentials.user;
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // ignore: avoid_print
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        // ignore: avoid_print
        print('Wrong password provided for that user.');
      }
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        // ignore: avoid_print
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        // ignore: avoid_print
        print('The account already exists for that email.');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> insertNote(Note note) => updateNote(note);

  Future<List<Note>> getAllNotes() async {
    if (currUser == null) return [];
    try {
      QuerySnapshot query = await notesCollection
          .where('_partition', isEqualTo: currUser!.uid)
          .where('_isDeleted', isNotEqualTo: true)
          .get();
      List<Note> notes = [for (var note in query.docs) fromQueryDoc(note)];
      return notes;
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateNotes(List<Note> notes) async {
    if (currUser == null) return false;
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var note in notes) {
        updateNote(note, batch: batch);
      }
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNote(Note note, {WriteBatch? batch}) async {
    if (currUser == null) return false;
    try {
      var json = toFirebaseJson(note);
      json['last_modified_timestamp'] = Timestamp.now();
      DocumentReference docRef = notesCollection.doc(note.id);
      if (batch == null) {
        await docRef.set(json, SetOptions(merge: true));
      } else {
        batch.set(docRef, json, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(Note note) async {
    note.isDeleted = true;
    return await updateNote(note);
  }

  Note fromQueryDoc(QueryDocumentSnapshot note) {
    DateTime dt = (note['created_timestamp'] as Timestamp).toDate();
    return Note(
      id: note.id,
      title: note["title"].toString(),
      content: note["content"].toString(),
      source: note["source"].toString(),
      timestamp: dt.toIso8601String(),
    );
  }

  toFirebaseJson(Note note) {
    Timestamp created = Timestamp.fromDate(note.getDateTime());
    return {
      'title': note.title,
      'content': note.content,
      'source': note.source,
      'created_timestamp': created,
      '_isDeleted': note.isDeleted,
      '_partition': currUser!.uid,
    };
  }
}
