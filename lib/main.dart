import 'package:cubaankedua/auth/auth.dart';
import 'package:cubaankedua/auth/login_or_register.dart';
import 'package:cubaankedua/pages/home_page.dart';
import 'package:cubaankedua/pages/login_page.dart';
import 'package:cubaankedua/pages/main_page.dart';
import 'package:cubaankedua/pages/profile_page.dart';
import 'package:cubaankedua/pages/register_page.dart';
import 'package:cubaankedua/pages/users_page.dart';
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
      //error missing img
      home:  AuthPage(),
      theme: lightMode,
      darkTheme: darkMode,
      routes: {
        '/login_register_page': (context) => const LoginOrRegister(),
        '/main_page': (context) => const MainPage(),
        '/profile_page':(context) => ProfilePage(),
        '/users_page': (context) => const UsersPage(),
      },
    );
  }
}
