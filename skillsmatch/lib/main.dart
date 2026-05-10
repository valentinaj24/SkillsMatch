import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/splash_onboarding.dart'; // ← DODAJ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ← UKLONI: await FirebaseAuth.instance.signOut();
  runApp(const SkillsMatchApp());
}

class SkillsMatchApp extends StatelessWidget {
  const SkillsMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skills Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5)), // ← indigo umesto teal
        useMaterial3: true,
      ),

      // ← ZAMENI home sa SplashScreen
      home: SplashScreen(
        nextScreen: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF0F0FF),
                body: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF4F46E5)),
                ),
              );
            }
            if (snapshot.hasData) {
              return const MainNavigationScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}