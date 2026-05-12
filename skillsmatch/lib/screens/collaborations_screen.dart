import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
const _kBg = Color(0xFFF0F0FF);
const _kCard = Color(0xFFFFFFFF);
const _kText = Color(0xFF1E1B4B);
const _kSub = Color(0xFF6B7280);
const _kBorder = Color(0xFFE2E8F0);
const _kGreen = Color(0xFF059669);
const _kAmber = Color(0xFFD97706);
const _kRed = Color(0xFFEF4444);

class _OrbPainter extends CustomPainter {
  final double t;

  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (0.12, 0.20, 75.0, const Color(0x35818CF8)),
      (0.82, 0.12, 55.0, const Color(0x307C3AED)),
      (0.55, 0.78, 65.0, const Color(0x284F46E5)),
      (0.92, 0.60, 45.0, const Color(0x22818CF8)),
      (0.28, 0.88, 50.0, const Color(0x307C3AED)),
    ];

    for (var (rx, ry, r, color) in orbs) {
      final dx = math.sin(t + rx * 6) * 14;
      final dy = math.cos(t + ry * 4) * 11;
      final cx = size.width * rx + dx;
      final cy = size.height * ry + dy;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => oldDelegate.t != t;
}

class _StarPainter extends CustomPainter {
  final double t;

  _StarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final stars = [
      (0.15, 0.18, 3.5),
      (0.82, 0.22, 2.8),
      (0.65, 0.08, 2.2),
      (0.35, 0.30, 2.0),
      (0.90, 0.45, 3.0),
      (0.08, 0.55, 2.5),
      (0.72, 0.68, 2.0),
      (0.48, 0.75, 3.2),
    ];

