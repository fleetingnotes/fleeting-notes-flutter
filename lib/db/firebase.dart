import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Note.dart';
import 'db_interface.dart';

class FirebaseDB implements DatabaseInterface {
  @override
  String userId = 'local';
  User? currUser;
  late CollectionReference notesCollection;
  FirebaseDB() {
    FirebaseAuth.instance.userChanges().listen((User? user) {
      currUser = user;
      userId = (user == null) ? 'local' : user.uid;
      FirebaseAnalytics.instance
          .setUserId(id: (user == null) ? null : user.uid);
    });
    notesCollection = FirebaseFirestore.instance.collection('notes');
  }
  @override
  bool isLoggedIn() {
    return currUser != null;
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      UserCredential credentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      currUser = credentials.user;
      userId = (credentials.user == null) ? 'local' : credentials.user!.uid;
      await FirebaseAnalytics.instance.logLogin(loginMethod: 'firebase');
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

  @override
  Future<bool> register(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'firebase');
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

  @override
  Future<bool> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await FirebaseAnalytics.instance.logEvent(name: 'sign_out', parameters: {
        'method': 'firebase',
      });
      currUser = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> insertNote(Note note) async => await updateNote(note);

  @override
  Future<List<Note>> getAllNotes({int? limit}) async {
    if (currUser == null) return [];
    try {
      var query = notesCollection
          .where('_partition', isEqualTo: currUser!.uid)
          .where('_isDeleted', isNotEqualTo: true);

      if (limit != null) {
        query = query.limit(limit);
      }
      var docs = (await query.get()).docs;

      List<Note> notes = [for (var note in docs) fromQueryDoc(note)];
      return notes;
    } catch (e) {
      return [];
    }
  }

  Future<bool> isNotesEmpty() async {
    var notes = await getAllNotes(limit: 1);
    return notes.isEmpty;
  }

  @override
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

  @override
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

  @override
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
