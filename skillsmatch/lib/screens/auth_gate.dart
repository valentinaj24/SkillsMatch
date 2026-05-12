import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'profile_screen.dart';
import 'incoming_call_listener.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
          return const Scaffold(
            backgroundColor: Color(0xFFF0F0FF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          );
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
              return const Scaffold(
                backgroundColor: Color(0xFFF0F0FF),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                ),
              );
            }

            if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
              return const ProfileScreen();
            }

            final data = profileSnapshot.data!.data();

            if (_isProfileCompleted(data)) {
              return IncomingCallListener(
                child: MainNavigationScreen(),
              );
            }

            return const ProfileScreen();
          },
        );
      },
    );
  }
}