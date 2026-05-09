import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

// ─── Password Strength ────────────────────────────────────────────────────────
enum _PwStr { empty, weak, fair, good, strong }

_PwStr _evalPw(String p) {
  if (p.isEmpty) return _PwStr.empty;
  int s = 0;
  if (p.length >= 8)  s++;
  if (p.length >= 12) s++;
  if (RegExp(r'[A-Z]').hasMatch(p)) s++;
  if (RegExp(r'[0-9]').hasMatch(p)) s++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s++;
  if (s <= 1) return _PwStr.weak;
  if (s == 2) return _PwStr.fair;
  if (s == 3) return _PwStr.good;
  return _PwStr.strong;
}

Color _pwColor(_PwStr s) {
  switch (s) {
    case _PwStr.weak:   return const Color(0xFFEF4444);
    case _PwStr.fair:   return const Color(0xFFF59E0B);
    case _PwStr.good:   return const Color(0xFF3B82F6);
    case _PwStr.strong: return const Color(0xFF10B981);
    default:            return Colors.transparent;
  }
}

String _pwLabel(_PwStr s) {
  switch (s) {
    case _PwStr.weak:   return 'Šibko';
    case _PwStr.fair:   return 'Povprečno';
    case _PwStr.good:   return 'Dobro';
    case _PwStr.strong: return 'Odlično 💪';
    default:            return '';
  }
}

int _pwSteps(_PwStr s) {
  switch (s) {
    case _PwStr.weak:   return 1;
    case _PwStr.fair:   return 2;
    case _PwStr.good:   return 3;
    case _PwStr.strong: return 4;
    default:            return 0;
  }
}

// ─── Floating Orb Painter ─────────────────────────────────────────────────────
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

