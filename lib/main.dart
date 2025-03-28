import 'package:cubaankedua/pages/home_page.dart';
import 'package:cubaankedua/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'animal_id.dart';
import 'package:cubaankedua/theme/dark_mode.dart';
import 'package:cubaankedua/theme/light_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError=FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const AnimalClassifierApp());
}

class AnimalClassifierApp extends StatelessWidget {
  const AnimalClassifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      theme: lightMode,
      darkTheme: darkMode,
    );
  }
}
