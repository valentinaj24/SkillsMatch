import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/splash_onboarding.dart';
import 'screens/profile_screen.dart';

Future<void> _checkPermissions() async {
  var status = await Permission.bluetooth.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Permission disabled');
  }
  status = await Permission.bluetoothConnect.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Connect Permission disabled');
  }
}

Future<void> _initializeAndroidAudioSettings() async {
  await webrtc.WebRTC.initialize(options: {
    'androidAudioConfiguration':
        webrtc.AndroidAudioConfiguration.communication.toMap(),
  });
  webrtc.Helper.setAndroidAudioConfiguration(
    webrtc.AndroidAudioConfiguration.communication,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      home: SplashScreen(nextScreen: const AuthWrapper()),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  bool _isProfileCompleted(Map<String, dynamic>? data) {
    if (data == null) return false;

    if (data['profileCompleted'] == true) return true;

    final ime = (data['ime'] ?? '').toString().trim();
    final lokacija = (data['lokacija'] ?? '').toString().trim();
    final vescine = data['vescine'] as List<dynamic>? ?? [];

    return ime.isNotEmpty && lokacija.isNotEmpty && vescine.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
              return const ProfileScreen();
            }

            final data = profileSnapshot.data!.data();

            if (_isProfileCompleted(data)) {
              return const MainNavigationScreen();
            }

            return const ProfileScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF0F0FF),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
    );
  }
}
