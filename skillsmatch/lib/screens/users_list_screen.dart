import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _kP = Color(0xFF4F46E5);
const _kPD = Color(0xFF312E81);
const _kPL = Color(0xFF818CF8);
const _kV = Color(0xFF7C3AED);
const _kC = Color(0xFF0891B2);
const _kG = Color(0xFF059669);
const _kA = Color(0xFFD97706);
const _kSf = Color(0xFFF5F5FF);
const _kW = Color(0xFFFFFFFF);
const _kBg = Color(0xFFF0F0FF);
const _kBd = Color(0xFFE2E8F0);
const _kTx = Color(0xFF1E1B4B);
const _kTs = Color(0xFF6B7280);

// ─── Orb painter ──────────────────────────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final (rx, ry, r, c) in [
      (0.10, 0.20, 80.0, const Color(0x38818CF8)),
      (0.87, 0.09, 60.0, const Color(0x327C3AED)),
      (0.60, 0.84, 68.0, const Color(0x2A4F46E5)),
      (0.90, 0.56, 44.0, const Color(0x20818CF8)),
      (0.24, 0.89, 52.0, const Color(0x2E7C3AED)),
    ]) {
      final dx = math.sin(t + rx * 5) * 14;
      final dy = math.cos(t + ry * 4) * 11;
      final o = Offset(size.width * rx + dx, size.height * ry + dy);
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c, Colors.transparent],
          ).createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter o) => o.t != t;
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (b) => LinearGradient(
        stops: const [0.0, 0.4, 0.6, 1.0],
        colors: const [
          Color(0xFFE8E8F0),
          Color(0xFFF5F5FF),
          Colors.white,
          Color(0xFFE8E8F0),
        ],
        transform: _SlideTx(_c.value),
      ).createShader(b),
      child: child,
    ),
    child: widget.child,
  );
}

class _SlideTx extends GradientTransform {
  final double v;
  const _SlideTx(this.v);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * 2 * (v - 0.5), 0, 0);
}

Widget _skBox({double? w, double h = 14, double r = 8}) => Container(
  width: w,
  height: h,
  decoration: BoxDecoration(
    color: const Color(0xFFE8E8F0),
    borderRadius: BorderRadius.circular(r),
  ),
);

