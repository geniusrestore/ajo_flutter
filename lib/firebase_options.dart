import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBXQn0c-CQqGO6TDWxdBJauXCRBy_Qwgxc",
    authDomain: "my-ajo-project1.firebaseapp.com",
    projectId: "my-ajo-project1",
    storageBucket: "my-ajo-project1.firebasestorage.app",
    messagingSenderId: "182425698520",
    appId: "1:182425698520:web:b7711233969cb66ce017ad",
    measurementId: "G-ZSQR04VSH4",
  );
}