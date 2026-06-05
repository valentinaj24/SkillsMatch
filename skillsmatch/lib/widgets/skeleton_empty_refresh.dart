import 'dart:math' as math;
import 'package:flutter/material.dart';

const _kP  = Color(0xFF4F46E5);
const _kPL = Color(0xFF818CF8);
const _kV  = Color(0xFF7C3AED);
const _kSf = Color(0xFFF5F5FF);
const _kBd = Color(0xFFE2E8F0);
const _kTx = Color(0xFF1E1B4B);
const _kTs = Color(0xFF6B7280);
const _kW  = Color(0xFFFFFFFF);
const _kBg = Color(0xFFF0F0FF);

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED LOADING SCREEN
// Prikazuje animirano mrežo ljudi med nalaganjem podatkov
// ═══════════════════════════════════════════════════════════════════════════════
class SkeletonScreen extends StatefulWidget {
  const SkeletonScreen({super.key});
  @override State<SkeletonScreen> createState() => _SkeletonScreenState();
}

class _SkeletonScreenState extends State<SkeletonScreen>
    with TickerProviderStateMixin {

  late AnimationController _netCtrl;   // mreža
  late AnimationController _textCtrl;  // besedilo
  late AnimationController _dotCtrl;   // pike za loading tekst

  late Animation<double> _textFade;

  final List<String> _messages = [
    'Iščemo mentorje...',
    'Nalagamo skupnost...',
    'Pripravljamo ujemanja...',
    'Skoraj pripravljeno...',
  ];
  int _msgIdx = 0;

  @override
  void initState() {
    super.initState();

    _netCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5))..repeat();

    _dotCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..repeat();

    _textCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textCtrl.forward();

    // Menjaj sporočilo vsake 2 sekundi
    _cycleMessages();
  }

  Future<void> _cycleMessages() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) break;
      await _textCtrl.reverse();
      if (!mounted) break;
      setState(() => _msgIdx = (_msgIdx + 1) % _messages.length);
      await _textCtrl.forward();
    }
  }

  @override
  void dispose() {
    _netCtrl.dispose(); _textCtrl.dispose(); _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [

        // ── Indigo header (isti kot pravi) ──────────────────────────────────
        Container(
          width: double.infinity,
          height: 158,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF3730A3),
                       Color(0xFF4F46E5), Color(0xFF818CF8)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(children: [
            // Orb ozadje
            AnimatedBuilder(
              animation: _netCtrl,
              builder: (_, __) => CustomPaint(
                size: Size(size.width, 158),
                painter: _HeaderOrbPainter(_netCtrl.value * 2 * math.pi))),
            // Vsebina headerja
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.22), width: 1.5)),
                    child: const Icon(Icons.groups_rounded,
                        color: Colors.white, size: 24)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(20)),
                    child: _DotLoader(ctrl: _dotCtrl)),
                ]),
                const SizedBox(height: 14),
                const Text('Skupnost', style: TextStyle(
                    color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.bold, letterSpacing: -0.4)),
                const SizedBox(height: 4),
                FadeTransition(
                  opacity: _textFade,
                  child: Text(_messages[_msgIdx],
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14))),
              ])))
          ])),

        // ── Animirana mreža ljudi ────────────────────────────────────────────
        Expanded(child: AnimatedBuilder(
          animation: _netCtrl,
          builder: (_, __) => CustomPaint(
            painter: _NetworkPainter(_netCtrl.value * 2 * math.pi),
            child: Container()),
        )),

        // ── Spodnji tekst ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(children: [
            _PulseRow(ctrl: _netCtrl),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _textFade,
              child: Text(_messages[_msgIdx],
                  style: const TextStyle(
                      color: _kTs, fontSize: 13,
                      fontWeight: FontWeight.w500))),
          ])),
      ]),
    );
  }
}

// ─── Header orb painter ───────────────────────────────────────────────────────
class _HeaderOrbPainter extends CustomPainter {
  final double t;
  _HeaderOrbPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final (rx, ry, r, c) in [
      (0.85, 0.2, 70.0,  const Color(0x30818CF8)),
      (0.15, 0.8, 55.0,  const Color(0x287C3AED)),
      (0.60, 0.5, 40.0,  const Color(0x204F46E5)),
    ]) {
      final dx = math.sin(t + rx * 4) * 12;
      final dy = math.cos(t + ry * 3) * 8;
      final o  = Offset(size.width * rx + dx, size.height * ry + dy);
      canvas.drawCircle(o, r, Paint()
        ..shader = RadialGradient(colors: [c, Colors.transparent])
            .createShader(Rect.fromCircle(center: o, radius: r)));
    }
  }
  @override bool shouldRepaint(_HeaderOrbPainter o) => o.t != t;
}

