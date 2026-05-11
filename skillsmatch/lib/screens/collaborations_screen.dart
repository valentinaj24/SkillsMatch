import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
const _kBg = Color(0xFFF0F0FF);
const _kCard = Color(0xFFFFFFFF);
const _kText = Color(0xFF1E1B4B);
const _kSub = Color(0xFF6B7280);
const _kBorder = Color(0xFFE2E8F0);
const _kGreen = Color(0xFF059669);
const _kAmber = Color(0xFFD97706);

class CollaborationsScreen extends StatefulWidget {
  const CollaborationsScreen({super.key});

  @override
  State<CollaborationsScreen> createState() => _CollaborationsScreenState();
}

class _CollaborationsScreenState extends State<CollaborationsScreen> {
  String selectedTab = 'received';

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    if (selectedTab == 'received') {
      return FirebaseFirestore.instance
          .collection('collaborations')
          .where('receiverId', isEqualTo: currentUid)
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('collaborations')
        .where('requesterId', isEqualTo: currentUid)
        .snapshots();
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('collaborations')
        .doc(docId)
        .set({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'accepted'
              ? 'Povabilo je bilo sprejeto.'
              : status == 'rejected'
              ? 'Povabilo je bilo zavrnjeno.'
              : 'Sodelovanje je zaključeno.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kPrimary,
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
        return Colors.redAccent;
      case 'completed':
        return _kPrimary;
      default:
        return _kAmber;
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 58, 22, 28),
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
      ),
      child: const Column(
        children: [
          Icon(Icons.handshake_rounded, color: Colors.white, size: 48),
          SizedBox(height: 14),
          Text(
            'Sodelovanja',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Preglej povabila, termine in statuse sodelovanj.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
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
        onTap: () => setState(() => selectedTab = value),
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
            borderRadius: BorderRadius.circular(14),
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
                  fontWeight: FontWeight.bold,
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
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kPrimary, _kViolet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              selectedTab == 'received'
                  ? 'Ni prejetih povabil'
                  : 'Ni poslanih povabil',
              style: const TextStyle(
                color: _kText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              selectedTab == 'received'
                  ? 'Ko vam nekdo pošlje povabilo, bo prikazano tukaj.'
                  : 'Povabila lahko pošljete iz profila uporabnika.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSub, fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collaborationCard(String docId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'pending').toString();
    final statusColor = _statusColor(status);

    final otherName = selectedTab == 'received'
        ? (data['requesterName'] ?? 'Neznan uporabnik').toString()
        : (data['receiverName'] ?? 'Neznan uporabnik').toString();

    final skillName = (data['skillName'] ?? 'Ni izbrane veščine').toString();
    final message = (data['message'] ?? '').toString();
    final time = (data['time'] ?? 'Ni ure').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  selectedTab == 'received'
                      ? Icons.call_received_rounded
                      : Icons.call_made_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      skillName,
                      style: const TextStyle(color: _kSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

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
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: _kSub, fontSize: 13, height: 1.45),
            ),
          ],

          if (selectedTab == 'received' && status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(docId, 'rejected'),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Zavrni'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(docId, 'accepted'),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Sprejmi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (status == 'accepted') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _updateStatus(docId, 'completed'),
                icon: const Icon(Icons.done_all_rounded, size: 17),
                label: const Text('Označi kot zaključeno'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5FF),
          borderRadius: BorderRadius.circular(12),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _header(),
          _tabs(),
          const SizedBox(height: 14),
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
                    child: Text(
                      'Napaka: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
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
                  padding: const EdgeInsets.only(bottom: 110),
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
    );
  }
}
