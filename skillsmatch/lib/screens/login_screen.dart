import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';

// ─── Color System ─────────────────────────────────────────────────────────────
const _kPrimary      = Color(0xFF4F46E5);
const _kPrimaryDark  = Color(0xFF312E81);
const _kPrimaryLight = Color(0xFF818CF8);
const _kViolet       = Color(0xFF7C3AED);
const _kSurface      = Color(0xFFF5F5FF);
const _kCardBg       = Color(0xFFFFFFFF);
const _kBg           = Color(0xFFF0F0FF);
const _kBorder       = Color(0xFFCBD5E1);
const _kText         = Color(0xFF1E1B4B);
const _kTextSub      = Color(0xFF6B7280);

// ─── Orb Painter ─────────────────────────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (0.10, 0.20, 80.0, const Color(0x35818CF8)),
      (0.85, 0.10, 60.0, const Color(0x307C3AED)),
      (0.60, 0.82, 68.0, const Color(0x284F46E5)),
      (0.92, 0.58, 46.0, const Color(0x22818CF8)),
      (0.28, 0.88, 52.0, const Color(0x307C3AED)),
    ];
    for (final (rx, ry, r, color) in orbs) {
      final dx = math.sin(t + rx * 5) * 14;
      final dy = math.cos(t + ry * 4) * 11;
      final cx = size.width  * rx + dx;
      final cy = size.height * ry + dy;
      final paint = Paint()
        ..shader = RadialGradient(colors: [color, Colors.transparent])
            .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }
  @override
  bool shouldRepaint(_OrbPainter o) => o.t != t;
}

// ─── Skills Match Illustration Painter ───────────────────────────────────────
// Prikazuje abstraktno sceno: trije avatarji povezani z linijami (network/skupnost)
class _IllustrationPainter extends CustomPainter {
  final double t; // animacijski čas 0..2π
  _IllustrationPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Ozadje krog ──────────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.42, bgPaint);

    // ── Pozicije avatarjev (rahlo animirane) ─────────────────────────────────
    final c  = Offset(w * 0.50, h * 0.50 + math.sin(t) * 3);
    final l  = Offset(w * 0.18, h * 0.62 + math.sin(t + 1.0) * 4);
    final r  = Offset(w * 0.82, h * 0.62 + math.sin(t + 2.0) * 4);
    final tl = Offset(w * 0.28, h * 0.22 + math.sin(t + 0.5) * 3);
    final tr = Offset(w * 0.72, h * 0.22 + math.sin(t + 1.5) * 3);

    // ── Linije (connections) ─────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final pair in [(c, l), (c, r), (c, tl), (c, tr), (l, tl), (r, tr)]) {
      canvas.drawLine(pair.$1, pair.$2, linePaint);
    }

    // Animirani pulz po liniji c→tl
    final pulse = (math.sin(t * 1.5) + 1) / 2;
    final px = c.dx + (tl.dx - c.dx) * pulse;
    final py = c.dy + (tl.dy - c.dy) * pulse;
    final pulsePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(px, py), 4, pulsePaint);

    // Drugi pulz c→r
    final pulse2 = (math.sin(t * 1.2 + math.pi) + 1) / 2;
    final px2 = c.dx + (r.dx - c.dx) * pulse2;
    final py2 = c.dy + (r.dy - c.dy) * pulse2;
    canvas.drawCircle(Offset(px2, py2), 3.5, pulsePaint);

    // ── Avatarji ─────────────────────────────────────────────────────────────
    void drawAvatar(Offset pos, double radius, Color col, IconData? icon,
        {bool isMain = false}) {
      // Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos + const Offset(0, 4), radius, shadowPaint);

      // Fill
      final fillPaint = Paint()..color = col;
      canvas.drawCircle(pos, radius, fillPaint);

      // Ring
      final ringPaint = Paint()
        ..color = Colors.white.withOpacity(isMain ? 0.8 : 0.5)
        ..strokeWidth = isMain ? 2.5 : 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, radius + 2, ringPaint);

      // Ikona — narišemo z TextPainter (Unicode)
      final emoji = icon == null ? '👤' : '';
      if (isMain) {
        // Centralna ikona = ključavnica
        _drawText(canvas, pos, '🔐', radius * 0.9);
      } else {
        _drawText(canvas, pos, '👤', radius * 0.75);
      }
    }

    // Barve avatarjev
    drawAvatar(c,  28, _kPrimary,  null, isMain: true);
    drawAvatar(l,  20, _kViolet,   null);
    drawAvatar(r,  20, const Color(0xFF0891B2), null);
    drawAvatar(tl, 18, const Color(0xFF059669), null);
    drawAvatar(tr, 18, const Color(0xFFD97706), null);

    // ── Floating badges ───────────────────────────────────────────────────────
    _drawBadge(canvas, Offset(w * 0.06, h * 0.38 + math.sin(t + 0.3) * 5),
        '✓ Varno', const Color(0xFF10B981));
    _drawBadge(canvas, Offset(w * 0.68, h * 0.10 + math.sin(t + 1.8) * 5),
        '⚡ Hitro', const Color(0xFFF59E0B));
    _drawBadge(canvas, Offset(w * 0.60, h * 0.88 + math.sin(t + 0.9) * 4),
        '🌐 Skupnost', const Color(0xFF818CF8));
  }

  void _drawText(Canvas canvas, Offset center, String text, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawBadge(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
              color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();

    final pad   = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final rect  = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: pos,
          width:  tp.width + pad.horizontal + 2,
          height: tp.height + pad.vertical),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, Paint()..color = color.withOpacity(0.9));
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_IllustrationPainter o) => o.t != t;
}

