// File generated manually for Flutter project configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for macOS',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAV1cbqJI3Z66qt_feS2a9fZnstuTd86uY',
    appId: '1:689408176481:web:5df2c4181ee0ae938e1520',
    messagingSenderId: '689408176481',
    projectId: 'edushield-73506',
    authDomain: 'edushield-73506.firebaseapp.com',
    storageBucket: 'edushield-73506.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAV1cbqJI3Z66qt_feS2a9fZnstuTd86uY',
    appId: '1:689408176481:web:5df2c4181ee0ae938e1520',
    messagingSenderId: '689408176481',
    projectId: 'edushield-73506',
    storageBucket: 'edushield-73506.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAV1cbqJI3Z66qt_feS2a9fZnstuTd86uY',
    appId: '1:689408176481:web:5df2c4181ee0ae938e1520',
    messagingSenderId: '689408176481',
    projectId: 'edushield-73506',
    storageBucket: 'edushield-73506.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAV1cbqJI3Z66qt_feS2a9fZnstuTd86uY',
    appId: '1:689408176481:web:5df2c4181ee0ae938e1520',
    messagingSenderId: '689408176481',
    projectId: 'edushield-73506',
    authDomain: 'edushield-73506.firebaseapp.com',
    storageBucket: 'edushield-73506.firebasestorage.app',
  );
}