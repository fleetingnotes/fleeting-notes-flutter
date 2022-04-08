import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Note.dart';

class FirebaseDB {
  User? user;
  late CollectionReference notesCollection;
  FirebaseDB() {
    FirebaseAuth.instance.userChanges().listen((User? user) {
      user = user;
    });
    notesCollection = FirebaseFirestore.instance.collection('notes');
  }
  bool isLoggedIn() => user != null;

  Future<bool> login(String email, String password) async {
    try {
      UserCredential credentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      user = credentials.user;
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
}
