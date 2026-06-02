import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/service_locator.dart';
import '../theme/app_colors.dart';

const _kPrimary = Color(0xFF4F46E5);

class ChatThemeScreen extends StatelessWidget {
  final String chatId;

  const ChatThemeScreen({super.key, required this.chatId});

  final List<Map<String, dynamic>> themes = const [
    {
      'id': 'purple',
      'name': 'Purple',
      'description': 'Klasična SkillsMatch tema',
      'colors': [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    },
    {
      'id': 'green',
      'name': 'Green',
      'description': 'Mirna zelena tema',
      'colors': [Color(0xFF16A34A), Color(0xFF22C55E)],
    },
    {
      'id': 'pink',
      'name': 'Pink',
      'description': 'Roze soft tema',
      'colors': [Color(0xFFDB2777), Color(0xFFF472B6)],
    },
    {
      'id': 'blue',
      'name': 'Blue',
      'description': 'Plava moderna tema',
      'colors': [Color(0xFF2563EB), Color(0xFF38BDF8)],
    },
    {
      'id': 'orange',
      'name': 'Orange',
      'description': 'Topla narandžasta tema',
      'colors': [Color(0xFFEA580C), Color(0xFFF97316)],
    },
    {
      'id': 'dark',
      'name': 'Dark violet',
      'description': 'Tamna elegantna tema',
      'colors': [Color(0xFF111827), Color(0xFF7C3AED)],
    },
  ];

  Future<void> _saveTheme(BuildContext context, String themeId) async {
    await ServiceLocator.firestore.collection('chats').doc(chatId).set({
      'theme': themeId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tema je uspešno promenjena.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kBg,
      appBar: AppBar(
        backgroundColor: context.kBg,
        elevation: 0,
        foregroundColor: context.kText,
        title: const Text(
          'Chat tema',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ServiceLocator.firestore
            .collection('chats')
            .doc(chatId)
            .snapshots(),
        builder: (context, snapshot) {
          final currentTheme =
              snapshot.data?.data()?['theme']?.toString() ?? 'purple';

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            itemCount: themes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final theme = themes[index];
              final id = theme['id'] as String;
              final name = theme['name'] as String;
              final description = theme['description'] as String;
              final colors = theme['colors'] as List<Color>;
              final selected = currentTheme == id;

              return Material(
                color: context.kCardBg,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _saveTheme(context, id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected ? colors.first : context.kBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: colors),
                            boxShadow: [
                              BoxShadow(
                                color: colors.first.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: context.kText,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  color: context.kTextSub,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.first,
                            size: 28,
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
