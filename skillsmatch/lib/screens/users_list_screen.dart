import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef7f5),
      appBar: AppBar(
        title: const Text('Skupnost uporabnikov'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Ni dodanih uporabnikov.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final vescine = data['vescine'] as List<dynamic>? ?? [];

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 350 + index * 80),
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(30 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: Card(
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  shadowColor: Colors.teal.withOpacity(0.18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.teal,
                              child: Icon(Icons.person, color: Colors.white),
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
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 17,
                                        color: Colors.teal,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(data['lokacija'] ?? ''),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        if ((data['opis'] ?? '').toString().isNotEmpty)
                          Text(
                            data['opis'],
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Colors.teal,
                              size: 19,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Razpoložljivost: ${data['razpolozljivost'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vescine.map((skill) {
                            return Chip(
                              backgroundColor: Colors.teal.shade50,
                              avatar: const Icon(
                                Icons.star,
                                color: Colors.teal,
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
