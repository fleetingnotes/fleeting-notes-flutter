// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAXzFkFSgQo0PYcIDJZg2gJBaxy1cqy1oc',
    appId: '1:220377646074:web:50b3f82d7fef6e07ebda43',
    messagingSenderId: '220377646074',
    projectId: 'fleetingnotes-22f77',
    authDomain: 'fleetingnotes-22f77.firebaseapp.com',
    storageBucket: 'fleetingnotes-22f77.appspot.com',
    measurementId: 'G-CEZQV726SD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXON2_4OVoHSplISHIQKtexvAlZEIZBRY',
    appId: '1:220377646074:android:f12456df2d895312ebda43',
    messagingSenderId: '220377646074',
    projectId: 'fleetingnotes-22f77',
    storageBucket: 'fleetingnotes-22f77.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBSwbl8AZFm6IjSDkC_5I6gO0fDCfCbOcc',
    appId: '1:220377646074:ios:ef5c21523441b74cebda43',
    messagingSenderId: '220377646074',
    projectId: 'fleetingnotes-22f77',
    storageBucket: 'fleetingnotes-22f77.appspot.com',
    iosClientId: '220377646074-b3l8tu5g7r4rti84lrlecurgqoq559gb.apps.googleusercontent.com',
    iosBundleId: 'com.fleetingnotes',
  );
}