// ─── Network painter — glavna animacija ──────────────────────────────────────
class _NetworkPainter extends CustomPainter {
  final double t;
  _NetworkPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pozicije vozlišč (lebdijo)
    final nodes = [
      // Center
      Offset(w * 0.50, h * 0.42 + math.sin(t) * 8),
      // Okolica
      Offset(w * 0.22, h * 0.28 + math.sin(t + 1.0) * 6),
      Offset(w * 0.78, h * 0.28 + math.sin(t + 2.0) * 6),
      Offset(w * 0.15, h * 0.58 + math.sin(t + 0.5) * 7),
      Offset(w * 0.85, h * 0.58 + math.sin(t + 1.5) * 7),
      Offset(w * 0.35, h * 0.70 + math.sin(t + 2.5) * 5),
      Offset(w * 0.65, h * 0.70 + math.sin(t + 3.0) * 5),
      // Zunanji
      Offset(w * 0.08, h * 0.38 + math.sin(t + 0.8) * 5),
      Offset(w * 0.92, h * 0.38 + math.sin(t + 1.8) * 5),
    ];

    // Povezave med vozlišči
    final edges = [
      [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6],
      [1, 2], [1, 3], [1, 7],
      [2, 4], [2, 8],
      [3, 5], [3, 7],
      [4, 6], [4, 8],
      [5, 6],
    ];

    // Nariši linije
    final linePaint = Paint()
      ..color = _kPL.withOpacity(0.18)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (final e in edges) {
      canvas.drawLine(nodes[e[0]], nodes[e[1]], linePaint);
    }

    // Animirani pulzi po linijah
    final pulses = [
      [0, 1, 0.0],  [0, 2, 0.3],  [0, 3, 0.6],
      [0, 4, 0.9],  [1, 7, 0.2],  [2, 8, 0.7],
    ];

    for (final p in pulses) {
      final from = nodes[p[0].toInt()];
      final to   = nodes[p[1].toInt()];
      final offset = p[2];
      final progress = ((t / (2 * math.pi) + offset) % 1.0);

      final px = from.dx + (to.dx - from.dx) * progress;
      final py = from.dy + (to.dy - from.dy) * progress;

      // Svetleča pikica
      canvas.drawCircle(Offset(px, py), 4,
          Paint()..color = _kPL.withOpacity(0.8)
                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(Offset(px, py), 2,
          Paint()..color = Colors.white.withOpacity(0.9));
    }

    // Nariši vozlišča
    for (int i = 0; i < nodes.length; i++) {
      final isCenter = i == 0;
      final r = isCenter ? 30.0 : (i < 7 ? 22.0 : 18.0);
      final o = nodes[i];

      // Glow
      canvas.drawCircle(o, r + 6, Paint()
        ..color = _kP.withOpacity(isCenter ? 0.15 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

      // Ozadje
      canvas.drawCircle(o, r, Paint()
        ..shader = RadialGradient(colors: [
          isCenter ? const Color(0xFFEEF2FF) : const Color(0xFFF5F5FF),
          const Color(0xFFE8E8F8),
        ]).createShader(Rect.fromCircle(center: o, radius: r)));

      // Border (pulzira za center)
      final borderR = isCenter
          ? r + math.sin(t * 2) * 2
          : r.toDouble();
      canvas.drawCircle(o, borderR, Paint()
        ..color = isCenter
            ? _kP.withOpacity(0.5 + math.sin(t * 2) * 0.2)
            : _kPL.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCenter ? 2.0 : 1.2);

      // Ikona (person emoji kot text)
      final emoji = isCenter ? '👥' : '👤';
      final tp = TextPainter(
        text: TextSpan(text: emoji,
            style: TextStyle(fontSize: isCenter ? 18 : 13)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }

    // Ozadni gradient (subtilen)
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [_kP.withOpacity(0.03), Colors.transparent],
      ).createShader(Rect.fromCenter(
          center: Offset(w / 2, h / 2), width: w, height: h));
    canvas.drawCircle(Offset(w / 2, h * 0.42), w * 0.5, bgPaint);
  }

  @override bool shouldRepaint(_NetworkPainter o) => o.t != t;
}

// ─── Pulzirajoče pike (3 pike) ────────────────────────────────────────────────
class _DotLoader extends StatelessWidget {
  final AnimationController ctrl;
  const _DotLoader({required this.ctrl});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Nalaganje',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 2),
        ...List.generate(3, (i) {
          final delay = i * 0.33;
          final v = ((ctrl.value - delay) % 1.0 + 1.0) % 1.0;
          final opacity = math.sin(v * math.pi).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Opacity(
              opacity: 0.3 + opacity * 0.7,
              child: const Text('.', style: TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold))));
        }),
      ]);
    });
}

