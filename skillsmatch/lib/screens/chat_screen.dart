import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'call_screen.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
const _kBg = Color(0xFFF0F0FF);
const _kText = Color(0xFF1E1B4B);
const _kSub = Color(0xFF6B7280);
const _kBorder = Color(0xFFE2E8F0);
const _kGreen = Color(0xFF22C55E);
const _kSeenGreen = Color(0xFF86EFAC);
const _kRed = Color(0xFFEF4444);

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool isSending = false;
  bool showEmojiPicker = false;

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setMyOnlineStatus(true);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && showEmojiPicker) {
        setState(() => showEmojiPicker = false);
      }
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _markMessagesAsSeen();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setMyOnlineStatus(false);

    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (currentUid.isEmpty) return;

    if (state == AppLifecycleState.resumed) {
      _setMyOnlineStatus(true);
    } else {
      _setMyOnlineStatus(false);
    }
  }

  Future<void> _setMyOnlineStatus(bool online) async {
    if (currentUid.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).set({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<String?> _getOtherUserId() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();

    final data = chatDoc.data();
    if (data == null) return null;

    final users = List<String>.from(data['users'] ?? []);

    for (final uid in users) {
      if (uid != currentUid) return uid;
    }

    return null;
  }

  Future<void> _markMessagesAsSeen() async {
    if (currentUid.isEmpty) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUid)
          .where('seen', isEqualTo: false)
          .get();

      if (query.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'seen': true,
          'seenAt': FieldValue.serverTimestamp(),
        });
      }

      batch.set(
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId),
        {'lastMessageSeen': true, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || currentUid.isEmpty || isSending) return;

    setState(() => isSending = true);
    _messageController.clear();

    try {
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId);

      await chatRef.collection('messages').add({
        'senderId': currentUid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
        'seenAt': null,
      });

      await chatRef.set({
        'lastMessage': text,
        'lastMessageSenderId': currentUid,
        'lastMessageSeen': false,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Napaka pri pošiljanju: $e'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<void> _startCall({required bool isVideo}) async {
  final otherUid = await _getOtherUserId();
  if (otherUid == null || !mounted) return;

  try {
    final response = await http.post(
      Uri.parse('https://skillsmatch-server.onrender.com/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'roomName': widget.chatId,
        'identity': currentUid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server greška: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'].toString();
    const livekitUrl = 'wss://skillsmatch-i3o8zkcc.livekit.cloud';

    // Obavijesti drugu osobu o pozivu
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.chatId)
        .set({
      'callerId': currentUid,
      'callerName': FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
        ? FirebaseAuth.instance.currentUser!.displayName!
        : (await FirebaseFirestore.instance.collection('users').doc(currentUid).get())
            .data()?['ime'] ?? 'Neznani',
      'receiverId': otherUid,
      'isVideo': isVideo,
      'status': 'ringing',
      'roomName': widget.chatId,
      'livekitUrl': 'wss://skillsmatch-i3o8zkcc.livekit.cloud',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final callerDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(currentUid)
    .get();

    debugPrint('✅ call from $currentUid (ime: ${callerDoc.data()?['ime']}) to $otherUid');

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          roomName: widget.chatId,
          token: token,
          livekitUrl: livekitUrl,
          isVideoCall: isVideo,
          otherUserName: widget.otherUserName,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Napaka pri klicu: $e'),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  void _toggleEmojiPicker() {
    if (showEmojiPicker) {
      setState(() => showEmojiPicker = false);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => showEmojiPicker = true);
      });
    }
  }

  void _addEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;

    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;

    final newText = text.replaceRange(start, end, emoji);
    final newOffset = start + emoji.length;

    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _deleteEmojiOrChar() {
    final text = _messageController.text;
    final selection = _messageController.selection;

    if (text.isEmpty) return;

    final cursor = selection.start < 0 ? text.length : selection.start;
    if (cursor == 0) return;

    final newText = text.replaceRange(cursor - 1, cursor, '');

    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor - 1),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  String _formatLastSeen(dynamic value) {
    if (value is! Timestamp) return 'Ni podatka';

    final d = value.toDate();
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inMinutes < 1) return 'pravkar';
    if (diff.inMinutes < 60) return 'pred ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'pred ${diff.inHours} h';

    return '${d.day}.${d.month}.${d.year}';
  }

  Widget _dateChip() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white),
        ),
        child: const Text(
          'Danes',
          style: TextStyle(
            color: _kSub,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _messageBubble(
    Map<String, dynamic> data, {
    required bool isLastMyMessage,
    required bool showDateChip,
  }) {
    final isMe = data['senderId'] == currentUid;
    final text = (data['text'] ?? '').toString();
    final seen = data['seen'] == true;
    final time = _formatTime(data['createdAt']);

    return Column(
      children: [
        if (showDateChip) _dateChip(),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              left: isMe ? 70 : 18,
              right: isMe ? 18 : 70,
              top: 7,
              bottom: 7,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF6D28D9),
                          Color(0xFF7C3AED),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 22),
                ),
                border: isMe ? null : Border.all(color: _kBorder),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? _kPrimary.withOpacity(0.22)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : _kText,
                      fontSize: 15,
                      height: 1.38,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : _kSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 10),
                        Icon(
                          seen ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 18,
                          color: seen ? _kSeenGreen : Colors.white70,
                        ),
                        if (isLastMyMessage) ...[
                          const SizedBox(width: 4),
                          Text(
                            seen ? 'Videno' : 'Poslano',
                            style: TextStyle(
                              color: seen ? _kSeenGreen : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kViolet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 35,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ni sporočil',
              style: TextStyle(
                color: _kText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Začni pogovor in pošlji prvo sporočilo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSub, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: _kBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 7, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _toggleEmojiPicker,
              icon: Icon(
                showEmojiPicker
                    ? Icons.keyboard_alt_rounded
                    : Icons.emoji_emotions_outlined,
                color: _kPrimary,
                size: 26,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Napiši sporočilo...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            GestureDetector(
              onTap: isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiPicker() {
    return SizedBox(
      height: 245,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _addEmoji(emoji.emoji);
        },
        onBackspacePressed: _deleteEmojiOrChar,
        config: const Config(
          height: 245,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 26,
            columns: 7,
            backgroundColor: Colors.white,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: Colors.white,
            indicatorColor: _kPrimary,
            iconColorSelected: _kPrimary,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: Colors.white,
            buttonColor: _kPrimary,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: Colors.white,
            buttonIconColor: _kPrimary,
          ),
        ),
      ),
    );
  }

  Widget _bottomChatArea() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_inputBar(), if (showEmojiPicker) _emojiPicker()],
      ),
    );
  }

  PreferredSizeWidget _chatHeader() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: _kText,
      toolbarHeight: 76,
      titleSpacing: 0,
      title: FutureBuilder<String?>(
        future: _getOtherUserId(),
        builder: (context, userSnapshot) {
          final otherUid = userSnapshot.data;

          if (otherUid == null) {
            return _headerContent(isOnline: false, subtitle: 'Sodelovanje');
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(otherUid)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? {};
              final isOnline = data['isOnline'] == true;
              final lastSeen = data['lastSeen'];

              return _headerContent(
                isOnline: isOnline,
                subtitle: isOnline
                    ? 'Online'
                    : 'Zadnjič videno: ${_formatLastSeen(lastSeen)}',
              );
            },
          );
        },
      ),
    );
  }

  Widget _headerContent({required bool isOnline, required String subtitle}) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kViolet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: isOnline ? _kGreen : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isOnline ? _kGreen : _kSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _startCall(isVideo: false),
          icon: const Icon(Icons.call_rounded, color: _kPrimary, size: 24),
        ),
        IconButton(
          onPressed: () => _startCall(isVideo: true),
          icon: const Icon(Icons.videocam_rounded, color: _kPrimary, size: 27),
        ),
      ],
    );
  }

  Widget _messagesBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _kPrimary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Napaka: ${snapshot.error}',
              style: const TextStyle(color: _kRed),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyChat();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markMessagesAsSeen();
          _scrollToBottom();
        });

        int lastMyMessageIndex = -1;

        for (int i = docs.length - 1; i >= 0; i--) {
          if (docs[i].data()['senderId'] == currentUid) {
            lastMyMessageIndex = i;
            break;
          }
        }

        return ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(0, 22, 0, 18),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _messageBubble(
              docs[index].data(),
              isLastMyMessage: index == lastMyMessageIndex,
              showDateChip: index == 0,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUid.isEmpty) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: Text('Uporabnik ni prijavljen.')),
      );
    }

    return PopScope(
      canPop: !showEmojiPicker,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && showEmojiPicker) {
          setState(() => showEmojiPicker = false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: _kBg,
        appBar: _chatHeader(),
        body: Column(
          children: [
            Expanded(child: _messagesBody()),
            _bottomChatArea(),
          ],
        ),
      ),
    );
  }
}
