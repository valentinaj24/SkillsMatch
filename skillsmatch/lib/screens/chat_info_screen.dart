import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/service_locator.dart';
import '../theme/app_colors.dart';
import 'media_gallery_screen.dart';
import 'search_messages_screen.dart';
import 'chat_theme_screen.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
const _kGreen = Color(0xFF22C55E);
const _kRed = Color(0xFFEF4444);

class ChatInfoScreen extends StatelessWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;

  const ChatInfoScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
    required this.onAudioCall,
    required this.onVideoCall,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _mediaStream() {
    return ServiceLocator.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('type', isEqualTo: 'image')
        .snapshots();
  }

  Future<void> _clearChat(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Obriši chat?'),
        content: const Text('Sve poruke iz ovog chata će biti obrisane.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši', style: TextStyle(color: _kRed)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final messages = await ServiceLocator.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = ServiceLocator.firestore.batch();

    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    batch.set(
      ServiceLocator.firestore.collection('chats').doc(chatId),
      {
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat je obrisan.')));

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
          'Chat info',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ServiceLocator.firestore
            .collection('users')
            .doc(otherUserId)
            .snapshots(),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data?.data() ?? {};
          final isOnline = userData['isOnline'] == true;
          final profileImage = (userData['profileImage'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
            children: [
              const SizedBox(height: 10),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kViolet],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.25),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 66,
                    backgroundColor: context.kCardBg,
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 72,
                            color: _kPrimary,
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  otherUserName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.kText,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? _kGreen.withOpacity(0.12)
                        : context.kCardBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: context.kBorder),
                  ),
                  child: Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: isOnline ? _kGreen : context.kTextSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _BigActionButton(
                      icon: Icons.call_rounded,
                      label: 'Audio',
                      onTap: onAudioCall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigActionButton(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      onTap: onVideoCall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigActionButton(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchMessagesScreen(
                              chatId: chatId,
                              otherUserName: otherUserName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _mediaStream(),
                builder: (context, mediaSnapshot) {
                  final count = mediaSnapshot.data?.docs.length ?? 0;

                  return _SectionCard(
                    children: [
                      _InfoTile(
                        icon: Icons.photo_library_rounded,
                        title: 'Media, slike i dokumenti',
                        trailing: '$count',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MediaGalleryScreen(
                                chatId: chatId,
                                otherUserName: otherUserName,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              _SectionCard(
                children: [
                  _InfoTile(
                    icon: Icons.palette_rounded,
                    title: 'Chat tema',
                    trailing: '',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatThemeScreen(chatId: chatId),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _InfoTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Obriši chat',
                    trailing: '',
                    danger: true,
                    onTap: () => _clearChat(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.kCardBg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.kBorder),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _kPrimary, size: 30),
              const SizedBox(height: 9),
              Text(
                label,
                style: TextStyle(
                  color: context.kText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.kCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.kBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;
  final VoidCallback onTap;
  final bool danger;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _kRed : context.kText;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: TextStyle(
                color: context.kTextSub,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: context.kTextSub),
        ],
      ),
      onTap: onTap,
    );
  }
}
