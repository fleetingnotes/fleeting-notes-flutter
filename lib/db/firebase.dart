import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleeting_notes_flutter/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import '../models/Note.dart';
import 'db_interface.dart';
import 'package:dio/dio.dart';
import '../crypt.dart';

class FirebaseDB implements DatabaseInterface {
  @override
  String userId = 'local';
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final Dio dio = Dio();
  User? currUser;
  StreamController<User?> authChangeController = StreamController<User?>();
  late CollectionReference notesCollection;
  CollectionReference encryptionCollection =
      FirebaseFirestore.instance.collection('encryption');
  FirebaseDB() {
    configRemoteConfig();
    userChanges.listen((User? user) {
      if (currUser?.uid != user?.uid) {
        authChangeController.add(user);
      }
      currUser = user;
      userId = (user == null) ? 'local' : user.uid;
      analytics.setUserId(id: (user == null) ? null : user.uid);
    });
    notesCollection = FirebaseFirestore.instance.collection('notes');
  }

  Stream<User?> get userChanges => auth.userChanges();

  bool get isSharedNotes => userId != 'local' && currUser?.uid != userId;

  Future<String?> getFirebaseHashedKey() async {
    if (userId == 'local') return null;
    var docRef = await encryptionCollection.doc(userId).get();
    return (docRef.exists) ? docRef.get('key') : null;
  }

  Future<String?> getEncryptionKey() async {
    return await secureStorage.read(key: 'encryption-key-$userId');
  }

  Future<void> setEncryptionKey(String key) async {
    String hashedKey = sha256Hash(key);
    String? firebaseHashedKey = await getFirebaseHashedKey();
    if (firebaseHashedKey == null) {
      await encryptionCollection.doc(userId).set({'key': hashedKey});
    } else if (firebaseHashedKey != hashedKey) {
      throw EncryptionException('Encryption key does not match');
    }
    await secureStorage.write(key: 'encryption-key-$userId', value: key);
    analytics.logEvent(name: 'set_encryption');
  }

