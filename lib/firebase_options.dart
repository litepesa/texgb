// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnTwbnUdAweufEjj_uPjKqxCxNjj2klHM',
    appId: '1:1084620693228:web:8de33b192c6b9a15034fc9',
    messagingSenderId: '1084620693228',
    projectId: 'texgb-50a98',
    authDomain: 'texgb-50a98.firebaseapp.com',
    storageBucket: 'texgb-50a98.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_uzTahLR1BCPZYeO2u9BWWLnQl0-BkZY',
    appId: '1:1084620693228:android:3da829b75c85d271034fc9',
    messagingSenderId: '1084620693228',
    projectId: 'texgb-50a98',
    storageBucket: 'texgb-50a98.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-PGQQ1zqhD9puT0NoA3Loiz6Mv86RP0M',
    appId: '1:1084620693228:ios:cdf05771bdd1f687034fc9',
    messagingSenderId: '1084620693228',
    projectId: 'texgb-50a98',
    storageBucket: 'texgb-50a98.firebasestorage.app',
    iosBundleId: 'com.pomasoft.texgb',
  );
}