// ─── Skeleton card ────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) => _Shimmer(
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kW,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBd),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8F0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 13, 13, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8F0),
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _skBox(w: 120, h: 13),
                              const SizedBox(height: 6),
                              _skBox(w: 70, h: 10),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _skBox(w: 34, h: 22, r: 8),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _skBox(h: 26, r: 8)),
                        const SizedBox(width: 6),
                        Expanded(child: _skBox(h: 26, r: 8)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _skBox(h: 10),
                    const SizedBox(height: 5),
                    _skBox(w: 180, h: 10),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _skBox(w: 58, h: 20, r: 14),
                        const SizedBox(width: 5),
                        _skBox(w: 48, h: 20, r: 14),
                        const SizedBox(width: 5),
                        _skBox(w: 38, h: 20, r: 14),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _skBox(w: 72, h: 10),
                        const Spacer(),
                        _skBox(w: 60, h: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Skeleton screen ──────────────────────────────────────────────────────────
class _SkeletonScreen extends StatelessWidget {
  const _SkeletonScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _Shimmer(
            child: Container(
              height: 158,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDDD8F8), Color(0xFFEAE8FB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          _Shimmer(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kW,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _kBd),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      4,
                      (_) => Column(
                        children: [
                          _skBox(w: 22, h: 14, r: 4),
                          const SizedBox(height: 4),
                          _skBox(w: 38, h: 9, r: 4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: List.generate(
                      8,
                      (i) => _skBox(w: 48.0 + i * 9, h: 26, r: 30),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Shimmer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  _skBox(h: 46, r: 14),
                  const SizedBox(height: 11),
                  Row(
                    children: List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _skBox(w: 68, h: 32, r: 30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(4, (_) => const _SkeletonCard()),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Empty search state ───────────────────────────────────────────────────────
class _EmptySearch extends StatefulWidget {
  final VoidCallback onClear;
  const _EmptySearch({required this.onClear});
  @override
  State<_EmptySearch> createState() => _EmptySearchState();
}

class _EmptySearchState extends State<_EmptySearch>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _kW,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Animirana ikona
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final t = _c.value * 2 * math.pi;
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kPL.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: math.sin(t * 0.5) * 0.12,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _kSf,
                                border: Border.all(color: _kP, width: 2.5),
                              ),
                            ),
                            Icon(
                              Icons.search_rounded,
                              color: _kP.withOpacity(0.45),
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(
                          22 + math.sin(t * 0.5) * 2,
                          22 + math.cos(t * 0.5) * 2,
                        ),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _kP,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _kP.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Ni rezultatov',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kTx,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Poskusi drugačno iskanje\nali počisti aktiven filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTs, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: widget.onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kP, _kV],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kP.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Počisti filtre',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Empty community state ────────────────────────────────────────────────────
class _EmptyCommunity extends StatefulWidget {
  const _EmptyCommunity();
  @override
  State<_EmptyCommunity> createState() => _EmptyCommunityState();
}

class _EmptyCommunityState extends State<_EmptyCommunity>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value * 2 * math.pi;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, math.sin(t) * 6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kP.withOpacity(0.12 + math.sin(t) * 0.06),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.people_outline_rounded,
                      color: _kPL,
                      size: 44,
                    ),
                    Transform.translate(
                      offset: Offset(30, -30 + math.cos(t * 1.3) * 4),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_kP, _kV],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(-30, 20 + math.sin(t * 1.1) * 4),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: _kP.withOpacity(0.35 + math.sin(t * 2) * 0.2),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Skupnost je prazna',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kTx,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ko uporabniki ustvarijo profil,\nbodo prikazani tukaj.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTs, fontSize: 13, height: 1.5),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _inits(Map<String, dynamic> d) {
  final a = (d['ime'] ?? '').toString();
  final b = (d['priimek'] ?? '').toString();
  return '${a.isNotEmpty ? a[0] : ''}${b.isNotEmpty ? b[0] : ''}'.toUpperCase();
}

String _heroTag(Map<String, dynamic> d) =>
    'usr-${d['uid'] ?? d['ime'] ?? ''}-${d['priimek'] ?? ''}';
Color _avatarColor(String s) {
  final cols = [
    _kP,
    _kV,
    _kC,
    _kG,
    _kA,
    const Color(0xFFDB2777),
    const Color(0xFF0284C7),
  ];
  return s.isNotEmpty ? cols[s.codeUnitAt(0) % cols.length] : _kP;
}

Map<String, dynamic> _privacy(Map<String, dynamic> data) {
  return Map<String, dynamic>.from(data['privacy'] ?? {});
}

bool _showLocation(Map<String, dynamic> data) {
  return _privacy(data)['showLocation'] ?? true;
}

bool _showDescription(Map<String, dynamic> data) {
  return _privacy(data)['showDescription'] ?? true;
}

bool _showAvailability(Map<String, dynamic> data) {
  return _privacy(data)['showAvailability'] ?? true;
}

bool _showSkills(Map<String, dynamic> data) {
  return _privacy(data)['showSkills'] ?? true;
}

String _role(List sk) {
  final t = sk.any((s) => s['tip'] == 'Lahko učim druge');
  final l = sk.any((s) => s['tip'] == 'Želim se naučiti');
  if (t && l) return 'Mentor & Učenec';
  if (t) return 'Mentor';
  if (l) return 'Učenec';
  return 'Član';
}

Color _roleC(String r) {
  if (r.contains('Mentor') && r.contains('Učenec')) return _kV;
  if (r.contains('Mentor')) return _kP;
  if (r.contains('Učenec')) return _kA;
  return _kTs;
}

List<Color> _roleGrad(String r) {
  if (r.contains('Mentor') && r.contains('Učenec')) return [_kP, _kV];
  if (r.contains('Mentor')) return [_kP, _kPL];
  if (r.contains('Učenec')) return [_kA, const Color(0xFFF59E0B)];
  return [_kTs, _kBd];
}

int _score(Map<String, dynamic> data, List sk, String q, String f) {
  int s = 42;
  final ql = q.toLowerCase();
  final loc = (data['lokacija'] ?? '').toString().toLowerCase();
  final st = sk
      .map((x) => '${x['naziv'] ?? ''} ${x['tip'] ?? ''}')
      .join(' ')
      .toLowerCase();
  if (ql.isNotEmpty && st.contains(ql)) s += 30;
  if (ql.isNotEmpty && loc.contains(ql)) s += 15;
  if (f == 'Mentorji' && sk.any((x) => x['tip'] == 'Lahko učim druge')) s += 15;
  if (f == 'Učenci' && sk.any((x) => x['tip'] == 'Želim se naučiti')) s += 15;
  if (f == 'Vikend' && data['razpolozljivost'] == 'Vikend') s += 15;
  return s.clamp(0, 100);
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Av extends StatelessWidget {
  final Map<String, dynamic> data;
  final double sz, rad;
  const _Av({required this.data, this.sz = 48, this.rad = 14});
  @override
  Widget build(BuildContext context) {
    final url = (data['photoUrl'] ?? '').toString();
    final ini = _inits(data);
    final col = _avatarColor(ini);
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [col, col.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(rad),
        boxShadow: [
          BoxShadow(
            color: col.withOpacity(0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(rad),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _txt(ini),
              ),
            )
          : _txt(ini),
    );
  }

  Widget _txt(String i) => Center(
    child: Text(
      i,
      style: TextStyle(
        color: Colors.white,
        fontSize: sz * 0.32,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _AnimatedCommunityIcon extends StatefulWidget {
  const _AnimatedCommunityIcon();

  @override
  State<_AnimatedCommunityIcon> createState() => _AnimatedCommunityIconState();
}

class _AnimatedCommunityIconState extends State<_AnimatedCommunityIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value * 2 * math.pi;

        return Transform.translate(
          offset: Offset(0, math.sin(t) * 4),
          child: Transform.scale(
            scale: 1 + math.sin(t) * 0.04,
            child: Image.asset(
              'assets/images/skupnost.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// USERS LIST SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});
  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'Vsi';
  String _activeSkill = '';
  bool _showX = false;

  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _searchCtrl.addListener(() {
      final h = _searchCtrl.text.isNotEmpty;
      if (h != _showX) setState(() => _showX = h);
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _query = _searchCtrl.text.trim());
  }

  void _clearAll() {
    _searchCtrl.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _query = '';
      _showX = false;
      _activeSkill = '';
      _filter = 'Vsi';
    });
  }

  void _clear() {
    _searchCtrl.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _query = '';
      _showX = false;
      _activeSkill = '';
    });
  }

  bool _matches(Map<String, dynamic> data, List sk) {
    final q = _query.toLowerCase();

    final visibleSkills = _showSkills(data) ? sk : [];

    final nm = '${data['ime'] ?? ''} ${data['priimek'] ?? ''}'.toLowerCase();

    final loc = _showLocation(data)
        ? (data['lokacija'] ?? '').toString().toLowerCase()
        : '';

    final des = _showDescription(data)
        ? (data['opis'] ?? '').toString().toLowerCase()
        : '';

    final st = visibleSkills
        .map(
          (s) =>
              '${s['naziv'] ?? ''} ${s['nivoZnanja'] ?? ''} ${s['tip'] ?? ''}',
        )
        .join(' ')
        .toLowerCase();

    final sOk =
        q.isEmpty ||
        nm.contains(q) ||
        loc.contains(q) ||
        des.contains(q) ||
        st.contains(q);

    final fOk =
        _filter == 'Vsi' ||
        (_filter == 'Mentorji' &&
            visibleSkills.any((s) => s['tip'] == 'Lahko učim druge')) ||
        (_filter == 'Učenci' &&
            visibleSkills.any((s) => s['tip'] == 'Želim se naučiti')) ||
        (_filter == 'Vikend' &&
            _showAvailability(data) &&
            data['razpolozljivost'] == 'Vikend');

    return sOk && fOk;
  }

  List<QueryDocumentSnapshot> _prepare(List<QueryDocumentSnapshot> docs) =>
      docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        return _matches(data, data['vescine'] as List? ?? []);
      }).toList()..sort((a, b) {
        final da = a.data() as Map<String, dynamic>;
        final db = b.data() as Map<String, dynamic>;
        return _score(
          db,
          db['vescine'] as List? ?? [],
          _query,
          _filter,
        ).compareTo(_score(da, da['vescine'] as List? ?? [], _query, _filter));
      });

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header(int total) => AnimatedBuilder(
    animation: _orbCtrl,
    builder: (_, __) {
      final t = _orbCtrl.value * 2 * math.pi;

      return Container(
        width: double.infinity,
        height: 315,
        padding: const EdgeInsets.fromLTRB(22, 50, 22, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
              Color(0xFF4F46E5),
              Color(0xFF818CF8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _OrbPainter(t))),

            Positioned(
              right: 0,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$total profilov',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 175,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                          width: 1.4,
                        ),
                      ),
                    ),

                    Transform.translate(
                      offset: Offset(math.sin(t) * 48, math.cos(t) * 16),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white.withOpacity(0.80),
                        size: 18,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(
                        math.cos(t * 1.2) * 58,
                        math.sin(t * 1.2) * 28,
                      ),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(
                        math.sin(t * 1.5) * -58,
                        math.cos(t * 1.5) * 25,
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white.withOpacity(0.70),
                        size: 15,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(
                        math.cos(t * 1.8) * -45,
                        math.sin(t * 1.8) * -34,
                      ),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Transform.translate(
                      offset: Offset(0, math.sin(t) * 6),
                      child: Transform.rotate(
                        angle: math.sin(t) * 0.035,
                        child: Image.asset(
                          'assets/images/skupnost.png',
                          width: 145,
                          height: 145,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                children: [
                  const Text(
                    'Skupnost',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 37,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Odkrij mentorje, učence in strokovnjake.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 14,
                      height: 1.35,
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

  // ── Community panel ────────────────────────────────────────────────────────
  Widget _communityPanel(List<QueryDocumentSnapshot> docs) {
    int mentorji = 0, ucenci = 0, vikend = 0;
    final Map<String, int> freq = {};
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final sk = data['vescine'] as List? ?? [];
      if (sk.any((s) => s['tip'] == 'Lahko učim druge')) mentorji++;
      if (sk.any((s) => s['tip'] == 'Želim se naučiti')) ucenci++;
      if (data['razpolozljivost'] == 'Vikend') vikend++;
      for (final s in sk) {
        final n = (s['naziv'] ?? '').toString().trim();
        if (n.isNotEmpty) freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    final topSkills =
        (freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .take(14)
            .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: _kW,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBd),
        boxShadow: [
          BoxShadow(
            color: _kP.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _statTile(
                  '${docs.length}',
                  'Skupaj',
                  Icons.groups_rounded,
                  _kP,
                ),
                _divider(),
                _statTile(
                  '$mentorji',
                  'Mentorji',
                  Icons.workspace_premium_rounded,
                  _kV,
                ),
                _divider(),
                _statTile('$ucenci', 'Učenci', Icons.school_rounded, _kC),
                _divider(),
                _statTile('$vikend', 'Vikend', Icons.weekend_rounded, _kG),
              ],
            ),
          ),
          if (topSkills.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kP, _kV],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.tag_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Priljubljene veščine',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kTx,
                      ),
                    ),
                  ),
                  if (_activeSkill.isNotEmpty)
                    GestureDetector(
                      onTap: _clear,
                      child: const Text(
                        'Počisti ×',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: topSkills.map((e) {
                  final name = e.key;
                  final cnt = e.value;
                  final sel = _activeSkill == name;
                  final allC = [
                    _kP,
                    _kV,
                    _kC,
                    _kG,
                    _kA,
                    const Color(0xFFDB2777),
                    const Color(0xFF0284C7),
                    const Color(0xFF0D9488),
                  ];
                  final col = allC[name.hashCode.abs() % allC.length];
                  final fs = cnt >= 3
                      ? 13.0
                      : cnt == 2
                      ? 12.0
                      : 11.0;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final nv = sel ? '' : name;
                      _searchCtrl.text = nv;
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        _activeSkill = nv;
                        _query = nv;
                        _showX = nv.isNotEmpty;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: cnt >= 3 ? 12 : 9,
                        vertical: cnt >= 3 ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? col : _kSf,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: sel ? col : col.withOpacity(0.28),
                          width: sel ? 0 : 1.2,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: col.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: fs,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: sel ? Colors.white : col,
                            ),
                          ),
                          if (cnt > 1) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Colors.white.withOpacity(0.25)
                                    : col.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '$cnt',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: sel ? Colors.white : col,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Dotakni se veščine za iskanje',
                style: TextStyle(fontSize: 11, color: _kTs.withOpacity(0.7)),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statTile(String val, String lbl, IconData icon, Color col) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, color: col, size: 16),
            const SizedBox(height: 4),
            Text(
              val,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: col,
              ),
            ),
            Text(
              lbl,
              style: const TextStyle(
                fontSize: 9,
                color: _kTs,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: _kBd,
  );

  // ── Search panel ───────────────────────────────────────────────────────────
  Widget _searchPanel(int count) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _kW,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBd, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _kP.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search_rounded, color: _kPL, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(fontSize: 14, color: _kTx),
                  decoration: const InputDecoration(
                    hintText: 'Išči ime, lokacijo, veščino...',
                    hintStyle: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              if (_showX)
                GestureDetector(
                  onTap: _clear,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.close_rounded, size: 16, color: _kTs),
                  ),
                ),
              GestureDetector(
                onTap: _search,
                child: Container(
                  margin: const EdgeInsets.all(5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kP, _kV],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _kP.withOpacity(0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Išči',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final (lbl, icon, col) in [
                ('Vsi', Icons.grid_view_rounded, _kP),
                ('Mentorji', Icons.workspace_premium_rounded, _kV),
                ('Učenci', Icons.school_rounded, _kC),
                ('Vikend', Icons.weekend_rounded, _kG),
              ]) ...[_filterChip(lbl, icon, col), const SizedBox(width: 7)],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '$count ${count == 1 ? 'rezultat' : 'rezultatov'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTs,
              ),
            ),
            if (_query.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kP.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '"$_query"',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kP,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (_query.isNotEmpty || _filter != 'Vsi')
              GestureDetector(
                onTap: _clearAll,
                child: const Text(
                  'Počisti vse',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _filterChip(String lbl, IconData icon, Color col) {
    final sel = _filter == lbl;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = lbl);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? col : _kW,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: sel ? col : _kBd, width: sel ? 0 : 1.2),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: col.withOpacity(0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: sel ? Colors.white : _kTs),
            const SizedBox(width: 5),
            Text(
              lbl,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : _kTs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── User card ──────────────────────────────────────────────────────────────
  Widget _userCard(
    BuildContext ctx,
    Map<String, dynamic> data,
    List sk,
    int sc,
    int idx,
  ) {
    final role = _role(sk);
    final grad = _roleGrad(role);
    final roleC = _roleC(role);
    final vis = sk.take(3).toList();
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) =>
                UserDetailScreen(data: data, skills: sk, score: sc, role: role),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 200 + idx * 40),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)),
            child: child,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _kW,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: grad,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 13, 13, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: _heroTag(data),
                              child: _Av(data: data, sz: 46, rad: 13),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${data['ime'] ?? ''} ${data['priimek'] ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _kTx,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: roleC,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        role,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: roleC,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: sc >= 70
                                    ? _kG.withOpacity(0.09)
                                    : sc >= 55
                                    ? _kA.withOpacity(0.09)
                                    : _kSf,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sc >= 70
                                      ? _kG.withOpacity(0.22)
                                      : sc >= 55
                                      ? _kA.withOpacity(0.22)
                                      : _kBd,
                                ),
                              ),
                              child: Text(
                                '$sc%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: sc >= 70
                                      ? _kG
                                      : sc >= 55
                                      ? _kA
                                      : _kTs,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _pill(
                              Icons.location_on_rounded,
                              _showLocation(data)
                                  ? (data['lokacija'] ?? '—')
                                  : 'Skrito',
                            ),
                            const SizedBox(width: 6),
                            _pill(
                              Icons.schedule_rounded,
                              _showAvailability(data)
                                  ? (data['razpolozljivost'] ?? '—')
                                  : 'Skrito',
                            ),
                          ],
                        ),
                        if (_showDescription(data) &&
                            (data['opis'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(
                            data['opis'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kTs,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (vis.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              ...vis.map((s) {
                                final ct = s['tip'] == 'Lahko učim druge';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ct
                                        ? _kP.withOpacity(0.07)
                                        : _kA.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: ct
                                          ? _kP.withOpacity(0.18)
                                          : _kA.withOpacity(0.18),
                                    ),
                                  ),
                                  child: Text(
                                    s['naziv'] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: ct ? _kP : _kA,
                                    ),
                                  ),
                                );
                              }),
                              if (sk.length > 3)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kSf,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _kBd),
                                  ),
                                  child: Text(
                                    '+${sk.length - 3}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _kTs,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _matchBadge(sc),
                            const Spacer(),
                            const Text(
                              'Poglej profil',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _kP,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: _kP,
                              size: 12,
                            ),
                          ],
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
  }

  Widget _pill(IconData icon, String text) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: _kSf,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: _kPL),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kTx,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _matchBadge(int sc) {
    final (txt, col) = sc >= 75
        ? ('Top match', _kG)
        : sc >= 55
        ? ('Dobro ujemanje', _kA)
        : ('Osnovno', _kTs);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 11, color: col),
        const SizedBox(width: 3),
        Text(
          txt,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: col,
          ),
        ),
      ],
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (ctx, snap) {
        // ── Loading — skeleton ──────────────────────────────────────────────
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SkeletonScreen();
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Napaka: ${snap.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        // ── Empty community ─────────────────────────────────────────────────
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Column(
            children: [
              _header(0),
              const Expanded(child: _EmptyCommunity()),
            ],
          );
        }

        final all = snap.data!.docs;
        final users = _prepare(all);

        // ── Pull to refresh + list ──────────────────────────────────────────
        return RefreshIndicator(
          color: _kP,
          backgroundColor: _kW,
          strokeWidth: 2.5,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _header(all.length)),
              SliverToBoxAdapter(child: _communityPanel(all)),
              SliverToBoxAdapter(child: _searchPanel(users.length)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (users.isEmpty)
                SliverToBoxAdapter(child: _EmptySearch(onClear: _clearAll))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final data = users[i].data() as Map<String, dynamic>;
                      final sk = data['vescine'] as List? ?? [];
                      final sc = _score(data, sk, _query, _filter);
                      return _userCard(ctx, data, sk, sc, i);
                    }, childCount: users.length),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final List skills;
  final int score;
  final String role;
  const UserDetailScreen({
    super.key,
    required this.data,
    required this.skills,
    required this.score,
    required this.role,
  });
  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbCtrl;
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

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final sk = widget.skills;
    final sc = widget.score;
    final r = widget.role;
    final showLocation = _showLocation(d);
    final showDescription = _showDescription(d);
    final showAvailability = _showAvailability(d);
    final showSkills = _showSkills(d);

    final visibleSkills = showSkills ? sk : [];
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _orbCtrl,
              builder: (_, __) => Container(
                padding: const EdgeInsets.fromLTRB(20, 54, 20, 28),
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OrbPainter(_orbCtrl.value * 2 * math.pi),
                      ),
                    ),
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.13),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Hero(
                          tag: _heroTag(d),
                          child: _Av(data: d, sz: 88, rad: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${d['ime'] ?? ''} ${d['priimek'] ?? ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _roleC(r).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _roleC(r).withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                r,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (showLocation &&
                                (d['lokacija'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white70,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      d['lokacija'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPD, _kP],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _kP.withOpacity(0.25),
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
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white70,
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Ujemanje profila',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$sc%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(
                                height: 5,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                height: 5,
                                width:
                                    (MediaQuery.of(context).size.width - 60) *
                                    (sc / 100),
                                decoration: BoxDecoration(
                                  color: sc >= 70
                                      ? _kG
                                      : sc >= 55
                                      ? _kA
                                      : Colors.white60,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          Icons.schedule_rounded,
                          'Razpoložljivost',
                          showAvailability
                              ? (d['razpolozljivost'] ?? '—')
                              : 'Skrito',
                          _kP,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoCard(
                          Icons.auto_awesome_rounded,
                          'Veščine',
                          showSkills ? '${visibleSkills.length}' : 'Skrito',
                          _kV,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _section(
                    'Opis',
                    Icons.description_outlined,
                    _kP,
                    child: Text(
                      !showDescription
                          ? 'Uporabnik je skril opis.'
                          : (d['opis'] ?? '').toString().isEmpty
                          ? 'Ni opisa.'
                          : d['opis'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kTs,
                        height: 1.5,
                      ),
                    ),
                  ),
                  _section(
                    'Veščine',
                    Icons.auto_awesome_rounded,
                    _kV,
                    child: !showSkills
                        ? const Text(
                            'Uporabnik je skril veščine.',
                            style: TextStyle(color: _kTs, fontSize: 13),
                          )
                        : visibleSkills.isEmpty
                        ? const Text(
                            'Ni dodanih veščin.',
                            style: TextStyle(color: _kTs, fontSize: 13),
                          )
                        : Column(
                            children: visibleSkills.asMap().entries.map((e) {
                              final s = e.value;
                              final ct = s['tip'] == 'Lahko učim druge';
                              final ac = ct ? _kP : _kA;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: _kW,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: _kBd),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: ct
                                                ? [_kP, _kV]
                                                : [
                                                    _kA,
                                                    const Color(0xFFF59E0B),
                                                  ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(13),
                                            bottomLeft: Radius.circular(13),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: ct
                                                  ? [_kP, _kV]
                                                  : [
                                                      _kA,
                                                      const Color(0xFFF59E0B),
                                                    ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            ct
                                                ? Icons
                                                      .volunteer_activism_rounded
                                                : Icons.school_rounded,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s['naziv'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: _kTx,
                                                ),
                                              ),
                                              Text(
                                                '${s['nivoZnanja']} • '
                                                '${ct ? "Učim" : "Učim se"}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: ac,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Sporočila bodo kmalu na voljo!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: _kP,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kP, _kV],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kP.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pošlji sporočilo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _infoCard(IconData icon, String lbl, String val, Color c) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: _kW,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBd),
      boxShadow: [
        BoxShadow(
          color: c.withOpacity(0.07),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(height: 6),
        Text(lbl, style: const TextStyle(fontSize: 11, color: _kTs)),
        const SizedBox(height: 3),
        Text(
          val,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: _kTx,
          ),
        ),
      ],
    ),
  );

  Widget _section(
    String title,
    IconData icon,
    Color c, {
    required Widget child,
  }) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kW,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _kBd),
      boxShadow: [
        BoxShadow(
          color: c.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c, c.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _kTx,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
