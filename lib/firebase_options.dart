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
        return macos;
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
    apiKey: 'TODO_ADD_WEB_API_KEY',
    appId: '1:836204666207:web:TODO_ADD_WEB_APP_ID',
    messagingSenderId: '836204666207',
    projectId: 'task-1c336',
    authDomain: 'task-1c336.firebaseapp.com',
    storageBucket: 'task-1c336.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzB6595c6qIY551wBFoB5FEer7WEr4ww0',
    appId: '1:836204666207:android:1503b4c69907a9de5aeaea',
    messagingSenderId: '836204666207',
    projectId: 'task-1c336',
    storageBucket: 'task-1c336.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO_ADD_IOS_API_KEY',
    appId: '1:836204666207:ios:TODO_ADD_IOS_APP_ID',
    messagingSenderId: '836204666207',
    projectId: 'task-1c336',
    storageBucket: 'task-1c336.appspot.com',
    iosBundleId: 'com.example.todo_app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TODO_ADD_MACOS_API_KEY',
    appId: '1:836204666207:ios:TODO_ADD_MACOS_APP_ID',
    messagingSenderId: '836204666207',
    projectId: 'task-1c336',
    storageBucket: 'task-1c336.appspot.com',
    iosBundleId: 'com.example.todo_app',
  );
}
