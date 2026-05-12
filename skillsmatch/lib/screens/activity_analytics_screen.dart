import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
const _kAmber = Color(0xFFD97706);
const _kGreen = Color(0xFF059669);
const _kRed = Color(0xFFEF4444);
const _kBg = Color(0xFFF0F0FF);
const _kCard = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE2E8F0);
const _kText = Color(0xFF1E1B4B);
const _kSub = Color(0xFF6B7280);

class ActivityAnalyticsScreen extends StatefulWidget {
  const ActivityAnalyticsScreen({super.key});

  @override
  State<ActivityAnalyticsScreen> createState() =>
      _ActivityAnalyticsScreenState();
}

class _ActivityAnalyticsScreenState extends State<ActivityAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbCtrl;

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    _myCollaborationsStream() {
  final sentStream = FirebaseFirestore.instance
      .collection('collaborations')
      .where('requesterId', isEqualTo: currentUid)
      .snapshots();

  final receivedStream = FirebaseFirestore.instance
      .collection('collaborations')
      .where('receiverId', isEqualTo: currentUid)
      .snapshots();

  return sentStream.asyncMap((sentSnap) async {
    final receivedSnap = await FirebaseFirestore.instance
        .collection('collaborations')
        .where('receiverId', isEqualTo: currentUid)
        .get();

    final all = <QueryDocumentSnapshot<Map<String, dynamic>>>[
      ...sentSnap.docs,
      ...receivedSnap.docs,
    ];

    final ids = <String>{};
    return all.where((doc) => ids.add(doc.id)).toList();
  });
}

  Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream() {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: currentUid)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _myCollaborations(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      return data['requesterId'] == currentUid || data['receiverId'] == currentUid;
    }).toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Aktivno';
      case 'completed':
        return 'Zaključeno';
      case 'rejected':
        return 'Zavrnjeno';
      default:
        return 'Čaka';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return _kGreen;
      case 'completed':
        return _kPrimary;
      case 'rejected':
        return _kRed;
      default:
        return _kAmber;
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day}.${d.month}.${d.year}';
    }
    return 'Ni datuma';
  }

  String _topSkill(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final counts = <String, int>{};

    for (final doc in docs) {
      final skill = (doc.data()['skillName'] ?? '').toString().trim();
      if (skill.isNotEmpty) {
        counts[skill] = (counts[skill] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return 'Ni podatka';

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  List<MapEntry<String, int>> _topSkills(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final counts = <String, int>{};

    for (final doc in docs) {
      final skill = (doc.data()['skillName'] ?? '').toString().trim();
      if (skill.isNotEmpty) {
        counts[skill] = (counts[skill] ?? 0) + 1;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
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
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _myCollaborationsStream(),
          builder: (context, collabSnap) {
          if (collabSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }

          if (collabSnap.hasError) {
            return Center(
              child: Text(
                'Napaka: ${collabSnap.error}',
                style: const TextStyle(color: _kRed),
              ),
            );
          }

          final myDocs = collabSnap.data ?? [];

          final completed =
              myDocs.where((d) => d.data()['status'] == 'completed').length;
          final active =
              myDocs.where((d) => d.data()['status'] == 'accepted').length;
          final pending =
              myDocs.where((d) => d.data()['status'] == 'pending').length;
          final rejected =
              myDocs.where((d) => d.data()['status'] == 'rejected').length;

          final topSkill = _topSkill(myDocs);
          final topSkills = _topSkills(myDocs);

          myDocs.sort((a, b) {
            final ad = a.data()['createdAt'];
            final bd = b.data()['createdAt'];

            if (ad is Timestamp && bd is Timestamp) {
              return bd.compareTo(ad);
            }
            return 0;
          });

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _reviewsStream(),
            builder: (context, reviewSnap) {
              final reviewDocs = reviewSnap.data?.docs ?? [];

              double totalRating = 0;
              for (final doc in reviewDocs) {
                totalRating += (doc.data()['rating'] ?? 0).toDouble();
              }

              final avgRating = reviewDocs.isEmpty
                  ? 0.0
                  : totalRating / reviewDocs.length;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _header(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  icon: Icons.done_all_rounded,
                                  title: 'Zaključena',
                                  value: '$completed',
                                  subtitle: 'sodelovanja',
                                  color: _kPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statCard(
                                  icon: Icons.access_time_rounded,
                                  title: 'Aktivna',
                                  value: '$active',
                                  subtitle: 'sodelovanja',
                                  color: _kGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  icon: Icons.people_alt_rounded,
                                  title: 'Skupno',
                                  value: '${myDocs.length}',
                                  subtitle: 'povezav',
                                  color: _kAmber,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statCard(
                                  icon: Icons.star_rounded,
                                  title: 'Ocena',
                                  value: reviewDocs.isEmpty
                                      ? '0.0'
                                      : avgRating.toStringAsFixed(1),
                                  subtitle: '${reviewDocs.length} ocen',
                                  color: _kViolet,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          _topSkillCard(topSkill),

                          const SizedBox(height: 14),

                          _statusSection(
                            pending: pending,
                            active: active,
                            completed: completed,
                            rejected: rejected,
                          ),

                          const SizedBox(height: 14),

                          _weeklyActivitySection(myDocs),

                          const SizedBox(height: 14),

                          _skillsSection(topSkills),

                          const SizedBox(height: 14),

                          _insightsSection(
                          completed: completed,
                          pending: pending,
                          active: active,
                          reviews: reviewDocs.length,
                          topSkill: topSkill,
                        ),

                          const SizedBox(height: 14),

                          _historySection(myDocs),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _header() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 54, 20, 30),
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
              bottomLeft: Radius.circular(34),
              bottomRight: Radius.circular(34),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbPainter(_orbCtrl.value * 2 * math.pi),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Aktivnost',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.30),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aktivnost in analitika',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pregled sodelovanj, srečanj,\nocen in napredka uporabnika.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: _kText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: _kSub,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topSkillCard(String topSkill) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Najpogostejša veščina',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topSkill,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSection({
    required int pending,
    required int active,
    required int completed,
    required int rejected,
  }) {
    final total = pending + active + completed + rejected;

    return _section(
      title: 'Status sodelovanj',
      icon: Icons.pie_chart_rounded,
      child: Column(
          children: [
            _DonutChart(
              pending: pending,
              active: active,
              completed: completed,
              rejected: rejected,
            ),
            const SizedBox(height: 12),
            _progressRow('Čaka', pending, total, _kAmber),
            _progressRow('Aktivno', active, total, _kGreen),
            _progressRow('Zaključeno', completed, total, _kPrimary),
            _progressRow('Zavrnjeno', rejected, total, _kRed),
          ],
        ),
    );
  }

  Widget _progressRow(String label, int value, int total, Color color) {
    final percent = total == 0 ? 0.0 : value / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(height: 8, color: const Color(0xFFF1F5F9)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: (MediaQuery.of(context).size.width - 60) * percent,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillsSection(List<MapEntry<String, int>> topSkills) {
    return _section(
      title: 'Najpogostejše veščine',
      icon: Icons.bar_chart_rounded,
      child: topSkills.isEmpty
          ? const Text(
              'Ni dovolj podatkov za prikaz veščin.',
              style: TextStyle(color: _kSub, fontSize: 13),
            )
          : Column(
              children: topSkills.map((entry) {
                final maxValue = topSkills.first.value;
                final percent = maxValue == 0 ? 0.0 : entry.value / maxValue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Container(
                                height: 9,
                                color: const Color(0xFFF1F5F9),
                              ),
                              FractionallySizedBox(
                                widthFactor: percent,
                                child: Container(
                                  height: 9,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_kPrimary, _kViolet],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

 Widget _insightsSection({
  required int completed,
  required int pending,
  required int active,
  required int reviews,
  required String topSkill,
}) {
  final insights = <Map<String, dynamic>>[];

  if (completed == 0) {
    insights.add({
      'icon': Icons.flag_rounded,
      'color': _kAmber,
      'title': 'Začni prvo sodelovanje',
      'subtitle':
          'Poveži se z uporabniki in začni pridobivati izkušnje.',
    });
  }

  if (active > 0) {
    insights.add({
      'icon': Icons.trending_up_rounded,
      'color': _kGreen,
      'title': '$active aktivnih sodelovanj',
      'subtitle':
          'Trenutno si aktiven pri več učnih povezovanjih.',
    });
  }

  if (pending > 0) {
    insights.add({
      'icon': Icons.schedule_rounded,
      'color': _kAmber,
      'title': '$pending čakajočih zahtev',
      'subtitle':
          'Nekatera sodelovanja še čakajo na odgovor uporabnikov.',
    });
  }

  if (reviews == 0) {
    insights.add({
      'icon': Icons.star_border_rounded,
      'color': _kViolet,
      'title': 'Pridobi prve ocene',
      'subtitle':
          'Ocene povečajo zaupanje in kredibilnost profila.',
    });
  } else {
    insights.add({
      'icon': Icons.workspace_premium_rounded,
      'color': _kPrimary,
      'title': 'Največ aktivnosti pri veščini',
      'subtitle': topSkill,
    });
  }

  if (completed >= 5) {
    insights.add({
      'icon': Icons.emoji_events_rounded,
      'color': _kGreen,
      'title': 'Odličen napredek',
      'subtitle':
          'Uspešno si zaključil več sodelovanj in gradiš skupnost.',
    });
  }

  return _section(
    title: 'Analitični vpogledi',
    icon: Icons.insights_rounded,
    child: Column(
      children: insights.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item['color'].withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item['color'].withOpacity(0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item['color'].withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item['icon'],
                  color: item['color'],
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['subtitle'],
                      style: const TextStyle(
                        color: _kSub,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
Widget _weeklyActivitySection(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final now = DateTime.now();

  final days = List.generate(7, (index) {
    final date = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: 6 - index));

    return date;
  });

  final counts = List.generate(7, (_) => 0);

  for (final doc in docs) {
    final data = doc.data();

    DateTime? date;

    if (data['createdAt'] is Timestamp) {
      date = (data['createdAt'] as Timestamp).toDate();
    } else if (data['date'] is Timestamp) {
      date = (data['date'] as Timestamp).toDate();
    }

    if (date == null) continue;

    for (int i = 0; i < days.length; i++) {
      final d = days[i];

      final sameDay =
          date.year == d.year && date.month == d.month && date.day == d.day;

      if (sameDay) {
        counts[i]++;
      }
    }
  }

  final labels = days.map((d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'Pon';
      case DateTime.tuesday:
        return 'Tor';
      case DateTime.wednesday:
        return 'Sre';
      case DateTime.thursday:
        return 'Čet';
      case DateTime.friday:
        return 'Pet';
      case DateTime.saturday:
        return 'Sob';
      default:
        return 'Ned';
    }
  }).toList();

  return _section(
    title: 'Aktivnost v zadnjih 7 dneh',
    icon: Icons.show_chart_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prikaz števila sodelovanj po dnevih glede na ustvarjene interakcije.',
          style: TextStyle(
            color: _kSub,
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 150,
          child: _WeeklyBarChart(
            values: counts,
            labels: labels,
          ),
        ),
      ],
    ),
  );
}

  Widget _historySection(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return _section(
      title: 'Zgodovina sodelovanj',
      icon: Icons.history_rounded,
      child: docs.isEmpty
          ? const Text(
              'Zaenkrat še nimaš sodelovanj.',
              style: TextStyle(color: _kSub, fontSize: 13),
            )
          : Column(
              children: docs.map((doc) {
                final data = doc.data();
                final requesterId = (data['requesterId'] ?? '').toString();

                final otherName = requesterId == currentUid
                    ? (data['receiverName'] ?? 'Neznan uporabnik').toString()
                    : (data['requesterName'] ?? 'Neznan uporabnik').toString();

                final skill = (data['skillName'] ?? 'Ni veščine').toString();
                final status = (data['status'] ?? 'pending').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimary, _kViolet],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.handshake_rounded,
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
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$skill • ${_formatDate(data['date'])}',
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _statusColor(status).withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;

  const _WeeklyBarChart({
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 124,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final value = values[index];
          final percent = maxValue == 0 ? 0.05 : value / maxValue;
          final barHeight = 62 * percent.clamp(0.10, 1.0);
          final isTop = value == maxValue && value > 0;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: isTop ? _kPrimary : _kSub,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 18,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEBFF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      width: 18,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimary, _kViolet],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          if (value > 0)
                            BoxShadow(
                              color: _kPrimary.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  style: TextStyle(
                    color: isTop ? _kPrimary : _kSub,
                    fontSize: 10,
                    fontWeight: isTop ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final int pending;
  final int active;
  final int completed;
  final int rejected;

  const _DonutChart({
    required this.pending,
    required this.active,
    required this.completed,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final total = pending + active + completed + rejected;

    return SizedBox(
      height: 170,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _DonutPainter(
                pending: pending,
                active: active,
                completed: completed,
                rejected: rejected,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'skupaj',
                      style: TextStyle(
                        color: _kSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('Čaka', pending, _kAmber),
                _legendItem('Aktivno', active, _kGreen),
                _legendItem('Zaključeno', completed, _kPrimary),
                _legendItem('Zavrnjeno', rejected, _kRed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _kText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int pending;
  final int active;
  final int completed;
  final int rejected;

  _DonutPainter({
    required this.pending,
    required this.active,
    required this.completed,
    required this.rejected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = pending + active + completed + rejected;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (total == 0) return;

    final data = [
      (pending, _kAmber),
      (active, _kGreen),
      (completed, _kPrimary),
      (rejected, _kRed),
    ];

    double startAngle = -math.pi / 2;

    for (final item in data) {
      final value = item.$1;
      final color = item.$2;

      if (value == 0) continue;

      final sweepAngle = (value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.pending != pending ||
        oldDelegate.active != active ||
        oldDelegate.completed != completed ||
        oldDelegate.rejected != rejected;
  }
}

class _OrbPainter extends CustomPainter {
  final double t;

  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (0.10, 0.20, 80.0, const Color(0x35818CF8)),
      (0.85, 0.10, 58.0, const Color(0x307C3AED)),
      (0.60, 0.82, 65.0, const Color(0x284F46E5)),
      (0.92, 0.55, 44.0, const Color(0x22818CF8)),
      (0.25, 0.88, 50.0, const Color(0x307C3AED)),
    ];

    for (final orb in orbs) {
      final rx = orb.$1;
      final ry = orb.$2;
      final r = orb.$3;
      final color = orb.$4;

      final dx = math.sin(t + rx * 5) * 14;
      final dy = math.cos(t + ry * 4) * 11;
      final cx = size.width * rx + dx;
      final cy = size.height * ry + dy;

      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, Colors.transparent],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: r),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => oldDelegate.t != t;
}