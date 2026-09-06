import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase.initializeApp.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMumD9arRaGpvH6As0nOCDZQJaWi2BV4k',
    appId: '1:1017758929444:android:942910975283c754f6feb1',
    messagingSenderId: '1017758929444',
    projectId: 'twin-brain-advisor',
    authDomain: 'twin-brain-advisor.firebaseapp.com',
    storageBucket: 'twin-brain-advisor.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMumD9arRaGpvH6As0nOCDZQJaWi2BV4k',
    appId: '1:1017758929444:android:942910975283c754f6feb1',
    messagingSenderId: '1017758929444',
    projectId: 'twin-brain-advisor',
    storageBucket: 'twin-brain-advisor.firebasestorage.app',
  );
}