// ─── Pulzirajoča vrstica (spodaj) ────────────────────────────────────────────
class _PulseRow extends StatelessWidget {
  final AnimationController ctrl;
  const _PulseRow({required this.ctrl});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) {
      final t = ctrl.value * 2 * math.pi;
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ...List.generate(5, (i) {
          final scale = 0.6 + math.sin(t + i * 0.6) * 0.4;
          final opacity = 0.3 + math.sin(t + i * 0.6) * 0.4;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: scale.clamp(0.4, 1.0),
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kP.withOpacity(opacity.clamp(0.2, 0.8)),
                  boxShadow: [BoxShadow(
                      color: _kP.withOpacity(0.2),
                      blurRadius: 4)]))));
        }),
      ]);
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKELETON USER CARD — shimmer kartica (obdržana za morebitno uporabo)
// ═══════════════════════════════════════════════════════════════════════════════
class SkeletonUserCard extends StatelessWidget {
  const SkeletonUserCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    height: 120,
    decoration: BoxDecoration(
      color: _kW,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _kBd)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// EMPTY STATES (nespremenjeni)
// ═══════════════════════════════════════════════════════════════════════════════

class EmptySearchState extends StatefulWidget {
  final VoidCallback onClear;
  const EmptySearchState({super.key, required this.onClear});
  @override State<EmptySearchState> createState() => _EmptySearchStateState();
}

class _EmptySearchStateState extends State<EmptySearchState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _bounce = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade   = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _bounce,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: _kW,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kBd),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(children: [
            _SearchIllustration(),
            const SizedBox(height: 18),
            const Text('Ni rezultatov', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: _kTx)),
            const SizedBox(height: 6),
            const Text('Poskusi drugačno iskanje ali\npočisti aktiven filter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTs, fontSize: 13, height: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: widget.onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kP, _kV],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _kP.withOpacity(0.3),
                      blurRadius: 10, offset: const Offset(0, 4))]),
                child: const Text('Počisti filtre', style: TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.bold)))),
          ]),
        ),
      ),
    ),
  );
}

class _SearchIllustration extends StatefulWidget {
  @override State<_SearchIllustration> createState() =>
      _SearchIllustrationState();
}
class _SearchIllustrationState extends State<_SearchIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) {
      final t = _ctrl.value * 2 * math.pi;
      return SizedBox(width: 110, height: 110,
        child: Stack(alignment: Alignment.center, children: [
          Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(
                      color: _kPL.withOpacity(0.2), width: 1.5))),
          Transform.rotate(angle: math.sin(t * 0.5) * 0.15,
            child: Stack(alignment: Alignment.center, children: [
              Container(width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: _kSf, border: Border.all(color: _kP, width: 3))),
              Icon(Icons.search_rounded, color: _kP.withOpacity(0.5), size: 28),
            ])),
          Transform.translate(
            offset: Offset(24 + math.sin(t*0.5)*2, 24 + math.cos(t*0.5)*2),
            child: Container(width: 18, height: 5,
                decoration: BoxDecoration(color: _kP,
                    borderRadius: BorderRadius.circular(3)))),
          Transform.translate(
            offset: Offset(28, -28 + math.sin(t * 2) * 4),
            child: Container(width: 26, height: 26,
                decoration: BoxDecoration(color: _kP, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _kP.withOpacity(0.3),
                        blurRadius: 8)]),
                child: const Center(child: Text('?', style: TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.bold))))),
        ]));
    });
}

// ─── Empty community ──────────────────────────────────────────────────────────
class EmptyCommunityState extends StatefulWidget {
  const EmptyCommunityState({super.key});
  @override State<EmptyCommunityState> createState() =>
      _EmptyCommunityStateState();
}
class _EmptyCommunityStateState extends State<EmptyCommunityState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: AnimatedBuilder(animation: _ctrl, builder: (_, __) {
      final t = _ctrl.value * 2 * math.pi;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Transform.translate(
          offset: Offset(0, math.sin(t) * 6),
          child: Stack(alignment: Alignment.center, children: [
            Container(width: 110, height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: _kP.withOpacity(0.12 + math.sin(t) * 0.06),
                        blurRadius: 30, spreadRadius: 8)])),
            Container(width: 96, height: 96,
                decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight))),
            const Icon(Icons.people_outline_rounded, color: _kPL, size: 44),
            Transform.translate(
              offset: Offset(30, -30 + math.cos(t * 1.3) * 4),
              child: Container(width: 24, height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_kP, _kV],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 14))),
            Transform.translate(
              offset: Offset(-30, 20 + math.sin(t * 1.1) * 4),
              child: Icon(Icons.auto_awesome_rounded,
                  color: _kP.withOpacity(0.35 + math.sin(t*2) * 0.2),
                  size: 18)),
          ])),
        const SizedBox(height: 18),
        const Text('Skupnost je prazna', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: _kTx)),
        const SizedBox(height: 8),
        const Text('Ko uporabniki ustvarijo profil,\nbodo prikazani tukaj.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTs, fontSize: 13, height: 1.5)),
      ]);
    })));
}

// ─── Empty skills ─────────────────────────────────────────────────────────────
class EmptySkillsState extends StatelessWidget {
  const EmptySkillsState({super.key});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 600),
    curve: Curves.elasticOut,
    builder: (_, v, child) => Transform.scale(scale: v, child: child),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFEEF2FF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDD6FE))),
      child: Column(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kV, _kP],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _kP.withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 4))]),
            child: const Icon(Icons.lightbulb_rounded,
                color: Colors.white, size: 30))),
        const SizedBox(height: 12),
        const Text('Še nimate veščin', style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15, color: _kTx)),
        const SizedBox(height: 5),
        const Text('Dodajte veščine, ki jih ponujate\nali se jih želite naučiti.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTs, fontSize: 12, height: 1.5)),
      ]),
    ));
}