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
        return ios;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAdtifJ-cH7iOMp8nV2EldoW_lTrxomkxQ',
    appId: '1:739581058617:web:25e2d6a6577b89622d77e8',
    messagingSenderId: '739581058617',
    projectId: 'vetclick-b0f5e',
    authDomain: 'vetclick-b0f5e.firebaseapp.com',
    storageBucket: 'vetclick-b0f5e.firebasestorage.app',
    measurementId: 'G-Y1BMGTMH1E',
  );

  /// Android configuration — update via `flutterfire configure` when ready
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdtifJ-cH7iOMp8nV2EldoW_lTrxomkxQ',
    appId: '1:739581058617:android:vetclick',
    messagingSenderId: '739581058617',
    projectId: 'vetclick-b0f5e',
    storageBucket: 'vetclick-b0f5e.firebasestorage.app',
  );

  /// iOS configuration — update via `flutterfire configure` when ready
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAdtifJ-cH7iOMp8nV2EldoW_lTrxomkxQ',
    appId: '1:739581058617:ios:vetclick',
    messagingSenderId: '739581058617',
    projectId: 'vetclick-b0f5e',
    storageBucket: 'vetclick-b0f5e.firebasestorage.app',
    iosClientId: '739581058617-ios.apps.googleusercontent.com',
    iosBundleId: 'com.example.vetmanager',
  );
}