// ─── Login Screen ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading    = false;
  bool showPassword = false;

  final _emailFN    = FocusNode();
  final _passwordFN = FocusNode();

  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _illuCtrl; // ilustracija

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _btnScale;

  late List<Animation<double>> _fFade;
  late List<Animation<Offset>> _fSlide;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.07), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _fFade  = [];
    _fSlide = [];
    for (int i = 0; i < 4; i++) {
      final s = (0.12 + i * 0.12).clamp(0.0, 0.9);
      final e = (s + 0.30).clamp(0.0, 1.0);
      _fFade.add(Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _entryCtrl,
              curve: Interval(s, e, curve: Curves.easeOut))));
      _fSlide.add(Tween<Offset>(
          begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryCtrl,
              curve: Interval(s, e, curve: Curves.easeOut))));
    }

    _orbCtrl  = AnimationController(
        vsync: this, duration: const Duration(seconds: 9))..repeat();
    _illuCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))..repeat();

    _btnCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
    _emailFN.addListener(()    => setState(() {}));
    _passwordFN.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    _btnCtrl.dispose();
    _illuCtrl.dispose();
    emailController.dispose();
    passwordController.dispose();
    _emailFN.dispose();
    _passwordFN.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email    = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Vnesite email in geslo.', Colors.redAccent); return;
    }
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      if (!mounted) return;
      _snack('Prijava uspešna.', _kPrimary);
    } on FirebaseAuthException catch (e) {
      String msg = 'Prijava ni uspela.';
      if (e.code == 'invalid-email')                         msg = 'Email naslov ni pravilen.';
      else if (e.code == 'user-not-found')                   msg = 'Uporabnik s tem emailom ne obstaja.';
      else if (e.code == 'wrong-password' ||
               e.code == 'invalid-credential')               msg = 'Email ali geslo ni pravilno.';
      _snack(msg, Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  InputDecoration _deco(String hint, IconData icon, FocusNode fn,
      {Widget? suffix}) {
    final focused = fn.hasFocus;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Icon(icon,
          color: focused ? _kPrimary : const Color(0xFFA5B4FC), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: focused ? const Color(0xFFF0F0FF) : _kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder, width: 1.2)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: _kText)));

  Widget _anim(int i, Widget child) => FadeTransition(
      opacity: _fFade[i],
      child: SlideTransition(position: _fSlide[i], child: child));

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header() => AnimatedBuilder(
    animation: _orbCtrl,
    builder: (_, __) => Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 62, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF3730A3),
                   Color(0xFF4F46E5), Color(0xFF818CF8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(
            painter: _OrbPainter(_orbCtrl.value * 2 * math.pi))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Ikona (statična, brez animacije)
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.32), width: 1.5)),
            child: const Icon(Icons.diversity_3_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(height: 18),
          const Text('Dobrodošli nazaj ',
              style: TextStyle(color: Colors.white, fontSize: 30,
                  fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 10),
          const Text(
            'Prijavite se in nadaljujte z\nuporabo aplikacije Skills Match.',
            style: TextStyle(
                color: Colors.white70, fontSize: 15, height: 1.55)),
          const SizedBox(height: 20),
          // Chips
          Wrap(spacing: 8, runSpacing: 8, children: [
            _hChip(Icons.school_rounded, 'Učenje'),
            _hChip(Icons.groups_rounded, 'Skupnost'),
            _hChip(Icons.handshake_rounded, 'Povezovanje'),
          ]),
        ]),
      ]),
    ),
  );

  Widget _hChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.22))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.white),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
    ]),
  );

  // ── Form Card ──────────────────────────────────────────────────────────────
  Widget _formCard() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
    child: Transform.translate(
      offset: const Offset(0, -2),
      child: Card(
        elevation: 18,
        shadowColor: _kPrimary.withOpacity(0.14),
        color: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(children: [

            // Ikona — statična, lepa
            _anim(0, Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kViolet],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: _kPrimary.withOpacity(0.38),
                  blurRadius: 18, offset: const Offset(0, 7))],
              ),
              child: const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 34),
            )),

            const SizedBox(height: 16),

            _anim(0, const Text('Prijava', style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: _kText))),
            const SizedBox(height: 4),
            _anim(0, const Text('Vnesite svoje podatke za dostop do profila.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _kTextSub))),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1, color: Color(0xFFF1F5F9))),

            // Email
            _anim(1, Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _lbl('Email'),
              TextField(controller: emailController, focusNode: _emailFN,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _deco('janez@example.si',
                      Icons.email_outlined, _emailFN)),
            ])),
            const SizedBox(height: 14),

            // Geslo
            _anim(2, Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _lbl('Geslo'),
              TextField(controller: passwordController, focusNode: _passwordFN,
                  obscureText: !showPassword,
                  decoration: _deco('••••••••', Icons.lock_outline, _passwordFN,
                      suffix: IconButton(
                        icon: Icon(showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            color: _kPrimaryLight, size: 20),
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                      ))),
            ])),

            const SizedBox(height: 26),

            // Gumb
            _anim(3, GestureDetector(
              onTapDown:   (_) => _btnCtrl.forward(),
              onTapUp:     (_) => _btnCtrl.reverse(),
              onTapCancel: ()  => _btnCtrl.reverse(),
              child: ScaleTransition(
                scale: _btnScale,
                child: SizedBox(width: double.infinity, height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isLoading ? null : const LinearGradient(
                          colors: [_kPrimary, _kViolet],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      color: isLoading ? const Color(0xFFE2E8F0) : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isLoading ? [] : [BoxShadow(
                        color: _kPrimary.withOpacity(0.40),
                        blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : login,
                      icon: isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Icon(Icons.login_rounded, size: 20),
                      label: Text(isLoading ? 'Prijavljanje...' : 'Prijavi se',
                          style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ),
              ),
            )),

            const SizedBox(height: 12),

            _anim(3, Center(child: TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: RichText(text: const TextSpan(
                text: 'Nimate računa? ',
                style: TextStyle(color: _kTextSub, fontSize: 14),
                children: [TextSpan(
                  text: 'Registracija →',
                  style: TextStyle(
                      color: _kPrimary, fontWeight: FontWeight.bold))],
              )),
            ))),
          ]),
        ),
      ),
    ),
  );

  // ── Ilustracija + sekcija ─────────────────────────────────────────────────
  Widget _illustrationSection() => Container(
    margin: const EdgeInsets.fromLTRB(14, 18, 14, 0),
    child: Column(children: [

      // Ilustracija (animirana) v kartici
      Container(
        height: 210,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(
              color: _kPrimary.withOpacity(0.30),
              blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Stack(children: [
          // Orbs v ozadju ilustracije
          Positioned.fill(child: AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) => CustomPaint(
                painter: _OrbPainter(_orbCtrl.value * 2 * math.pi)))),

          // Glavna ilustracija
          Positioned.fill(child: AnimatedBuilder(
            animation: _illuCtrl,
            builder: (_, __) => CustomPaint(
                painter: _IllustrationPainter(
                    _illuCtrl.value * 2 * math.pi)))),

          // Besedilo spodaj levo
          Positioned(left: 18, bottom: 18, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.25))),
              child: const Text('Skills Match Network',
                  style: TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ])),
        ]),
      ),

      const SizedBox(height: 14),

      // Tri info kartice pod ilustracijo
      Row(children: [
        _infoCard(
          Icons.lock_person_rounded,
          'Zasebnost',
          'Vaši podatki so\nzaščiteni z SSL',
          const Color(0xFF4F46E5),
          const Color(0xFFEEF2FF),
        ),
        const SizedBox(width: 10),
        _infoCard(
          Icons.flash_on_rounded,
          'Hitrost',
          'Takojšen dostop\ndo vseh funkcij',
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
        ),
        const SizedBox(width: 10),
        _infoCard(
          Icons.hub_rounded,
          'Mreža',
          '2.400+ aktivnih\nčlanov skupnosti',
          const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
        ),
      ]),

      const SizedBox(height: 12),

      // "Niste registrirani?" banner
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8F8)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kPrimary, _kViolet],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.person_add_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Prvič tukaj?',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: _kText)),
            const Text('Ustvarite brezplačen račun v 2 minutah.',
                style: TextStyle(fontSize: 12, color: _kTextSub)),
          ])),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12)),
              child: const Text('Registracija',
                  style: TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 20),

      Center(child: Text('© 2025 Skills Match · Vse pravice pridržane',
          style: TextStyle(fontSize: 11,
              color: _kTextSub.withOpacity(0.5)))),
      const SizedBox(height: 14),
    ]),
  );

  Widget _infoCard(IconData icon, String title, String sub,
      Color c, Color bg) =>
    Expanded(child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withOpacity(0.18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(height: 7),
        Text(title, style: TextStyle(color: c, fontSize: 12,
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10,
            color: _kTextSub, height: 1.4)),
      ]),
    ));

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              _header(),
              _formCard(),
              _illustrationSection(),
            ]),
          ),
        ),
      ),
    );
  }
}