import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'call_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart'; // added for dynamic theme
import '../services/encryption_service.dart';
import '../services/service_locator.dart'; // added for service locator
import 'chat_info_screen.dart';

// Brand / Accent Colors (stay the same)
const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
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
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isRecording = false;
  bool isUploadingVoice = false;
  String? playingVoiceUrl;
  bool isUploadingImage = false;
  bool isSending = false;
  bool showEmojiPicker = false;

  String get currentUid => ServiceLocator.auth.currentUser?.uid ?? '';

  List<Color> _themeColors(String themeId) {
  switch (themeId) {
    case 'green':
      return [const Color(0xFF16A34A), const Color(0xFF22C55E)];

    case 'pink':
      return [const Color(0xFFDB2777), const Color(0xFFF472B6)];

    case 'blue':
      return [const Color(0xFF2563EB), const Color(0xFF38BDF8)];

    case 'orange':
      return [const Color(0xFFEA580C), const Color(0xFFF97316)];

    case 'purple':
    default:
      return [const Color(0xFF4F46E5), const Color(0xFF7C3AED)];
  }
}

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

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _setMyOnlineStatus(bool online) async {
    if (currentUid.isEmpty) return;
    try {
      await ServiceLocator.firestore.collection('users').doc(currentUid).set({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<String?> _getOtherUserId() async {
    final chatDoc = await ServiceLocator.firestore
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

  Future<void> _openChatInfo() async {
    final otherUid = await _getOtherUserId();

    if (otherUid == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatInfoScreen(
          chatId: widget.chatId,
          otherUserName: widget.otherUserName,
          otherUserId: otherUid,
          onAudioCall: () => _startCall(isVideo: false),
          onVideoCall: () => _startCall(isVideo: true),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    if (currentUid.isEmpty || isUploadingImage) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => isUploadingImage = true);
    try {
      final file = File(picked.path);
      final imageUrl = await CloudinaryService.uploadChatImage(file);
      final chatRef = ServiceLocator.firestore
          .collection('chats')
          .doc(widget.chatId);
      await chatRef.collection('messages').add({
        'senderId': currentUid,
        'type': 'image',
        'text': '',
        'mediaUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
        'seenAt': null,
      });
      await chatRef.set({
        'lastMessage': '📷 Slika',
        'lastMessageSenderId': currentUid,
        'lastMessageSeen': false,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final otherUid = await _getOtherUserId();

if (otherUid != null) {
  final chatDoc = await ServiceLocator.firestore
      .collection('chats')
      .doc(widget.chatId)
      .get();

  final muted =
      chatDoc.data()?['notificationsMuted'] == true;

  if (!muted) {
    await http.post(
      Uri.parse(
        'https://skillsmatchnotifications.onrender.com/send-notification',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receiverId': otherUid,
        'title': 'Novo sporočilo',
        'body': '📷 Poslana je slika',
        'chatId': widget.chatId,
        'senderId': currentUid,
      }),
    );
  }
}
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Napaka pri pošiljanju slike: $e'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isUploadingImage = false);
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (isUploadingVoice) return;
    if (isRecording) {
      setState(() {
        isRecording = false;
        isUploadingVoice = true;
      });
      try {
        final path = await _audioRecorder.stop();
        if (path == null) return;
        final voiceUrl = await CloudinaryService.uploadVoiceMessage(File(path));
        final chatRef = ServiceLocator.firestore
            .collection('chats')
            .doc(widget.chatId);
        await chatRef.collection('messages').add({
          'senderId': currentUid,
          'type': 'voice',
          'text': '',
          'mediaUrl': voiceUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
          'seenAt': null,
        });
        await chatRef.set({
          'lastMessage': '🎤 Glasovno sporočilo',
          'lastMessageSenderId': currentUid,
          'lastMessageSeen': false,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _scrollToBottom();
      } catch (e) {
        _showErrorSnack('Napaka pri pošiljanju voice message.');
      } finally {
        if (mounted) setState(() => isUploadingVoice = false);
      }
      return;
    }
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showErrorSnack('Ni dovoljenja za mikrofon.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(), path: path);
    setState(() => isRecording = true);
  }

  Future<void> _markMessagesAsSeen() async {
    if (currentUid.isEmpty) return;
    try {
      final query = await ServiceLocator.firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUid)
          .where('seen', isEqualTo: false)
          .get();
      if (query.docs.isEmpty) return;
      final batch = ServiceLocator.firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'seen': true,
          'seenAt': FieldValue.serverTimestamp(),
        });
      }
      batch.set(
        ServiceLocator.firestore.collection('chats').doc(widget.chatId),
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
      final encryptedText = EncryptionService.encryptMessage(text);

      final chatRef = ServiceLocator.firestore
          .collection('chats')
          .doc(widget.chatId);

      await chatRef.collection('messages').add({
        'senderId': currentUid,
        'type': 'text',
        'text': encryptedText,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
        'seenAt': null,
        'encrypted': true,
      });

      await chatRef.set({
        'lastMessage': '💬 Novo sporočilo',
        'lastMessageSenderId': currentUid,
        'lastMessageSeen': false,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final otherUid = await _getOtherUserId();

if (otherUid != null) {
  final chatDoc = await ServiceLocator.firestore
      .collection('chats')
      .doc(widget.chatId)
      .get();

  final muted =
      chatDoc.data()?['notificationsMuted'] == true;

  if (!muted) {
    await http.post(
      Uri.parse(
        'https://skillsmatchnotifications.onrender.com/send-notification',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receiverId': otherUid,
        'title': 'Novo sporočilo',
        'body': '💬 Novo sporočilo',
        'chatId': widget.chatId,
        'senderId': currentUid,
      }),
    );
  }
}

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

    final staleCalls = await ServiceLocator.firestore
        .collection('calls')
        .where('status', whereIn: ['ringing', 'answered'])
        .where(
          'createdAt',
          isLessThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        )
        .get();
    for (final doc in staleCalls.docs) {
      await doc.reference.update({'status': 'expired'});
    }

    final existingCall = await ServiceLocator.firestore
        .collection('calls')
        .where('callerId', whereIn: [currentUid, otherUid])
        .where('receiverId', whereIn: [currentUid, otherUid])
        .where('status', whereIn: ['ringing', 'answered'])
        .where(
          'createdAt',
          isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        )
        .get();
    if (existingCall.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ze obstaja aktiven klic'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: _kPrimary)),
    );

    try {
      final currentUser = ServiceLocator.auth.currentUser;
      if (currentUser == null) throw Exception('Niste prijavljeni');
      final callerDoc = await ServiceLocator.firestore
          .collection('users')
          .doc(currentUid)
          .get();
      final callerName = callerDoc.data()?['ime'] ?? 'Nepoznat';
      final receiverDoc = await ServiceLocator.firestore
          .collection('users')
          .doc(otherUid)
          .get();
      final receiverFcmToken = receiverDoc.data()?['fcmToken'];
      if (receiverFcmToken == null)
        throw Exception('Korisnik nije dostupan za pozive');

      final response = await http.post(
        Uri.parse('https://skillsmatch-server.onrender.com/call/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'callerIdentity': currentUid,
          'receiverIdentity': otherUid,
          'receiverFcmToken': receiverFcmToken,
          'callerName': callerName,
          'isVideoCall': isVideo,
        }),
      );
      if (response.statusCode != 200)
        throw Exception('Server greška: ${response.statusCode}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final roomName = body['roomName'].toString();
      final token = body['token'].toString();
      final liveKitUrl = body['liveKitUrl'].toString();
      final callId = body['callId'].toString();

      await ServiceLocator.firestore.collection('calls').doc(callId).set({
        'callId': callId,
        'callerId': currentUid,
        'callerName': callerName,
        'receiverId': otherUid,
        'receiverName': widget.otherUserName,
        'isVideo': isVideo,
        'status': 'ringing',
        'roomName': roomName,
        'livekitUrl': liveKitUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            roomName: roomName,
            token: token,
            livekitUrl: liveKitUrl,
            isVideoCall: isVideo,
            otherUserName: widget.otherUserName,
            callId: callId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
          color: context.kCardBg.withOpacity(0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.kBorder),
        ),
        child: Text(
          'Danes',
          style: TextStyle(
            color: context.kTextSub,
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
  required List<Color> themeColors,
}) {
    final isMe = data['senderId'] == currentUid;
    final type = (data['type'] ?? 'text').toString();
    final rawText = (data['text'] ?? '').toString();
    final isEncrypted = data['encrypted'] == true;

    final text = isEncrypted
        ? EncryptionService.decryptMessage(rawText)
        : rawText;
    final mediaUrl = (data['mediaUrl'] ?? '').toString();
    final seen = data['seen'] == true;
    final time = _formatTime(data['createdAt']);
    final isPlayingThisVoice = playingVoiceUrl == mediaUrl;

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
              padding: type == 'image'
                  ? const EdgeInsets.fromLTRB(7, 7, 7, 9)
                  : const EdgeInsets.fromLTRB(16, 13, 16, 11),
              decoration: BoxDecoration(
                gradient: isMe
                  ? LinearGradient(
                      colors: themeColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
                color: isMe ? null : context.kCardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 22),
                ),
                border: isMe ? null : Border.all(color: context.kBorder),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (type == 'image' && mediaUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        mediaUrl,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (type == 'voice' && mediaUrl.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (playingVoiceUrl == mediaUrl) {
                              await _audioPlayer.stop();
                              setState(() => playingVoiceUrl = null);
                            } else {
                              await _audioPlayer.stop();
                              await _audioPlayer.play(UrlSource(mediaUrl));
                              setState(() => playingVoiceUrl = mediaUrl);
                              _audioPlayer.onPlayerComplete.listen((event) {
                                if (mounted)
                                  setState(() => playingVoiceUrl = null);
                              });
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withOpacity(0.20)
                                  : _kPrimary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlayingThisVoice
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: isMe ? Colors.white : _kPrimary,
                              size: 25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Glasovno sporočilo',
                          style: TextStyle(
                            color: isMe ? Colors.white : context.kText,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.graphic_eq_rounded,
                          color: isMe ? Colors.white70 : context.kTextSub,
                          size: 22,
                        ),
                      ],
                    )
                  else
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : context.kText,
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
                          color: isMe ? Colors.white70 : context.kTextSub,
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
                gradient: const LinearGradient(colors: [_kPrimary, _kViolet]),
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
            Text(
              'Ni sporočil',
              style: TextStyle(
                color: context.kText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Začni pogovor in pošlji prvo sporočilo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.kTextSub,
                fontSize: 13,
                height: 1.4,
              ),
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
        color: context.kBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 7, 6),
        decoration: BoxDecoration(
          color: context.kCardBg,
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
              key: Key('image_picker_button'),
              onPressed: isUploadingImage ? null : _pickAndSendImage,
              icon: isUploadingImage
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kPrimary,
                      ),
                    )
                  : Icon(Icons.image_rounded, color: _kPrimary, size: 25),
            ),
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
                key: Key('message_input'),
                controller: _messageController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(color: context.kText),
                decoration: InputDecoration(
                  hintText: 'Napiši sporočilo...',
                  hintStyle: TextStyle(
                    color: context.kTextSub,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            GestureDetector(
              key: Key('voice_record_button'),
              onTap: _toggleVoiceRecording,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRecording ? _kRed : _kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: isRecording ? Colors.white : _kPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              key: Key('send_button'),
              onTap: isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kPrimary, _kViolet]),
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
    final isDark = context.isDark;
    final backgroundColor = isDark ? context.kCardBg : Colors.white;
    return SizedBox(
      height: 245,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => _addEmoji(emoji.emoji),
        onBackspacePressed: _deleteEmojiOrChar,
        config: Config(
          height: 245,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 26,
            columns: 7,
            backgroundColor: backgroundColor,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: backgroundColor,
            indicatorColor: _kPrimary,
            iconColorSelected: _kPrimary,
            iconColor: isDark ? Colors.grey : Colors.grey,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: backgroundColor,
            buttonColor: _kPrimary,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: backgroundColor,
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
      backgroundColor: context.kCardBg,
      surfaceTintColor: context.kCardBg,
      foregroundColor: context.kText,
      toolbarHeight: 92,
      titleSpacing: 0,
      title: FutureBuilder<String?>(
        future: _getOtherUserId(),
        builder: (context, userSnapshot) {
          final otherUid = userSnapshot.data;
          if (otherUid == null) {
            return _headerContent(isOnline: false, subtitle: 'Sodelovanje');
          }
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: ServiceLocator.firestore
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
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          GestureDetector(
            onTap: _openChatInfo,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: _kPrimary,
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: GestureDetector(
              onTap: _openChatInfo,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.otherUserName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.kText,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: context.kTextSub,
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isOnline ? Colors.green : context.kTextSub,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          IconButton(
            onPressed: () => _startCall(isVideo: false),
            icon: const Icon(Icons.call),
          ),

          IconButton(
            onPressed: () => _startCall(isVideo: true),
            icon: const Icon(Icons.videocam),
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _openChatInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('Chat info')),
            ],
          ),
        ],
      ),
    );
  }

Widget _messagesBody(List<Color> themeColors) { 
     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ServiceLocator.firestore
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
        if (docs.isEmpty) return _emptyChat();

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
              themeColors: themeColors,
            );
          },
        );
      },
    );
  }
@override
Widget build(BuildContext context) {
  if (currentUid.isEmpty) {
    return Scaffold(
      backgroundColor: context.kBg,
      body: Center(
        child: Text(
          'Uporabnik ni prijavljen.',
          style: TextStyle(color: context.kText),
        ),
      ),
    );
  }

  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: ServiceLocator.firestore
        .collection('chats')
        .doc(widget.chatId)
        .snapshots(),
    builder: (context, chatSnapshot) {
      final themeId =
          chatSnapshot.data?.data()?['theme']?.toString() ?? 'purple';

      final themeColors = _themeColors(themeId);

      final chatBackground = switch (themeId) {
        'green' => const Color.fromARGB(255, 218, 255, 229),
        'pink' => const Color.fromARGB(255, 254, 208, 233),
        'blue' => const Color.fromARGB(255, 212, 229, 255),
        'orange' => const Color.fromARGB(255, 247, 230, 210),
        _ => context.kBg,
      };

      return PopScope(
        canPop: !showEmojiPicker,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && showEmojiPicker) {
            setState(() => showEmojiPicker = false);
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: chatBackground,
          appBar: _chatHeader(),
          body: Column(
            children: [
              Expanded(child: _messagesBody(themeColors)),
              _bottomChatArea(),
            ],
          ),
        ),
      );
    },
  );
}
}