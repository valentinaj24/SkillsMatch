import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef7f5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff009688)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyCommunity();
          }

          final users = snapshot.data!.docs;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(users.length)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final vescine = data['vescine'] as List<dynamic>? ?? [];

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 350 + index * 80),
                      tween: Tween(begin: 0, end: 1),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _userCard(data, vescine),
                    );
                  }, childCount: users.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 34),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Skupnost uporabnikov',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count uporabnikov je trenutno v skupnosti Skills Match.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> data, List<dynamic> vescine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff009688), Color(0xff4db6ac)],
                  ),
                ),
                child: const CircleAvatar(
                  radius: 29,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xff009688),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['ime'] ?? ''} ${data['priimek'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff004d40),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 17,
                          color: Color(0xff009688),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['lokacija'] ?? 'Ni lokacije',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if ((data['opis'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xfff8fffd),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                data['opis'],
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, color: Color(0xff009688), size: 19),
                const SizedBox(width: 6),
                Text(
                  'Razpoložljivost: ${data['razpolozljivost'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (vescine.isEmpty)
            const Text(
              'Ni dodanih veščin.',
              style: TextStyle(color: Colors.black54),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vescine.map((skill) {
                final bool canTeach = skill['tip'] == 'Lahko učim druge';

                return Chip(
                  backgroundColor: canTeach
                      ? Colors.teal.shade50
                      : Colors.amber.shade50,
                  side: BorderSide(
                    color: canTeach
                        ? Colors.teal.shade100
                        : Colors.amber.shade100,
                  ),
                  avatar: Icon(
                    canTeach ? Icons.volunteer_activism : Icons.school,
                    color: canTeach
                        ? const Color(0xff009688)
                        : Colors.amber.shade800,
                    size: 18,
                  ),
                  label: Text(
                    '${skill['naziv'] ?? ''} • ${skill['nivoZnanja'] ?? ''}',
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _emptyCommunity() {
    return Center(
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
              Icon(Icons.groups_2_outlined, size: 58, color: Color(0xff009688)),
              SizedBox(height: 16),
              Text(
                'Ni dodanih uporabnikov',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff004d40),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ko uporabniki ustvarijo profil, bodo prikazani tukaj.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
