// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:device_preview/device_preview.dart';
// import 'WelcomePage.dart';
// import 'BackEnd/firebaseOptions/firebase_options.dart';
//
// Future main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   runApp(
//     DevicePreview(
//       builder: (context) => const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: WelcomePage(),
//     );
//   }
// }

//Uncomment the below code if you are going to run the app on Android Studio

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'WelcomePage.dart';
import 'BackEnd/firebaseOptions/firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WelcomePage(), // Show WelcomePage initially
    );
  }
}