// ─── Register Screen ──────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {

  final imeController             = TextEditingController();
  final priimekController         = TextEditingController();
  final emailController           = TextEditingController();
  final telefonController         = TextEditingController();
  final lokacijaController        = TextEditingController();
  final passwordController        = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String vloga = 'Uporabnik';
  bool isLoading           = false;
  bool showPassword        = false;
  bool showConfirmPassword = false;
  _PwStr _pwStrength       = _PwStr.empty;

  final _imeFN     = FocusNode();
  final _priimekFN = FocusNode();
  final _emailFN   = FocusNode();
  final _telefonFN = FocusNode();
  final _lokacijaFN= FocusNode();
  final _passwordFN= FocusNode();
  final _confirmFN = FocusNode();

  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _btnCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _btnScale;
  late List<Animation<double>> _fFade;
  late List<Animation<Offset>> _fSlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 950));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.07), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _fFade  = [];
    _fSlide = [];
    for (int i = 0; i < 8; i++) {
      final s = (0.08 + i * 0.08).clamp(0.0, 0.9);
      final e = (s + 0.28).clamp(0.0, 1.0);
      _fFade.add(Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _entryCtrl,
              curve: Interval(s, e, curve: Curves.easeOut))));
      _fSlide.add(Tween<Offset>(
          begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryCtrl,
              curve: Interval(s, e, curve: Curves.easeOut))));
    }

    _orbCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 9))..repeat();

    _btnCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 110));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();

    // Password strength + step refresh
    passwordController.addListener(() =>
        setState(() => _pwStrength = _evalPw(passwordController.text)));

    // Vsi controllerji sprožijo rebuild za step indikator
    for (final c in [imeController, priimekController, emailController,
        telefonController, lokacijaController, confirmPasswordController]) {
      c.addListener(() => setState(() {}));
    }

    for (final fn in [_imeFN, _priimekFN, _emailFN, _telefonFN,
                      _lokacijaFN, _passwordFN, _confirmFN]) {
      fn.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _orbCtrl.dispose(); _btnCtrl.dispose();
    for (final c in [imeController, priimekController, emailController,
        telefonController, lokacijaController, passwordController,
        confirmPasswordController]) { c.dispose(); }
    for (final f in [_imeFN, _priimekFN, _emailFN, _telefonFN,
        _lokacijaFN, _passwordFN, _confirmFN]) { f.dispose(); }
    super.dispose();
  }

  // ── Register (unchanged logic) ─────────────────────────────────────────────
  Future<void> register() async {
    final ime     = imeController.text.trim();
    final priimek = priimekController.text.trim();
    final email   = emailController.text.trim();
    final telefon = telefonController.text.trim();
    final lokacija= lokacijaController.text.trim();
    final pw      = passwordController.text.trim();
    final cpw     = confirmPasswordController.text.trim();

    if ([ime, priimek, email, lokacija, pw, cpw].any((s) => s.isEmpty)) {
      _snack('Izpolnite vsa obvezna polja.', Colors.redAccent); return;
    }
    if (pw != cpw) { _snack('Gesli se ne ujemata.', Colors.redAccent); return; }
    setState(() => isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pw);
      final uid = cred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid, 'ime': ime, 'priimek': priimek, 'email': email,
        'telefon': telefon, 'lokacija': lokacija, 'vloga': vloga,
        'opis': '', 'razpolozljivost': '', 'vescine': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      await _showSuccessPopup();
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Registracija ni uspela.';
      if (e.code == 'email-already-in-use') msg = 'Ta email je že registriran.';
      else if (e.code == 'invalid-email')   msg = 'Email naslov ni pravilen.';
      else if (e.code == 'weak-password')   msg = 'Geslo mora imeti vsaj 6 znakov.';
      _snack(msg, Colors.redAccent);
    } catch (e) {
      _snack('Napaka: $e', Colors.redAccent);
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

  Future<void> _showSuccessPopup() async {
    await showDialog(context: context, barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.4),
                      blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 46),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Dobrodošli! 🎉', style: TextStyle(fontSize: 26,
                fontWeight: FontWeight.bold, color: _kPrimaryDark)),
            const SizedBox(height: 8),
            const Text('Vaš račun je bil uspešno ustvarjen.\nPrijavite se in odkrijte skupnost.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _kTextSub, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.centerLeft, end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.35),
                      blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                  child: const Text('Nadaljuj na prijavo',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
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
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
    );
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w600, color: _kText)));

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fFade[i],
    child: SlideTransition(position: _fSlide[i], child: child));

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header() => AnimatedBuilder(
    animation: _orbCtrl,
    builder: (_, __) => Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 68, 24, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5),
                   Color(0xFF818CF8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(
            painter: _OrbPainter(_orbCtrl.value * 2 * math.pi))),
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Pulsing icon ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.4), width: 2),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Registracija', style: TextStyle(
              color: Colors.white, fontSize: 32,
              fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.22))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_rounded, color: Colors.white70, size: 14),
              SizedBox(width: 5),
              Text('Skills Match Skupnost',
                  style: TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ustvarite račun in odkrijte skupnost\nzaupanja vrednih strokovnjakov.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
          const SizedBox(height: 22),
          _steps(),
        ]),
      ]),
    ),
  );

  // Korak je "done" ko so vsa njegova polja izpolnjena
  bool get _step1Done =>
      imeController.text.trim().isNotEmpty &&
      priimekController.text.trim().isNotEmpty &&
      emailController.text.trim().isNotEmpty &&
      lokacijaController.text.trim().isNotEmpty;

  bool get _step2Done => vloga.isNotEmpty; // vloga je vedno izbrana

  bool get _step3Done =>
      passwordController.text.trim().isNotEmpty &&
      confirmPasswordController.text.trim().isNotEmpty;

  // Kateri korak je trenutno aktiven (0-based)
  int get _currentStep {
    if (!_step1Done) return 0;
    if (!_step2Done) return 1;
    return 2;
  }

  Widget _steps() {
    final labels = ['Podatki', 'Vloga', 'Geslo'];
    final done   = [_step1Done, _step2Done, _step3Done];

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (int i = 0; i < labels.length; i++) ...[
        Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done[i]
                  ? Colors.white                          // izpolnjeno → bela
                  : i == _currentStep
                      ? Colors.white.withOpacity(0.9)    // aktiven → skoraj bela
                      : Colors.white.withOpacity(0.15),  // čaka → prosojno
              border: Border.all(
                  color: Colors.white.withOpacity(
                      done[i] ? 1.0 : i == _currentStep ? 0.8 : 0.35),
                  width: 1.5),
              boxShadow: done[i] || i == _currentStep ? [
                BoxShadow(
                    color: Colors.white.withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 2))
              ] : [],
            ),
            child: Center(
              child: done[i]
                  ? Icon(Icons.check_rounded,
                      size: 16,
                      color: _kPrimary)            // ✓ ikona ko izpolnjeno
                  : Text('${i + 1}', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: i == _currentStep ? _kPrimary : Colors.white54)),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 11,
              fontWeight: done[i] || i == _currentStep
                  ? FontWeight.w600 : FontWeight.normal,
              color: done[i]
                  ? Colors.white
                  : i == _currentStep
                      ? Colors.white.withOpacity(0.95)
                      : Colors.white.withOpacity(0.45),
            ),
            child: Text(labels[i]),
          ),
        ]),
        if (i < labels.length - 1)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 36, height: 2,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: done[i]
                  ? Colors.white.withOpacity(0.8)
                  : Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ]
    ]);
  }

  // ── Role cards ─────────────────────────────────────────────────────────────
  Widget _roleCards() {
    final roles = [
      ('Uporabnik', Icons.person_rounded,      'Iščem\nstoritve',       const Color(0xFF4F46E5)),
      ('Mentor',    Icons.school_rounded,       'Poučujem\ndruge',       const Color(0xFF7C3AED)),
      ('Učenec',    Icons.auto_stories_rounded, 'Učim se\nod mentorjev', const Color(0xFF0891B2)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl('Vloga'),
      Row(children: roles.map((r) {
        final (name, icon, sub, color) = r;
        final sel = vloga == name;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => vloga = name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              color: sel ? color.withOpacity(0.11) : _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: sel ? color : _kBorder, width: sel ? 2 : 1.2),
              boxShadow: sel ? [BoxShadow(color: color.withOpacity(0.2),
                  blurRadius: 12, offset: const Offset(0, 4))] : [],
            ),
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 230),
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.14) : Colors.transparent,
                  shape: BoxShape.circle),
                child: Icon(icon, color: sel ? color : const Color(0xFFA5B4FC),
                    size: 22),
              ),
              const SizedBox(height: 6),
              Text(name, style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: sel ? color : _kText)),
              const SizedBox(height: 2),
              Text(sub, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: _kTextSub,
                      height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 230),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? color : Colors.transparent,
                  border: Border.all(
                      color: sel ? color : _kBorder, width: 1.5)),
                child: sel ? const Icon(Icons.check_rounded,
                    size: 13, color: Colors.white) : null,
              ),
            ]),
          ),
        ));
      }).toList()),
    ]);
  }

  // ── Password strength bar ──────────────────────────────────────────────────
  Widget _pwBar() {
    if (_pwStrength == _PwStr.empty) return const SizedBox.shrink();
    final steps = _pwSteps(_pwStrength);
    final color = _pwColor(_pwStrength);
    return AnimatedOpacity(
      opacity: 1, duration: const Duration(milliseconds: 300),
      child: Padding(padding: const EdgeInsets.only(top: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: List.generate(4, (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 4, margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: i < steps ? color : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4)))))),
          const SizedBox(height: 5),
          Text('Moč gesla: ${_pwLabel(_pwStrength)}',
              style: TextStyle(fontSize: 11, color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Bottom section ─────────────────────────────────────────────────────────
  Widget _bottom() => Container(
    margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
    child: Column(children: [

      // Stats card
      Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.3),
              blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Column(children: [
          const Text('Skupnost v številkah', style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tisoče strokovnjakov vas že čaka',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('200+', 'Uporabnikov'),
            Container(height: 34, width: 1, color: Colors.white24),
            _stat('100+', 'Mentorjev'),
            Container(height: 34, width: 1, color: Colors.white24),
            _stat('96%', 'Zadovoljnih'),
          ]),
        ]),
      ),

      const SizedBox(height: 12),

      // Feature chips
      Row(children: [
        _feat(Icons.security_rounded, 'Varnost',
            'SSL šifriranje in zaščita podatkov',
            const Color(0xFF059669), const Color(0xFFECFDF5)),
        const SizedBox(width: 10),
        _feat(Icons.verified_rounded, 'Preverjeno',
            'Verificirani profili v skupnosti',
            const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
        const SizedBox(width: 10),
        _feat(Icons.bolt_rounded, 'Hitro',
            'Takojšnja aktivacija računa',
            const Color(0xFFD97706), const Color(0xFFFFFBEB)),
      ]),

      const SizedBox(height: 12),

      // How it works
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.info_outline_rounded, color: _kPrimary, size: 18),
            SizedBox(width: 8),
            Text('Kako deluje?', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.bold, color: _kText)),
          ]),
          const SizedBox(height: 16),
          _how(1, 'Ustvarite račun', 'Izpolnite vaše osnovne podatke.'),
          _how(2, 'Izberite vlogo', 'Bodite Mentor, Učenec ali Uporabnik.'),
          _how(3, 'Povežite se', 'Odkrijte skupnost in začnite sodelovati.'),
        ]),
      ),


      // Trust chips
      Row(children: [
        _chip(Icons.lock_outline_rounded, 'Varno'),
        const SizedBox(width: 8),
        _chip(Icons.privacy_tip_outlined, 'GDPR'),
        const SizedBox(width: 8),
        _chip(Icons.support_agent_rounded, 'Podpora 24/7'),
      ]),

      const SizedBox(height: 22),
      Center(child: Text('© 2026 Skills Match · Vse pravice pridržane',
          style: TextStyle(fontSize: 11,
              color: _kTextSub.withOpacity(0.55)))),
      const SizedBox(height: 10),
    ]),
  );

  Widget _stat(String v, String l) => Column(children: [
    Text(v, style: const TextStyle(color: Colors.white,
        fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(l, style: const TextStyle(color: Colors.white54, fontSize: 11)),
  ]);

  Widget _feat(IconData icon, String title, String sub, Color c, Color bg) =>
    Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 24),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: c, fontSize: 12,
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: _kTextSub,
            height: 1.4)),
      ]),
    ));

  Widget _how(int n, String title, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 28, height: 28,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kPrimary, _kViolet],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          shape: BoxShape.circle),
        child: Center(child: Text('$n',
            style: const TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600,
            fontSize: 13, color: _kText)),
        Text(sub, style: const TextStyle(fontSize: 12, color: _kTextSub)),
      ])),
    ]),
  );

  Widget _chip(IconData icon, String label) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: _kPrimary, size: 15),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w600, color: _kText)),
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

              // Form card
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Transform.translate(
                  offset: const Offset(0, -2),
                  child: Card(
                    elevation: 18,
                    shadowColor: _kPrimary.withOpacity(0.14),
                    color: _kCardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                        // Card header
                        Row(children: [
                          Container(width: 46, height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_kPrimary, _kViolet],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.edit_note_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Ustvari račun', style: TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold, color: _kText)),
                            Text('Polja z * so obvezna',
                                style: TextStyle(fontSize: 12, color: _kTextSub)),
                          ]),
                        ]),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9))),

                        // Ime + Priimek
                        _anim(0, Row(children: [
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _lbl('Ime *'),
                            TextField(controller: imeController,
                              focusNode: _imeFN,
                              textCapitalization: TextCapitalization.words,
                              decoration: _deco('Janez',
                                  Icons.badge_outlined, _imeFN)),
                          ])),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _lbl('Priimek *'),
                            TextField(controller: priimekController,
                              focusNode: _priimekFN,
                              textCapitalization: TextCapitalization.words,
                              decoration: _deco('Novak',
                                  Icons.person_outline, _priimekFN)),
                          ])),
                        ])),
                        const SizedBox(height: 16),

                        // Email
                        _anim(1, Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _lbl('Email *'),
                          TextField(controller: emailController,
                            focusNode: _emailFN,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _deco('janez@example.si',
                                Icons.email_outlined, _emailFN)),
                        ])),
                        const SizedBox(height: 16),

                        // Telefon
                        _anim(2, Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _lbl('Telefon'),
                          TextField(controller: telefonController,
                            focusNode: _telefonFN,
                            keyboardType: TextInputType.phone,
                            decoration: _deco('+386 41 000 000',
                                Icons.phone_android_outlined, _telefonFN)),
                        ])),
                        const SizedBox(height: 16),

                        // Lokacija
                        _anim(3, Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _lbl('Lokacija *'),
                          TextField(controller: lokacijaController,
                            focusNode: _lokacijaFN,
                            decoration: _deco('Ljubljana, Slovenija',
                                Icons.location_on_outlined, _lokacijaFN)),
                        ])),
                        const SizedBox(height: 20),

                        // Role cards
                        _anim(4, _roleCards()),
                        const SizedBox(height: 20),

                        // Geslo
                        _anim(5, Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _lbl('Geslo *'),
                          TextField(controller: passwordController,
                            focusNode: _passwordFN,
                            obscureText: !showPassword,
                            decoration: _deco('••••••••',
                                Icons.lock_outline, _passwordFN,
                                suffix: IconButton(
                                  icon: Icon(showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                    color: _kPrimaryLight, size: 20),
                                  onPressed: () => setState(
                                      () => showPassword = !showPassword),
                                ))),
                          _pwBar(),
                        ])),
                        const SizedBox(height: 16),

                        // Confirm password
                        _anim(6, Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _lbl('Ponovite geslo *'),
                          TextField(controller: confirmPasswordController,
                            focusNode: _confirmFN,
                            obscureText: !showConfirmPassword,
                            decoration: _deco('••••••••',
                                Icons.lock_reset_outlined, _confirmFN,
                                suffix: IconButton(
                                  icon: Icon(showConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                    color: _kPrimaryLight, size: 20),
                                  onPressed: () => setState(() =>
                                      showConfirmPassword = !showConfirmPassword),
                                ))),
                        ])),

                        const SizedBox(height: 28),

                        // Register button with press animation
                        _anim(7, GestureDetector(
                          onTapDown: (_) => _btnCtrl.forward(),
                          onTapUp:   (_) => _btnCtrl.reverse(),
                          onTapCancel: ()  => _btnCtrl.reverse(),
                          child: ScaleTransition(
                            scale: _btnScale,
                            child: SizedBox(width: double.infinity, height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: isLoading ? null
                                      : const LinearGradient(
                                          colors: [_kPrimary, _kViolet],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight),
                                  color: isLoading
                                      ? const Color(0xFFE2E8F0) : null,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: isLoading ? [] : [BoxShadow(
                                    color: _kPrimary.withOpacity(0.42),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7))],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: isLoading ? null : register,
                                  icon: isLoading
                                      ? const SizedBox(width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white))
                                      : const Icon(Icons.person_add_alt_1_rounded,
                                          size: 20),
                                  label: Text(
                                    isLoading ? 'Ustvarjanje...' : 'Ustvari račun',
                                    style: const TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18))),
                                ),
                              ),
                            ),
                          ),
                        )),

                        const SizedBox(height: 14),

                        Center(child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: RichText(text: const TextSpan(
                            text: 'Že imate račun? ',
                            style: TextStyle(color: _kTextSub, fontSize: 14),
                            children: [TextSpan(
                              text: 'Prijava →',
                              style: TextStyle(color: _kPrimary,
                                  fontWeight: FontWeight.bold))],
                          )),
                        )),
                      ]),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _bottom(),
            ]),
          ),
        ),
      ),
    );
  }
}