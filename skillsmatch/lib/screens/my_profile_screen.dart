import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_screen.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Uporabnik ni prijavljen.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffeef7f5),
      appBar: AppBar(
        title: const Text('Moj profil'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profil še ni ustvarjen.\nNajprej izpolnite obrazec.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final vescine = data['vescine'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 25 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff00796b), Color(0xff4db6ac)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 56,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${data['ime'] ?? ''} ${data['priimek'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['lokacija'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        'Uredi profil',
                        style: TextStyle(fontSize: 17),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  _infoCard(
                    icon: Icons.description,
                    title: 'Opis',
                    text: (data['opis'] ?? '').toString().isEmpty
                        ? 'Ni opisa.'
                        : data['opis'],
                  ),

                  _infoCard(
                    icon: Icons.schedule,
                    title: 'Razpoložljivost',
                    text: data['razpolozljivost'] ?? '',
                  ),

                  const SizedBox(height: 10),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Moje veščine',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (vescine.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Ni dodanih veščin.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...vescine.map((skill) {
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.star, color: Colors.white),
                          ),
                          title: Text(
                            skill['naziv'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${skill['nivoZnanja'] ?? ''} • ${skill['tip'] ?? ''}',
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(text),
      ),
    );
  }
}