    for (var (rx, ry, r) in stars) {
      final opacity = (0.4 + 0.4 * math.sin(t * 2.5 + rx * 10))
          .clamp(0.1, 0.9);

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final cx = size.width * rx;
      final cy = size.height * ry;
      final scale = 0.7 + 0.3 * math.sin(t * 1.8 + ry * 8);

      canvas.drawCircle(Offset(cx, cy), r * scale, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.t != t;
}

class CollaborationsScreen extends StatefulWidget {
  const CollaborationsScreen({super.key});

  @override
  State<CollaborationsScreen> createState() => _CollaborationsScreenState();
}

class _CollaborationsScreenState extends State<CollaborationsScreen>
    with TickerProviderStateMixin {
  String selectedTab = 'received';
  bool isUpdating = false;

  late AnimationController _orbCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final query = FirebaseFirestore.instance.collection('collaborations');

    if (selectedTab == 'received') {
      return query.where('receiverId', isEqualTo: currentUid).snapshots();
    }

    return query.where('requesterId', isEqualTo: currentUid).snapshots();
  }

  Future<void> _ensureChatExists(
    String collaborationId,
    Map<String, dynamic> data,
  ) async {
    final requesterId = (data['requesterId'] ?? '').toString();
    final receiverId = (data['receiverId'] ?? '').toString();

    if (requesterId.isEmpty || receiverId.isEmpty) {
      throw Exception('Manjka requesterId ali receiverId.');
    }

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(collaborationId);

    await chatRef.set({
      'collaborationId': collaborationId,
      'users': [requesterId, receiverId],
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _openChat(
    String collaborationId,
    Map<String, dynamic> data,
    String otherName,
  ) async {
    try {
      _showSnack('Odpiram sporočila...');

      await _ensureChatExists(collaborationId, data);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: collaborationId,
            otherUserName: otherName.isEmpty ? 'Neznan uporabnik' : otherName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Napaka pri odpiranju sporočil: $e', color: _kRed);
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    if (isUpdating) return;

    setState(() => isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('collaborations')
          .doc(docId)
          .set({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;

      _showSnack(
        status == 'accepted'
            ? 'Povabilo je bilo sprejeto.'
            : status == 'rejected'
            ? 'Povabilo je bilo zavrnjeno.'
            : 'Sodelovanje je zaključeno.',
        color: status == 'rejected' ? _kRed : _kPrimary,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Napaka pri posodobitvi: $e', color: _kRed);
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  Future<void> _confirmStatusChange(
    String docId,
    String status,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: const TextStyle(color: _kText, fontWeight: FontWeight.w900),
          ),
          content: Text(
            message,
            style: const TextStyle(color: _kSub, height: 1.45),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Prekliči',
                style: TextStyle(color: _kSub, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'rejected' ? _kRed : _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Potrdi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _updateStatus(docId, status);
    }
  }
  Future<void> _openReviewDialog(String docId, Map<String, dynamic> data) async {
  int rating = 0;
  final commentController = TextEditingController();

final requesterId = (data['requesterId'] ?? '').toString();
final receiverId = (data['receiverId'] ?? '').toString();

final otherUserId = requesterId == currentUid ? receiverId : requesterId;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Oceni sodelovanje',
              style: TextStyle(
                color: _kText,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final selected = index < rating;

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              rating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 180),
                              scale: selected ? 1.08 : 1,
                              child: Icon(
                                selected
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: _kAmber,
                                size: 30,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                const SizedBox(height: 10),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Napiši kratek komentar...',
                    hintStyle: const TextStyle(color: _kSub),
                    filled: true,
                    fillColor: const Color(0xFFF8F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _kPrimary, width: 1.4),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Prekliči',
                  style: TextStyle(color: _kSub, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: rating == 0
                  ? null
                  : () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAmber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Shrani',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == true) {
  if (rating == 0) {
    _showSnack('Najprej izberi število zvezdic.', color: _kRed);
    return;
  }

  if (otherUserId.isEmpty) {
    _showSnack('Napaka: uporabnik za oceno ni najden.', color: _kRed);
    return;
  }
  final myDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(currentUid)
    .get();

final myData = myDoc.data() ?? {};

final reviewerName =
    '${myData['ime'] ?? ''} ${myData['priimek'] ?? ''}'.trim();

  await FirebaseFirestore.instance
      .collection('reviews')
      .doc('${docId}_$currentUid')
      .set({
    'collaborationId': docId,
    'reviewerId': currentUid,
    'reviewerName': reviewerName.isEmpty ? 'Neznan uporabnik' : reviewerName,
    'reviewedUserId': otherUserId,
    'rating': rating,
    'comment': commentController.text.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  });

  if (!mounted) return;
  _showSnack('Ocena je shranjena.', color: _kGreen);
}
}

  void _showSnack(String text, {Color color = _kPrimary}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return _kGreen;
      case 'rejected':
        return _kRed;
      case 'completed':
        return _kPrimary;
      default:
        return _kAmber;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'completed':
        return Icons.verified_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Sprejeto';
      case 'rejected':
        return 'Zavrnjeno';
      case 'completed':
        return 'Zaključeno';
      default:
        return 'Čaka';
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day}.${d.month}.${d.year}';
    }

    return 'Ni datuma';
  }

  Widget _header() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbCtrl, _pulseCtrl, _floatCtrl]),
      builder: (_, __) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 52, 22, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E1B4B),
                Color(0xFF3730A3),
                Color(0xFF4F46E5),
                Color(0xFF818CF8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbPainter(_orbCtrl.value * 2 * math.pi),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _StarPainter(_orbCtrl.value * 2 * math.pi),
                ),
              ),
              Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _pulseAnim.value * 1.18,
                              child: Container(
                                width: 138,
                                height: 138,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.10),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _pulseAnim.value * 1.08,
                              child: Container(
                                width: 124,
                                height: 124,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _pulseAnim.value,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.38),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 98,
                              height: 98,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.55),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.30),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: _kViolet.withOpacity(0.45),
                                    blurRadius: 26,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: _kPrimary.withOpacity(0.30),
                                    blurRadius: 44,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/slika1.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.handshake_rounded,
                                    color: Colors.white,
                                    size: 46,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sodelovanja',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Preglej povabila, termine in statuse sodelovanj.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _tabButton(
            label: 'Prejeta',
            icon: Icons.inbox_rounded,
            value: 'received',
          ),
          _tabButton(label: 'Poslana', icon: Icons.send_rounded, value: 'sent'),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final selected = selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (selectedTab != value) {
            setState(() => selectedTab = value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 46,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : _kSub),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _kSub,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 120),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_kPrimary, _kViolet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.26),
                            blurRadius: 16,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Icon(
                        selectedTab == 'received'
                            ? Icons.mark_email_unread_rounded
                            : Icons.outbox_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedTab == 'received'
                          ? 'Ni prejetih povabil'
                          : 'Ni poslanih povabil',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedTab == 'received'
                          ? 'Ko vam nekdo pošlje povabilo, bo prikazano tukaj.'
                          : 'Povabila lahko pošljete iz profila uporabnika.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _kSub,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _collaborationCard(String docId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'pending').toString();
    final statusColor = _statusColor(status);

    final otherName = selectedTab == 'received'
        ? (data['requesterName'] ?? 'Neznan uporabnik').toString().trim()
        : (data['receiverName'] ?? 'Neznan uporabnik').toString().trim();

    final skillName = (data['skillName'] ?? 'Ni izbrane veščine').toString();
    final message = (data['message'] ?? '').toString().trim();
    final time = (data['time'] ?? 'Ni ure').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  selectedTab == 'received'
                      ? Icons.call_received_rounded
                      : Icons.call_made_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName.isEmpty ? 'Neznan uporabnik' : otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skillName.isEmpty ? 'Ni izbrane veščine' : skillName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status, statusColor),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _miniInfo(
                Icons.calendar_month_rounded,
                _formatDate(data['date']),
              ),
              const SizedBox(width: 8),
              _miniInfo(Icons.access_time_rounded, time),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FF),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _kBorder),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: _kSub,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (selectedTab == 'received' && status == 'pending') ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUpdating
                        ? null
                        : () => _confirmStatusChange(
                            docId,
                            'rejected',
                            'Zavrni povabilo?',
                            'Ali si prepričana, da želiš zavrniti to povabilo?',
                          ),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Zavrni'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kRed,
                      side: const BorderSide(color: _kRed),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUpdating
                        ? null
                        : () => _confirmStatusChange(
                            docId,
                            'accepted',
                            'Sprejmi povabilo?',
                            'Po sprejemu bosta lahko nadaljevala sodelovanje, sporočila in video klic.',
                          ),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Sprejmi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'accepted') ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Sporočila',
                    filled: true,
                    onTap: () => _openChat(docId, data, otherName),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    icon: Icons.video_call_rounded,
                    label: 'Video klic',
                    filled: true,
                    onTap: () {
                      _showSnack('Video klic bo dodan v naslednjem koraku.');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isUpdating
                    ? null
                    : () => _confirmStatusChange(
                        docId,
                        'completed',
                        'Zaključi sodelovanje?',
                        'Sodelovanje bo označeno kot zaključeno.',
                      ),
                icon: const Icon(Icons.done_all_rounded, size: 17),
                label: const Text('Označi kot zaključeno'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          if (status == 'completed') ...[
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openReviewDialog(docId, data),
                    icon: const Icon(Icons.star_rounded, size: 17),
                    label: const Text('Oceni sodelovanje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAmber,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 13, color: statusColor),
          const SizedBox(width: 4),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5FF),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: _kPrimary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUid.isEmpty) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Text(
            'Uporabnik ni prijavljen.',
            style: TextStyle(color: _kText, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _header(),
            _tabs(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kPrimary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Text(
                          'Napaka: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _kRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _emptyState();
                  }

                  docs.sort((a, b) {
                    final ad = a.data()['createdAt'];
                    final bd = b.data()['createdAt'];

                    if (ad is Timestamp && bd is Timestamp) {
                      return bd.compareTo(ad);
                    }

                    return 0;
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 112),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return _collaborationCard(doc.id, doc.data());
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}