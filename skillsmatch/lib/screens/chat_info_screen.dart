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
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              const SizedBox(height: 14),

              Center(
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: _kPrimary.withOpacity(0.15),
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 70,
                          color: _kPrimary,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 18),

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

              const SizedBox(height: 6),

              Center(
                child: Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isOnline ? _kGreen : context.kTextSub,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
                    icon: Icons.notifications_rounded,
                    title: 'Notifikacije',
                    trailing: 'Aktivne',
                    onTap: () {},
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

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.kText),
      title: Text(
        title,
        style: TextStyle(color: context.kText, fontWeight: FontWeight.w800),
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
