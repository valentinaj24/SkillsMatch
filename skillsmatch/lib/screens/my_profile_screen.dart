import 'dart:math' as math;
import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/service_locator.dart';

import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'activity_analytics_screen.dart';
import '../main.dart';
import '../accessibility/app_accessibility.dart';

// ─── Color System ──────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryDark = Color(0xFF312E81);
const _kPrimaryLight = Color(0xFF818CF8);
const _kViolet = Color(0xFF7C3AED);
const _kAmber = Color(0xFFD97706);
const _kGreen = Color(0xFF059669);

// Nivo barvni sistem
const _nivoColors = {
  'Začetnik': Color(0xFF10B981),
  'Srednji nivo': Color(0xFF3B82F6),
  'Napredni nivo': Color(0xFF8B5CF6),
  'Strokovnjak': Color(0xFFF59E0B),
};
const _nivoBg = {
  'Začetnik': Color(0xFFD1FAE5),
  'Srednji nivo': Color(0xFFDBEAFE),
  'Napredni nivo': Color(0xFFEDE9FE),
  'Strokovnjak': Color(0xFFFEF3C7),
};
const _nivoIcons = {
  'Začetnik': Icons.eco_rounded,
  'Srednji nivo': Icons.trending_up_rounded,
  'Napredni nivo': Icons.rocket_launch_rounded,
  'Strokovnjak': Icons.military_tech_rounded,
};

// ─── Orb Painter ──────────────────────────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final (rx, ry, r, color) in [
      (0.08, 0.18, 80.0, const Color(0x38818CF8)),
      (0.88, 0.08, 60.0, const Color(0x327C3AED)),
      (0.60, 0.85, 65.0, const Color(0x2A4F46E5)),
      (0.92, 0.55, 44.0, const Color(0x22818CF8)),
      (0.22, 0.88, 52.0, const Color(0x307C3AED)),
    ]) {
      final dx = math.sin(t + rx * 5) * 14;
      final dy = math.cos(t + ry * 4) * 11;
      canvas.drawCircle(
        Offset(size.width * rx + dx, size.height * ry + dy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [color, Colors.transparent])
              .createShader(
                Rect.fromCircle(
                  center: Offset(size.width * rx + dx, size.height * ry + dy),
                  radius: r,
                ),
              ),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter o) => o.t != t;
}

// ─── Mini Network Painter (za banner ilustracijo) ─────────────────────────────
class _NetworkMiniPainter extends CustomPainter {
  final double t;
  _NetworkMiniPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // Pozicije vozlišč z rahlo animacijo
    final nodes = [
      Offset(cx + math.sin(t) * 3, cy + math.cos(t) * 3),
      Offset(cx - 38 + math.sin(t + 1) * 4, cy - 34 + math.cos(t + 2) * 3),
      Offset(cx + 36 + math.sin(t + 2) * 3, cy - 28 + math.cos(t + 1) * 4),
      Offset(cx - 30 + math.sin(t + 3) * 4, cy + 36 + math.cos(t + 0.5) * 3),
      Offset(cx + 32 + math.sin(t + 0.5) * 3, cy + 38 + math.cos(t + 3) * 4),
    ];

