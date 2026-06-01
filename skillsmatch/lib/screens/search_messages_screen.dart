import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/service_locator.dart';
import '../services/encryption_service.dart';
import '../theme/app_colors.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kRed = Color(0xFFEF4444);

class SearchMessagesScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const SearchMessagesScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<SearchMessagesScreen> createState() => _SearchMessagesScreenState();
}

class _SearchMessagesScreenState extends State<SearchMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(dynamic value) {
    if (value is! Timestamp) return '';
    final d = value.toDate();

    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();

    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');

    return '$day.$month.$year • $hour:$minute';
  }

  String _getMessageText(Map<String, dynamic> data) {
    final type = (data['type'] ?? 'text').toString();

    if (type == 'image') return '📷 Slika';
    if (type == 'voice') return '🎤 Glasovno sporočilo';

    final rawText = (data['text'] ?? '').toString();
    final encrypted = data['encrypted'] == true;

    if (rawText.isEmpty) return '';

    if (encrypted) {
      return EncryptionService.decryptMessage(rawText);
    }

    return rawText;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() {
    return ServiceLocator.firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kBg,
      appBar: AppBar(
        backgroundColor: context.kBg,
        elevation: 0,
        foregroundColor: context.kText,
        title: Text(
          'Search - ${widget.otherUserName}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.kCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.kBorder),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: context.kText),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  icon: const Icon(Icons.search_rounded, color: _kPrimary),
                  hintText: 'Pretraži poruke...',
                  hintStyle: TextStyle(color: context.kTextSub),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => query = '');
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.kTextSub,
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => query = value.trim().toLowerCase());
                },
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Napaka pri pretrazi poruka.',
                      style: TextStyle(color: _kRed),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final results = docs.where((doc) {
                  final text = _getMessageText(doc.data()).toLowerCase();

                  if (query.isEmpty) return false;

                  return text.contains(query);
                }).toList();

                if (query.isEmpty) {
                  return _EmptySearchState(
                    icon: Icons.search_rounded,
                    title: 'Pretraži chat',
                    subtitle:
                        'Unesi reč ili deo poruke koju želiš da pronađeš.',
                  );
                }

                if (results.isEmpty) {
                  return _EmptySearchState(
                    icon: Icons.manage_search_rounded,
                    title: 'Nema rezultata',
                    subtitle: 'Nismo pronašli poruke za: "$query"',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = results[index].data();
                    final text = _getMessageText(data);
                    final date = _formatDateTime(data['createdAt']);

                    return Container(
                      decoration: BoxDecoration(
                        color: context.kCardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.kBorder),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            color: _kPrimary,
                          ),
                        ),
                        title: Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.kText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            date,
                            style: TextStyle(
                              color: context.kTextSub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptySearchState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: context.kTextSub),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.kText,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.kTextSub,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
