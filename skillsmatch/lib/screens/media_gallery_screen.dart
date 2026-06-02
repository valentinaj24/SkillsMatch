import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/service_locator.dart';
import '../theme/app_colors.dart';

const _kPrimary = Color(0xFF4F46E5);

class MediaGalleryScreen extends StatelessWidget {
  final String chatId;
  final String otherUserName;

  const MediaGalleryScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _imagesStream() {
  return ServiceLocator.firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .where('type', isEqualTo: 'image')
      .snapshots();
}

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';
    final d = value.toDate();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
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
          'Media - $otherUserName',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _imagesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Napaka pri nalaganju slik.',
                style: TextStyle(color: context.kText),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 70,
                      color: context.kTextSub,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nema poslatih slika',
                      style: TextStyle(
                        color: context.kText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sve slike koje pošaljete u ovom chatu biće prikazane ovde.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.kTextSub, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final imageUrl = (data['mediaUrl'] ?? '').toString();
              final date = _formatDate(data['createdAt']);

              if (imageUrl.isEmpty) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullImageScreen(imageUrl: imageUrl, date: date),
                    ),
                  );
                },
                child: Hero(
                  tag: imageUrl,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: context.kCardBg,
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: context.kTextSub,
                          ),
                        );
                      },
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

class FullImageScreen extends StatelessWidget {
  final String imageUrl;
  final String date;

  const FullImageScreen({
    super.key,
    required this.imageUrl,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          date.isEmpty ? 'Slika' : date,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
