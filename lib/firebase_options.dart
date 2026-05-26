// ignore_for_file: lines_longer_than_80_chars
// GENERATED TEMPLATE — Replace by running:
//   dart pub global activate flutterfire_cli
//   dart run flutterfire_cli:flutterfire configure
//
// This file must match your Firebase project (and android/app/google-services.json).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the Smart Campus app.
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD9ZWxl50b3MAdfGlH1rDUPVS58oZXyutE',
    appId: '1:1085264372032:web:584e2320f8a0e8ea5b9aa5',
    messagingSenderId: '1085264372032',
    projectId: 'smartcampusapp-bf9af',
    authDomain: 'smartcampusapp-bf9af.firebaseapp.com',
    storageBucket: 'smartcampusapp-bf9af.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjTBgNXnzf_U7YFBhF98Y3qxOaMF40b4M',
    appId: '1:1085264372032:android:647106f3cb8e3ce45b9aa5',
    messagingSenderId: '1085264372032',
    projectId: 'smartcampusapp-bf9af',
    storageBucket: 'smartcampusapp-bf9af.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzY9EDvCrW_498gA5l8aZFQC1YGWshvZA',
    appId: '1:1085264372032:ios:9f91a30ee7ac90145b9aa5',
    messagingSenderId: '1085264372032',
    projectId: 'smartcampusapp-bf9af',
    storageBucket: 'smartcampusapp-bf9af.firebasestorage.app',
    iosBundleId: 'com.smartcampus.smartCampusApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCzY9EDvCrW_498gA5l8aZFQC1YGWshvZA',
    appId: '1:1085264372032:ios:9f91a30ee7ac90145b9aa5',
    messagingSenderId: '1085264372032',
    projectId: 'smartcampusapp-bf9af',
    storageBucket: 'smartcampusapp-bf9af.firebasestorage.app',
    iosBundleId: 'com.smartcampus.smartCampusApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD9ZWxl50b3MAdfGlH1rDUPVS58oZXyutE',
    appId: '1:1085264372032:web:53214ae8ab6d0e375b9aa5',
    messagingSenderId: '1085264372032',
    projectId: 'smartcampusapp-bf9af',
    authDomain: 'smartcampusapp-bf9af.firebaseapp.com',
    storageBucket: 'smartcampusapp-bf9af.firebasestorage.app',
  );

  /// Linux desktop uses the same Firebase project as Web for local development.
  /// Run `dart run flutterfire_cli:flutterfire configure` and select Linux
  /// to generate a dedicated Linux app ID for production builds.
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyD9ZWxl50b3MAdfGlH1rDUPVS58oZXyutE',
    appId: '1:1085264372032:web:584e2320f8a0e8ea5b9aa5',
    messagingSenderId: '1085264372032',
    projectId: 'smartcampusapp-bf9af',
    authDomain: 'smartcampusapp-bf9af.firebaseapp.com',
    storageBucket: 'smartcampusapp-bf9af.firebasestorage.app',
  );

}