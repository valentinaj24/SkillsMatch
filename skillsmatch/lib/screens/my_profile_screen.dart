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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff009688)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _emptyProfile(context);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final vescine = data['vescine'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 35 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  _profileHeader(context, data),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _editButton(context),
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
                          text: data['razpolozljivost'] ?? 'Ni podatka.',
                        ),

                        const SizedBox(height: 16),

                        _sectionTitle('Moje veščine', Icons.auto_awesome),
                        const SizedBox(height: 12),

                        if (vescine.isEmpty)
                          _emptySkillsCard()
                        else
                          ...vescine.asMap().entries.map((entry) {
                            return _skillCard(entry.value, entry.key);
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileHeader(BuildContext context, Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 54, 22, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff004d40), Color(0xff009688), Color(0xff4db6ac)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0.7, end: 1),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 58, color: Color(0xff009688)),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            '${data['ime'] ?? ''} ${data['priimek'] ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  data['lokacija'] ?? 'Ni lokacije',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text(
          'Uredi profil',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff009688),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: Colors.teal.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xff009688), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff004d40),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xff009688)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xff004d40),
          ),
        ),
      ],
    );
  }

  Widget _emptySkillsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: const Column(
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xff009688), size: 38),
          SizedBox(height: 10),
          Text(
            'Ni dodanih veščin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _skillCard(dynamic skill, int index) {
    final bool canTeach = skill['tip'] == 'Lahko učim druge';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + index * 90),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: 0.92 + (0.08 * value), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canTeach
                ? [const Color(0xffe0f2f1), Colors.white]
                : [const Color(0xfffff8e1), Colors.white],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: canTeach ? Colors.teal.shade100 : Colors.amber.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: canTeach
                  ? const Color(0xff009688)
                  : Colors.amber.shade700,
              child: Icon(
                canTeach ? Icons.volunteer_activism : Icons.school,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill['naziv'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${skill['nivoZnanja'] ?? ''} • ${skill['tip'] ?? ''}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyProfile(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef7f5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_add_alt_1,
                  size: 58,
                  color: Color(0xff009688),
                ),
                SizedBox(height: 16),
                Text(
                  'Profil še ni ustvarjen',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff004d40),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Najprej izpolnite obrazec za ustvarjanje profila.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
