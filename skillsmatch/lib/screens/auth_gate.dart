import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // NIJE ULOGOVAN
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;

        // PROVERA DA LI PROFIL POSTOJI
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // AKO PROFIL POSTOJI -> APP
            if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
              return const MainNavigationScreen();
            }

            // AKO NE POSTOJI -> KREIRANJE PROFILA
            return const ProfileScreen();
          },
        );
      },
    );
  }
}