    // Linije
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < nodes.length; i++) {
      canvas.drawLine(nodes[0], nodes[i], linePaint);
    }
    canvas.drawLine(nodes[1], nodes[2], linePaint);
    canvas.drawLine(nodes[3], nodes[4], linePaint);

    // Animiran pulz
    final pulse = (math.sin(t * 1.6) + 1) / 2;
    final pp = nodes[0] + (nodes[2] - nodes[0]) * pulse;
    canvas.drawCircle(
      pp,
      4,
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Vozlišča
    void drawNode(Offset o, double r, bool main) {
      if (main) {
        canvas.drawCircle(
          o,
          r + 4,
          Paint()..color = Colors.white.withOpacity(0.12),
        );
      }
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(main ? 0.95 : 0.6),
              Colors.white.withOpacity(main ? 0.5 : 0.2),
            ],
          ).createShader(Rect.fromCircle(center: o, radius: r)),
      );

      if (main) {
        final tp = TextPainter(
          text: const TextSpan(text: '👤', style: TextStyle(fontSize: 12)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
      }
    }

    drawNode(nodes[0], 18, true);
    for (int i = 1; i < nodes.length; i++) {
      drawNode(nodes[i], 12, false);
    }
  }

  @override
  bool shouldRepaint(_NetworkMiniPainter o) => o.t != t;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class MyProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSkupnost;
  const MyProfileScreen({super.key, this.onNavigateToSkupnost});
  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Logout dialog ──────────────────────────────────────────────────────────
  Future<void> _logout(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 30,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Odjava',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.kText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ali se želite odjaviti iz aplikacije?',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.kTextSub, fontSize: 14),
              ),
              SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(c, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.kTextSub,
                        side: BorderSide(color: context.kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('Prekliči'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(c, true),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text(
                        'Odjava',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      await ServiceLocator.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
void _openSettingsSheet(BuildContext ctx) {
  showGeneralDialog(
    context: ctx,
    barrierDismissible: true,
    barrierLabel: 'Nastavitve',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.86,
            height: double.infinity,
            decoration: BoxDecoration(
              color: context.kBg,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(8, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPrimaryDark, _kPrimary, _kViolet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.20),
                            ),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nastavitve',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Uredi videz in dostopnost',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeModeNotifier,
                    builder: (context, mode, _) {
                      final isDark = mode == ThemeMode.dark;

                      return _settingsOptionCard(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: 'Temni način',
                        subtitle: 'Preklopi med svetlo in temno temo',
                        color: _kPrimary,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                          ),
                          child: _miniToggle(
                            value: isDark,
                            activeColor: _kPrimary,
                            onTap: () {
                              themeModeNotifier.value =
                                  isDark ? ThemeMode.light : ThemeMode.dark;
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  AnimatedBuilder(
                    animation: AppAccessibility.instance,
                    builder: (context, _) {
                      final senior = AppAccessibility.instance.seniorMode;

                      return _settingsOptionCard(
                        icon: Icons.format_size_rounded,
                        title: 'Dostopnost',
                        subtitle: 'Povečana velikost besedila',
                        color: _kViolet,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                          ),
                          child: _miniToggle(
                            value: senior,
                            activeColor: _kViolet,
                            onTap: () {
                              AppAccessibility.instance.setSeniorMode(!senior);
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _logout(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Odjava',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}
Widget _settingsOptionCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.kCardBg,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: context.kBorder),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.10),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Row(
        mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: color, size: 27),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.kTextSub,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: child,
        ),
      ],
    ),
  );
}
Widget _miniToggle({
  required bool value,
  required Color activeColor,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? activeColor : context.kBorder,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header(BuildContext ctx, Map<String, dynamic> data) {
    final photoUrl = (data['photoUrl'] ?? '').toString();
    final ime = data['ime'] ?? '';
    final priimek = data['priimek'] ?? '';
    final lokacija = data['lokacija'] ?? 'Ni lokacije';
    final initials =
        '${ime.isNotEmpty ? ime[0] : ''}${priimek.isNotEmpty ? priimek[0] : ''}'
            .toUpperCase();

    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
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
                // Top bar — logout
              Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openSettingsSheet(ctx),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.13),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Avatar
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.white24, Colors.white12],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      // Camera button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kPrimary, _kViolet],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimary.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Ime
                Text(
                  '$ime $priimek',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),
                _profileVerifiedBadge(
                  ServiceLocator.auth.currentUser?.uid ?? '',
                  data,
                ),

                const SizedBox(height: 10),

                // Lokacija pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white70,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        lokacija,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _profileVerifiedBadge(String userId, Map<String, dynamic> userData) {
  if (userId.isEmpty) return const SizedBox.shrink();

  return StreamBuilder<QuerySnapshot>(
    stream: ServiceLocator.firestore
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: userId)
        .snapshots(),
    builder: (context, snapshot) {
      final docs = snapshot.data?.docs ?? [];

      if (docs.isEmpty) return const SizedBox.shrink();

      double total = 0;
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['rating'] ?? 0).toDouble();
      }

      final averageRating = total / docs.length;
      final skills = userData['vescine'] as List? ?? [];

      final isMentor = skills.any(
        (s) => s['tip'] == 'Lahko učim druge',
      );

      final isVerified = isMentor && averageRating >= 4.5 && docs.length >= 3;
            if (!isVerified) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF14B8A6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Verified',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    },
  );
}

  // ── Edit button ────────────────────────────────────────────────────────────
  Widget _editBtn(BuildContext ctx) => GestureDetector(
    onTap: () => Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    ),
    child: Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, _kViolet],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.38),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Uredi profil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _analyticsCard(BuildContext ctx) => GestureDetector(
  onTap: () {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const ActivityAnalyticsScreen()),
    );
  },
  child: Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
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
          color: _kPrimary.withOpacity(0.25),
          blurRadius: 16,
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
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktivnost in analitika',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pregled zgodovine sodelovanj, srečanj in napredka.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white70,
          size: 16,
        ),
      ],
    ),
  ),
);

  // ── Info card ──────────────────────────────────────────────────────────────
  Widget _infoCard(IconData icon, String title, String text, Color accent) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.kCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.kText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.kTextSub,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _sectionHdr(String title, IconData icon) => Row(
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
      SizedBox(width: 10),
      Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: context.kText,
        ),
      ),
    ],
  );

  // ── Skill card ─────────────────────────────────────────────────────────────
  Widget _skillCard(dynamic skill, int index) {
    final canTeach = skill['tip'] == 'Lahko učim druge';
    final nivo = skill['nivoZnanja'] as String? ?? 'Začetnik';
    final mColor = _nivoColors[nivo] ?? _kPrimary;
    final mBg = _nivoBg[nivo] ?? context.kSurface;
    final mIcon = _nivoIcons[nivo] ?? Icons.star_rounded;
    final accent = canTeach ? _kPrimary : _kAmber;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.kCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.kBorder),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Colored left bar
            Container(
              width: 5,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canTeach
                      ? [_kPrimary, _kViolet]
                      : [_kAmber, const Color(0xFFF59E0B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canTeach
                      ? [_kPrimary, _kViolet]
                      : [_kAmber, const Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                canTeach
                    ? Icons.volunteer_activism_rounded
                    : Icons.school_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill['naziv'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.kText,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Nivo badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: mBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(mIcon, size: 10, color: mColor),
                            const SizedBox(width: 3),
                            Text(
                              nivo,
                              style: TextStyle(
                                fontSize: 10,
                                color: mColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Tip badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          canTeach ? 'Učim' : 'Učim se',
                          style: TextStyle(
                            fontSize: 10,
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // ── Empty skills ───────────────────────────────────────────────────────────
  Widget _emptySkills() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF5F3FF), Color(0xFFEEF2FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDD6FE)),
    ),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kViolet, _kPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lightbulb_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Ni dodanih veščin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: context.kText,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Dodajte veščine v zavihku Uredi.',
          style: TextStyle(color: context.kTextSub, fontSize: 13),
        ),
      ],
    ),
  );

  // ── Stat item ──────────────────────────────────────────────────────────────
  Widget _statItem(String value, String label, IconData icon) => Column(
    children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ],
  );

  Widget _vDivider() =>
      Container(height: 36, width: 1, color: Colors.white.withOpacity(0.18));

  // ── Profile completeness card ───────────────────────────────────────────────
  Widget _completenessCard(Map<String, dynamic> data, int skillCount) {
    final checks = [
      (
        'Ime in priimek',
        (data['ime'] ?? '').toString().isNotEmpty &&
            (data['priimek'] ?? '').toString().isNotEmpty,
        Icons.badge_outlined,
      ),
      (
        'Lokacija',
        (data['lokacija'] ?? '').toString().isNotEmpty,
        Icons.location_on_outlined,
      ),
      (
        'Opis',
        (data['opis'] ?? '').toString().isNotEmpty,
        Icons.description_outlined,
      ),
      ('Veščine', skillCount > 0, Icons.auto_awesome_outlined),
    ];
    final done = checks.where((c) => c.$2).length;
    final total = checks.length;
    final pct = done / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: pct == 1.0
                      ? const Color(0xFF10B981).withOpacity(0.12)
                      : _kPrimary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  pct == 1.0
                      ? Icons.verified_rounded
                      : Icons.person_search_rounded,
                  color: pct == 1.0 ? const Color(0xFF10B981) : _kPrimary,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popolnost profila',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.kText,
                      ),
                    ),
                    Text(
                      '$done od $total korakov zaključenih',
                      style: TextStyle(fontSize: 12, color: context.kTextSub),
                    ),
                  ],
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: pct == 1.0 ? const Color(0xFF10B981) : _kPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 7, color: context.kBorder.withOpacity(0.3)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 7,
                  width: (MediaQuery.of(context).size.width - 28 - 36) * pct,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: pct == 1.0
                          ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                          : [_kPrimary, _kViolet],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Check items
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: checks.map((c) {
              final (label, done, icon) = c;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: done ? Color(0xFF6EE7B7) : context.kBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      done ? Icons.check_circle_rounded : icon,
                      size: 14,
                      color: done ? Color(0xFF10B981) : context.kTextSub,
                    ),
                    SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: done ? Color(0xFF059669) : context.kTextSub,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Illustrated banner ─────────────────────────────────────────────────────
Widget _illustratedBanner(BuildContext ctx) {
  return Container(
    width: double.infinity,
    height: 160,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: _kPrimary.withOpacity(0.3),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -28,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kViolet.withOpacity(0.18),
              ),
            ),
          ),

          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: _networkIllustration(),
          ),

          Positioned(
            left: 20,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Skills Match',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Poveži se z\ndrugo skupnostjo!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => widget.onNavigateToSkupnost?.call(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Odkrij',
                          style: TextStyle(
                            color: _kPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: _kPrimary,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _networkIllustration() {
    return SizedBox(
      width: 130,
      height: 160,
      child: AnimatedBuilder(
        animation: _orbCtrl,
        builder: (_, __) {
          final t = _orbCtrl.value * 2 * math.pi;
          return CustomPaint(painter: _NetworkMiniPainter(t));
        },
      ),
    );
  }

  // ── Tips sekcija ───────────────────────────────────────────────────────────
  Widget _tipsSection() {
    final isDark = context.isDark;

    final tips = [
      (
        Icons.tips_and_updates_rounded,
        'Dopolnite profil',
        'Popoln profil dobi 3× več ogleda.',
        const Color(0xFF4F46E5),
        isDark ? const Color(0xFF1A1933) : const Color(0xFFEEF2FF),
      ),
      (
        Icons.star_rounded,
        'Dodajte veščine',
        'Več veščin = več priložnosti za povezovanje.',
        const Color(0xFFD97706),
        isDark ? const Color(0xFF1F1A0F) : const Color(0xFFFFFBEB),
      ),
      (
        Icons.handshake_rounded,
        'Povežite se',
        'Poiščite mentorje in učence v skupnosti.',
        const Color(0xFF059669),
        isDark ? const Color(0xFF0C1F18) : const Color(0xFFECFDF5),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHdr('Nasveti za vas', Icons.lightbulb_rounded),
        const SizedBox(height: 12),
        ...tips.map((t) {
          final (icon, title, sub, color, bg) = t;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(isDark ? 0.35 : 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.kTextSub,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Empty profile ──────────────────────────────────────────────────────────
  Widget _emptyProfile() => Scaffold(
  backgroundColor: context.kBg,
  body: Stack(
    children: [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.kCardBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Profil še ni ustvarjen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.kText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Najprej izpolnite obrazec za ustvarjanje profila.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: context.kTextSub, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);

  Widget _reviewsSummaryCard(String userId, Map<String, dynamic> userData) {
  return StreamBuilder<QuerySnapshot>(
    stream: ServiceLocator.firestore
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: userId)
        .snapshots(),
    builder: (context, snapshot) {
      final docs = snapshot.data?.docs ?? [];

      double total = 0;
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['rating'] ?? 0).toDouble();
      }

      final reviewCount = docs.length;
      final averageRating = reviewCount == 0 ? 0.0 : total / reviewCount;

      final skills = userData['vescine'] as List? ?? [];

      final isMentor = skills.any(
        (s) => s['tip'] == 'Lahko učim druge',
      );

      final isVerifiedMentor = isMentor && averageRating >= 4.5 && reviewCount >= 3;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.kBorder),
          boxShadow: [
            BoxShadow(
              color: _kAmber.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHdr('Moje ocene', Icons.star_rounded),
            const SizedBox(height: 14),

            Row(
              children: [
                Icon(Icons.star_rounded, color: _kAmber, size: 24),
                SizedBox(width: 8),
                Text(
                  reviewCount == 0
                      ? 'Še nimaš ocen'
                      : '${averageRating.toStringAsFixed(1)} / 5.0',
                  style: TextStyle(
                    color: context.kText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  '($reviewCount)',
                  style: TextStyle(
                    color: context.kTextSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (isVerifiedMentor) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kGreen.withOpacity(0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: _kGreen, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Verified Mentor',
                      style: TextStyle(
                        color: _kGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (docs.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...docs.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final rating = data['rating'] ?? 0;
                final comment = (data['comment'] ?? '').toString();
                final reviewerId = (data['reviewerId'] ?? '').toString();

                return FutureBuilder<DocumentSnapshot>(
                  future: ServiceLocator.firestore
                      .collection('users')
                      .doc(reviewerId)
                      .get(),
                  builder: (context, userSnap) {
                    final userData = userSnap.data?.data() as Map<String, dynamic>?;

                    final reviewerName = userData == null
                        ? 'Neznan uporabnik'
                        : '${userData['ime'] ?? ''} ${userData['priimek'] ?? ''}'.trim();

                    return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName.isEmpty ? 'Neznan uporabnik' : reviewerName,
                            style: TextStyle(
                              color: context.kText,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: _kAmber,
                            size: 16,
                          );
                        }),
                      ),
                      if (comment.isNotEmpty) ...[
                        SizedBox(height: 6),
                        Text(
                          comment,
                          style: TextStyle(
                            color: context.kTextSub,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                             );
            },
          );
        }),
            ],
          ],
        ),
      );
    },
  );
}



  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final uid = ServiceLocator.auth.currentUser?.uid;
    if (uid == null) return _emptyProfile();

    return Scaffold(
      backgroundColor: context.kBg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: ServiceLocator.firestore
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }
          if (!snap.hasData || !snap.data!.exists) return _emptyProfile();

          final data = snap.data!.data() as Map<String, dynamic>;
          final vescine = data['vescine'] as List<dynamic>? ?? [];
          final opis = (data['opis'] ?? '').toString();
          final razp = data['razpolozljivost'] ?? 'Ni podatka.';

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    _header(ctx, data),

                    // ── Content ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Edit button ──────────────────────────────────────
                          _editBtn(ctx),
                          const SizedBox(height: 16),

                          // ── Stats row ────────────────────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPrimary.withOpacity(0.28),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem(
                                  '${vescine.length}',
                                  'Veščine',
                                  Icons.auto_awesome_rounded,
                                ),
                                _vDivider(),
                                _statItem(
                                  vescine
                                      .where(
                                        (s) => s['tip'] == 'Lahko učim druge',
                                      )
                                      .length
                                      .toString(),
                                  'Učim',
                                  Icons.volunteer_activism_rounded,
                                ),
                                _vDivider(),
                                _statItem(
                                  vescine
                                      .where(
                                        (s) => s['tip'] == 'Želim se naučiti',
                                      )
                                      .length
                                      .toString(),
                                  'Učim se',
                                  Icons.school_rounded,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Profil completeness ──────────────────────────────
                          _completenessCard(data, vescine.length),

                          const SizedBox(height: 14),
                          _reviewsSummaryCard(uid, data),

                          

                          const SizedBox(height: 14),

                          // ── Info kartice ─────────────────────────────────────
                          _infoCard(
                            Icons.description_outlined,
                            'Opis',
                            opis.isEmpty ? 'Ni opisa.' : opis,
                            _kPrimary,
                          ),
                          _infoCard(
                            Icons.schedule_outlined,
                            'Razpoložljivost',
                            razp,
                            _kViolet,
                          ),
                          

                          const SizedBox(height: 6),

                          // ── Veščine section ───────────────────────────────────
                          _sectionHdr(
                            'Moje veščine',
                            Icons.auto_awesome_rounded,
                          ),
                          const SizedBox(height: 12),

                          if (vescine.isEmpty)
                            _emptySkills()
                          else
                            ...vescine.asMap().entries.map(
                              (e) => _skillCard(e.value, e.key),
                            ),

                            const SizedBox(height: 14),
                          _analyticsCard(ctx),

                          const SizedBox(height: 10),



                          // ── Illustrated banner ────────────────────────────────
                          _illustratedBanner(ctx),

                          const SizedBox(height: 14),

                          // ── Nasveti sekcija ───────────────────────────────────
                          _tipsSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}