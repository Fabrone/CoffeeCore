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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyC_H-8v4vl1iu2qDFhJXOVpQP-j8H2QxOw',
    appId: '1:832093698869:web:add42debd6754eda572a7c',
    messagingSenderId: '832093698869',
    projectId: 'coffeecore-7111a',
    authDomain: 'coffeecore-7111a.firebaseapp.com',
    storageBucket: 'coffeecore-7111a.firebasestorage.app',
    measurementId: 'G-L9N338TCLX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9DrJOt2PN1-6hEKqzyBnKWIag5Eapg4I',
    appId: '1:832093698869:android:2423813438820c42572a7c',
    messagingSenderId: '832093698869',
    projectId: 'coffeecore-7111a',
    storageBucket: 'coffeecore-7111a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCu3yl6L9N8W7Z38PeKXemAc9cI8PRSJvQ',
    appId: '1:832093698869:ios:08295d878c1b0ebb572a7c',
    messagingSenderId: '832093698869',
    projectId: 'coffeecore-7111a',
    storageBucket: 'coffeecore-7111a.firebasestorage.app',
    iosBundleId: 'com.example.coffeecore',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCu3yl6L9N8W7Z38PeKXemAc9cI8PRSJvQ',
    appId: '1:832093698869:ios:08295d878c1b0ebb572a7c',
    messagingSenderId: '832093698869',
    projectId: 'coffeecore-7111a',
    storageBucket: 'coffeecore-7111a.firebasestorage.app',
    iosBundleId: 'com.example.coffeecore',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC_H-8v4vl1iu2qDFhJXOVpQP-j8H2QxOw',
    appId: '1:832093698869:web:15c1df224e9032b5572a7c',
    messagingSenderId: '832093698869',
    projectId: 'coffeecore-7111a',
    authDomain: 'coffeecore-7111a.firebaseapp.com',
    storageBucket: 'coffeecore-7111a.firebasestorage.app',
    measurementId: 'G-429YSKQTXH',
  );
}
