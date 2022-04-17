import 'dart:developer';
import 'dart:html';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Flags {
  User? currUser;
  String userId = 'local';
  late CollectionReference globalFlagCollection;
  late CollectionReference userFlagCollection;

  Map<String, dynamic> globalFlags = {};
  Map<String, dynamic> userFlags = {};

  // On initialization, register callback for when the firebase user state changes
  Flags() {
    print("Initializing Firebase flags connection");
    FirebaseAuth.instance.userChanges().listen((User? user) {
      currUser = user;
      userId = (user == null) ? 'local' : user.uid;
      if (userId != 'local') {
        userFlagCollection =
            FirebaseFirestore.instance.collection("user_flags");
      }
    });

    globalFlagCollection =
        FirebaseFirestore.instance.collection("global_flags");
    print("Firebase flags connection initialized");
  }

  bool isLoggedIn() {
    return currUser != null;
  }

  Map<String, dynamic> _consolidateFlagDocs(
      List<QueryDocumentSnapshot<Object?>> docs) {
    return docs.fold<Map<String, dynamic>>({},
        (Map<String, dynamic> state, doc) {
      state.addAll(doc.data() as Map<String, dynamic>);
      return state;
    });
  }

  Future<void> loadUserFlags() async {
    try {
      var flagsDocs = userFlagCollection
          .where('_partition', isEqualTo: currUser!.uid)
          .get();
      return flagsDocs.then((querySnapshot) {
        userFlags = _consolidateFlagDocs(querySnapshot.docs);
      });
    } catch (e) {
      log("Error when loading user flags");
    }
  }

  /// Loads global flags from Firebase and cache them
  Future<void> loadGlobalFlags() async {
    try {
      var flagsDocs = globalFlagCollection.get();
      return flagsDocs.then((querySnapshot) {
        globalFlags = _consolidateFlagDocs(querySnapshot.docs);
      });
    } catch (e) {
      log("Error when loading global flags");
    }
  }

  /// Get a flag value from global flag cache, or from user cache if [useUserFlag]
  /// is [true]. If the flag is present in global but not in user cache, then
  /// returns the global value.
  T? getFlag<T>(String flagName, {bool useUserFlag = false}) {
    try {
      T? result = globalFlags[flagName] as T;
      if (useUserFlag && userFlags.containsKey(flagName)) {
        result = userFlags[flagName] as T;
      }
      return result;
    } catch (e) {
      log("Flag $flagName could not be fetched, perhaps it was not of type ${T.toString()}");
      return null;
    }
  }
}