  Future<void> configRemoteConfig() async {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(seconds: 1),
    ));
    await remoteConfig.setDefaults(const {
      "use_firebase": true,
      "initial_notes": "[]",
      "link_suggestion_threshold": 0.5,
      "save_delay_ms": 1000,
      "max_attachment_size_mb": 10,
      "max_attachment_size_mb_premium": 25,
    });
    remoteConfig.fetchAndActivate().catchError((e) {});
  }

  Future<bool> isCurrUserPremium() async {
    if (!isLoggedIn()) return false;
    await currUser!.getIdToken(true);
    var decodedToken = await currUser!.getIdTokenResult();
    Map claims = decodedToken.claims ?? {};
    return claims['stripeRole'] == 'premium';
  }

  void setAnalytics(enabled) {
    analytics.setAnalyticsCollectionEnabled(enabled);
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
    }
  }

  Future<bool> logoutAllSessions() async {
    if (!isLoggedIn()) return false;
    try {
      await dio.post(
        'https://us-central1-fleetingnotes-22f77.cloudfunctions.net/new_logout_all_sessions',
        data: {
          'uid': currUser!.uid,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> addAttachment(String filename, Uint8List? fileBytes) async {
    if (fileBytes == null || fileBytes.isEmpty) {
      throw Exception('File is empty');
    }
    int maxSize = await isCurrUserPremium()
        ? remoteConfig.getInt('max_attachment_size_mb_premium')
        : remoteConfig.getInt('max_attachment_size_mb');
    if (fileBytes.lengthInBytes / 1000000 > maxSize) {
      throw Exception('File cannot be larger than $maxSize MB');
    }
    final storageRef = storage.ref();
    final fileRef = storageRef.child(filename);
    final mimeType = lookupMimeType(filename);
    await fileRef.putData(fileBytes,
        SettableMetadata(contentType: mimeType ?? 'application/octet-stream'));
    return await fileRef.getDownloadURL();
  }

  Future<Map<String, double>> getSentenceSimilarity(
      String text, List<String> sentences) async {
    var response = await dio.post(
      'https://us-central1-fleetingnotes-22f77.cloudfunctions.net/rank_sentence_similarity',
      data: {
        'query': text,
        'sentences': sentences,
      },
    );
    Map<String, double> linkMap = Map.from(response.data);
    return linkMap;
  }

  Future<List<String>> orderListByRelevance(
      String text, List<String> links) async {
    Map<String, double> linkMap = await getSentenceSimilarity(text, links);
    List<String> similarLinks = linkMap.keys.toList();
    similarLinks.sort((k1, k2) => linkMap[k2]!.compareTo(linkMap[k1]!));
    return similarLinks.toList();
  }

  @override
  bool isLoggedIn() {
    if (currUser == null || currUser!.uid != userId) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      UserCredential credentials = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      currUser = credentials.user;
      authChangeController.add(currUser);
      userId = (credentials.user == null) ? 'local' : credentials.user!.uid;
      await analytics.logLogin(loginMethod: 'firebase');
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
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await analytics.logSignUp(signUpMethod: 'firebase');
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
      await auth.signOut();
      await analytics.logEvent(name: 'sign_out', parameters: {
        'method': 'firebase',
      });
      currUser = null;
      authChangeController.add(currUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> insertNote(Note note) async => await updateNote(note);

  @override
  Future<List<Note>> getAllNotes({int? limit, bool isShared = false}) async {
    var query = notesCollection
        .where('_partition', isEqualTo: userId)
        .where('_isDeleted', isNotEqualTo: true);
    if (isShared) {
      query = query.where('is_shared', isEqualTo: true);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    var docs = (await query.get()).docs;
    String? encryptionKey = await getEncryptionKey();
    List<Note> notes = [
      for (var note in docs) fromQueryDoc(note, encryptionKey: encryptionKey)
    ];
    return notes;
  }

  Future<bool> isNotesEmpty() async {
    var notes = await getAllNotes(limit: 1);
    return notes.isEmpty;
  }

  Future<Note?> getNoteById(String id) async {
    var doc = await notesCollection.doc(id).get();
    if (doc.exists) {
      String? encryptionKey = await getEncryptionKey();
      Note note = fromQueryDoc(doc, encryptionKey: encryptionKey);
      if (note.isDeleted) return null;
      return note;
    } else {
      return null;
    }
  }

  @override
  Future<bool> updateNotes(List<Note> notes) async {
    if (!isLoggedIn()) return false;
    try {
      String? encryptionKey = await getEncryptionKey();
      WriteBatch batch = FirebaseFirestore.instance.batch();
      List<Future> futures = [];
      for (var note in notes) {
        futures.add(updateNote(
          note,
          batch: batch,
          encryptionKey: encryptionKey,
          tryGetEncryptionKey: false,
        ));
      }
      await Future.wait(futures);
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateNote(Note note,
      {WriteBatch? batch,
      String? encryptionKey,
      bool tryGetEncryptionKey = true}) async {
    if (!isLoggedIn()) return false;
    try {
      if (tryGetEncryptionKey) {
        encryptionKey = await getEncryptionKey();
      }
      var json = toFirebaseJson(note, encryptionKey: encryptionKey);
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

  Future<void> deleteAccount() async {
    List<Note> allNotes = await getAllNotes();
    for (var note in allNotes) {
      note.isDeleted = true;
    }
    await updateNotes(allNotes);
    await currUser!.delete();
  }

  Note fromQueryDoc(DocumentSnapshot doc, {String? encryptionKey}) {
    bool docContainsString(String str) => doc.data().toString().contains(str);
    bool isEncrypted =
        docContainsString('is_encrypted') ? doc.get('is_encrypted') : false;
    DateTime dt = (doc['created_timestamp'] as Timestamp).toDate();
    String title = doc["title"].toString();
    String content = doc["content"].toString();
    String source = doc["source"].toString();
    if (isEncrypted) {
      if (encryptionKey == null) {
        throw EncryptionException(
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
      id: doc.id,
      title: title,
      content: content,
      source: source,
      partition: doc["_partition"].toString(),
      isDeleted:
          (docContainsString('_isDeleted')) ? doc.get('_isDeleted') : false,
      isShareable:
          (docContainsString('is_shared')) ? doc.get('is_shared') : false,
      timestamp: dt.toIso8601String(),
    );
  }

  toFirebaseJson(Note note, {String? encryptionKey}) {
    Timestamp created = Timestamp.fromDate(note.getDateTime());
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
      'created_timestamp': created,
      '_isDeleted': note.isDeleted,
      '_partition': currUser!.uid,
      'is_shared': note.isShareable,
      'is_encrypted': isEncrypted,
    };
  }

  Future<void> setInitialNotes() async {
    try {
      List remoteConfigInitNotes =
          jsonDecode(remoteConfig.getString('initial_notes'));
      List<Note> initNotes = remoteConfigInitNotes
          .map((note) => Note.empty(
                title: note['title'],
                content: note['content'],
                source: note['source'],
              ))
          .toList();
      await updateNotes(initNotes);
    } finally {
      analytics.logEvent(
        name: 'set_initial_notes',
        parameters: {
          'remote_config_init_notes': remoteConfig.getString('initial_notes'),
        },
      );
    }
  }
}
