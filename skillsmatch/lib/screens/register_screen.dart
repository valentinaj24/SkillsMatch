import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_colors.dart'; // added for dynamic theme
import '../services/service_locator.dart';

// Brand / accent colors (remain unchanged)
const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryDark = Color(0xFF312E81);
const _kPrimaryLight = Color(0xFF818CF8);
const _kViolet = Color(0xFF7C3AED);

// Constant header gradient (same as login/profile)
const _headerGradientColors = [
  Color(0xFF1E1B4B),
  Color(0xFF3730A3),
  Color(0xFF4F46E5),
  Color(0xFF818CF8),
];

// ─── Password Strength ────────────────────────────────────────────────────────
enum _PwStr { empty, weak, fair, good, strong }

_PwStr _evalPw(String p) {
  if (p.isEmpty) return _PwStr.empty;
  int s = 0;
  if (p.length >= 8) s++;
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
    case _PwStr.weak:
      return const Color(0xFFEF4444);
    case _PwStr.fair:
      return const Color(0xFFF59E0B);
    case _PwStr.good:
      return const Color(0xFF3B82F6);
    case _PwStr.strong:
      return const Color(0xFF10B981);
    default:
      return Colors.transparent;
  }
}

String _pwLabel(_PwStr s) {
  switch (s) {
    case _PwStr.weak:
      return 'Šibko';
    case _PwStr.fair:
      return 'Povprečno';
    case _PwStr.good:
      return 'Dobro';
    case _PwStr.strong:
      return 'Odlično 💪';
    default:
      return '';
  }
}

int _pwSteps(_PwStr s) {
  switch (s) {
    case _PwStr.weak:
      return 1;
    case _PwStr.fair:
      return 2;
    case _PwStr.good:
      return 3;
    case _PwStr.strong:
      return 4;
    default:
      return 0;
  }
}

// ─── Floating Orb Painter (unchanged) ─────────────────────────────────────
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
  bool shouldRepaint(_OrbPainter o) => o.t != t;
}

// ─── Star Painter (unchanged) ─────────────────────────────────────────────
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
      final opacity = (0.4 + 0.4 * math.sin(t * 2.5 + rx * 10)).clamp(0.1, 0.9);
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
  bool shouldRepaint(_StarPainter o) => o.t != t;
}

// ─── Register Screen ──────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final imeController = TextEditingController();
  final priimekController = TextEditingController();
  final emailController = TextEditingController();
  final telefonController = TextEditingController();
  final lokacijaController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String vloga = 'Uporabnik';
  bool isLoading = false;
  bool isGettingLocation = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  _PwStr _pwStrength = _PwStr.empty;

  final _imeFN = FocusNode();
  final _priimekFN = FocusNode();
  final _emailFN = FocusNode();
  final _telefonFN = FocusNode();
  final _lokacijaFN = FocusNode();
  final _passwordFN = FocusNode();
  final _confirmFN = FocusNode();

  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _btnScale;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;
  late List<Animation<double>> _fFade;
  late List<Animation<Offset>> _fSlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _fFade = [];
    _fSlide = [];
    for (int i = 0; i < 8; i++) {
      final s = (0.08 + i * 0.08).clamp(0.0, 0.9);
      final e = (s + 0.28).clamp(0.0, 1.0);
      _fFade.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: Interval(s, e, curve: Curves.easeOut),
          ),
        ),
      );
      _fSlide.add(
        Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: Interval(s, e, curve: Curves.easeOut),
          ),
        ),
      );
    }

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _btnScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
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

    _entryCtrl.forward();
    passwordController.addListener(
      () => setState(() => _pwStrength = _evalPw(passwordController.text)),
    );
    for (final c in [
      imeController,
      priimekController,
      emailController,
      telefonController,
      lokacijaController,
      confirmPasswordController,
    ]) {
      c.addListener(() => setState(() {}));
    }
    for (final fn in [
      _imeFN,
      _priimekFN,
      _emailFN,
      _telefonFN,
      _lokacijaFN,
      _passwordFN,
      _confirmFN,
    ]) {
      fn.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    _btnCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    for (final c in [
      imeController,
      priimekController,
      emailController,
      telefonController,
      lokacijaController,
      passwordController,
      confirmPasswordController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _imeFN,
      _priimekFN,
      _emailFN,
      _telefonFN,
      _lokacijaFN,
      _passwordFN,
      _confirmFN,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Register (unchanged logic) ─────────────────────────────────────────────
  Future<void> register() async {
    final ime = imeController.text.trim();
    final priimek = priimekController.text.trim();
    final email = emailController.text.trim();
    final telefon = telefonController.text.trim();
    final lokacija = lokacijaController.text.trim();
    final pw = passwordController.text.trim();
    final cpw = confirmPasswordController.text.trim();

    if ([ime, priimek, email, lokacija, pw, cpw].any((s) => s.isEmpty)) {
      _snack('Izpolnite vsa obvezna polja.', Colors.redAccent);
      return;
    }

    if (pw != cpw) {
      _snack('Gesli se ne ujemata.', Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    try {
      final cred = await ServiceLocator.auth.createUserWithEmailAndPassword(
        email: email,
        password: pw,
      );

      final user = cred.user!;
      final uid = user.uid;

      await user.sendEmailVerification();

      await ServiceLocator.firestore.collection('users').doc(uid).set({
        'uid': uid,
        'ime': ime,
        'priimek': priimek,
        'email': email,
        'telefon': telefon,
        'lokacija': lokacija,
        'vloga': vloga,
        'opis': '',
        'razpolozljivost': '',
        'vescine': [],
        'profileCompleted': false,
        'authProvider': 'email',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await ServiceLocator.auth.signOut();

      if (!mounted) return;

      await _showSuccessPopup();

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Registracija ni uspela.';

      if (e.code == 'email-already-in-use') {
        msg = 'Ta email je že registriran.';
      } else if (e.code == 'invalid-email') {
        msg = 'Email naslov ni pravilen.';
      } else if (e.code == 'weak-password') {
        msg = 'Geslo mora imeti vsaj 6 znakov.';
      }

      _snack(msg, Colors.redAccent);
    } catch (e) {
      _snack('Napaka: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> uporabiTrenutnoLokacijo() async {
    setState(() => isGettingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('Lokacijske storitve niso omogočene.', Colors.orange);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _snack('Dovoljenje za lokacijo je zavrnjeno.', Colors.orange);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _snack('Lokacija je trajno zavrnjena.', Colors.orange);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isNotEmpty) {
        final place = places.first;
        final city = place.locality ?? '';
        final country = place.country ?? '';
        lokacijaController.text = '$city, $country';
        _snack('Lokacija uspešno dodana.', _kPrimary);
      }
    } catch (e) {
      _snack('Napaka pri pridobivanju lokacije.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => isGettingLocation = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showSuccessPopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: context.isDark
                  ? [const Color(0xFF1A1933), const Color(0xFF252438)]
                  : [const Color(0xFFEEF2FF), const Color(0xFFF5F3FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kViolet],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Dobrodošli! 🎉',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.kText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vaš račun je bil ustvarjen.\nNa email smo vam poslali povezavo za potrditev računa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.kTextSub,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kViolet],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    key: const Key('success_continue_button'),
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Razumem',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  // ── Theme‑aware helpers ─────────────────────────────────────────────────
  InputDecoration _deco(
    String hint,
    IconData icon,
    FocusNode fn, {
    Widget? suffix,
  }) {
    final focused = fn.hasFocus;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.isDark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFFCBD5E1),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: focused ? _kPrimary : const Color(0xFFA5B4FC),
        size: 20,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: focused
          ? (context.isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F0FF))
          : context.kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.kBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.kText,
      ),
    ),
  );

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fFade[i],
    child: SlideTransition(position: _fSlide[i], child: child),
  );

  // ─── Header (constant gradient) ─────────────────────────────────────────
  Widget _header() => AnimatedBuilder(
    animation: Listenable.merge([_orbCtrl, _pulseCtrl, _floatCtrl]),
    builder: (_, __) => Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 68, 24, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _headerGradientColors,
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
          Positioned.fill(
            child: CustomPaint(
              painter: _StarPainter(_orbCtrl.value * 2 * math.pi),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _pulseAnim.value * 1.18,
                      child: Container(
                        width: 158,
                        height: 158,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _pulseAnim.value * 1.08,
                      child: Container(
                        width: 145,
                        height: 145,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.20),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.38),
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                          width: 3.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 36,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: _kViolet.withOpacity(0.50),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.30),
                            blurRadius: 50,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/slika3.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Registracija',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Skills Match Skupnost',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ustvarite račun in odkrijte skupnost\nzaupanja vrednih strokovnjakov.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              _steps(),
            ],
          ),
        ],
      ),
    ),
  );

  bool get _step1Done =>
      imeController.text.trim().isNotEmpty &&
      priimekController.text.trim().isNotEmpty &&
      emailController.text.trim().isNotEmpty &&
      lokacijaController.text.trim().isNotEmpty;
  bool get _step2Done => vloga.isNotEmpty;
  bool get _step3Done =>
      passwordController.text.trim().isNotEmpty &&
      confirmPasswordController.text.trim().isNotEmpty;
  int get _currentStep {
    if (!_step1Done) return 0;
    if (!_step2Done) return 1;
    return 2;
  }

  Widget _steps() {
    final labels = ['Podatki', 'Vloga', 'Geslo'];
    final done = [_step1Done, _step2Done, _step3Done];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done[i]
                      ? Colors.white
                      : i == _currentStep
                      ? Colors.white.withOpacity(0.9)
                      : Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      done[i]
                          ? 1.0
                          : i == _currentStep
                          ? 0.8
                          : 0.35,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: done[i] || i == _currentStep
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: done[i]
                      ? Icon(Icons.check_rounded, size: 16, color: _kPrimary)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: i == _currentStep
                                ? _kPrimary
                                : Colors.white54,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: done[i] || i == _currentStep
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: done[i]
                      ? Colors.white
                      : i == _currentStep
                      ? Colors.white.withOpacity(0.95)
                      : Colors.white.withOpacity(0.45),
                ),
                child: Text(labels[i]),
              ),
            ],
          ),
          if (i < labels.length - 1)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 36,
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: done[i]
                    ? Colors.white.withOpacity(0.8)
                    : Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ],
    );
  }

  // ─── Role cards (theme‑aware) ──────────────────────────────────────────────
  Widget _roleCards() {
    final roles = [
      (
        'Uporabnik',
        Icons.person_rounded,
        'Iščem\nstoritve',
        const Color(0xFF4F46E5),
      ),
      (
        'Mentor',
        Icons.school_rounded,
        'Poučujem\ndruge',
        const Color(0xFF7C3AED),
      ),
      (
        'Učenec',
        Icons.auto_stories_rounded,
        'Učim se\nod mentorjev',
        const Color(0xFF0891B2),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lbl('Vloga'),
        Row(
          children: roles.map((r) {
            final (name, icon, sub, color) = r;
            final sel = vloga == name;
            return Expanded(
              child: GestureDetector(
                key: Key('role_card_${name.toLowerCase()}'),
                onTap: () => setState(() => vloga = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.11) : context.kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? color : context.kBorder,
                      width: sel ? 2 : 1.2,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 230),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withOpacity(0.14)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: sel ? color : const Color(0xFFA5B4FC),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sel ? color : context.kText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        textAlign: TextAlign.center,
                        // 🔧 FIX: removed const, use context.kTextSub
                        style: TextStyle(
                          fontSize: 10,
                          color: context.kTextSub,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 230),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? color : Colors.transparent,
                          border: Border.all(
                            color: sel ? color : context.kBorder,
                            width: 1.5,
                          ),
                        ),
                        child: sel
                            ? const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Password strength bar ─────────────────────────────────────────────────
  Widget _pwBar() {
    if (_pwStrength == _PwStr.empty) return const SizedBox.shrink();
    final steps = _pwSteps(_pwStrength);
    final color = _pwColor(_pwStrength);
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 4,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i < steps ? color : context.kBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Moč gesla: ${_pwLabel(_pwStrength)}',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom section (theme‑aware) ─────────────────────────────────────────
  Widget _bottom() => Container(
    margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
    child: Column(
      children: [
        // Stats card (constant gradient or dynamic? We'll keep it dynamic like the profile screen)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.isDark
                  ? [const Color(0xFF1E1B4B), const Color(0xFF4F46E5)]
                  : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.3),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Skupnost v številkah',
                style: TextStyle(
                  color: context.isDark ? Colors.white : context.kText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tisoče strokovnjakov vas že čaka',
                style: TextStyle(
                  color: context.isDark ? Colors.white54 : context.kTextSub,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('200+', 'Uporabnikov'),
                  Container(
                    height: 34,
                    width: 1,
                    color: context.isDark ? Colors.white24 : Colors.black12,
                  ),
                  _stat('100+', 'Mentorjev'),
                  Container(
                    height: 34,
                    width: 1,
                    color: context.isDark ? Colors.white24 : Colors.black12,
                  ),
                  _stat('96%', 'Zadovoljnih'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Feature chips
        Row(
          children: [
            _feat(
              Icons.security_rounded,
              'Varnost',
              'SSL šifriranje in zaščita podatkov',
              const Color(0xFF059669),
              context.isDark
                  ? const Color(0xFF0C1F18)
                  : const Color(0xFFECFDF5),
            ),
            const SizedBox(width: 10),
            _feat(
              Icons.verified_rounded,
              'Preverjeno',
              'Verificirani profili v skupnosti',
              const Color(0xFF7C3AED),
              context.isDark
                  ? const Color(0xFF1A1933)
                  : const Color(0xFFF5F3FF),
            ),
            const SizedBox(width: 10),
            _feat(
              Icons.bolt_rounded,
              'Hitro',
              'Takojšnja aktivacija računa',
              const Color(0xFFD97706),
              context.isDark
                  ? const Color(0xFF1F1A0F)
                  : const Color(0xFFFFFBEB),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // How it works
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.kCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                  Icon(Icons.info_outline_rounded, color: _kPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Kako deluje?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.kText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _how(1, 'Ustvarite račun', 'Izpolnite vaše osnovne podatke.'),
              _how(2, 'Izberite vlogo', 'Bodite Mentor, Učenec ali Uporabnik.'),
              _how(
                3,
                'Povežite se',
                'Odkrijte skupnost in začnite sodelovati.',
              ),
            ],
          ),
        ),
        // Trust chips
        Row(
          children: [
            _chip(Icons.lock_outline_rounded, 'Varno'),
            const SizedBox(width: 8),
            _chip(Icons.privacy_tip_outlined, 'GDPR'),
            const SizedBox(width: 8),
            _chip(Icons.support_agent_rounded, 'Podpora 24/7'),
          ],
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            '© 2026 Skills Match · Vse pravice pridržane',
            style: TextStyle(
              fontSize: 11,
              color: context.kTextSub.withOpacity(0.55),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ),
  );

  Widget _stat(String v, String l) => Column(
    children: [
      Text(
        v,
        style: TextStyle(
          color: context.isDark ? Colors.white : context.kText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        l,
        style: TextStyle(
          color: context.isDark ? Colors.white54 : context.kTextSub,
          fontSize: 11,
        ),
      ),
    ],
  );

  Widget _feat(IconData icon, String title, String sub, Color c, Color bg) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: c, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: context.kTextSub,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _how(int n, String title, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_kPrimary, _kViolet]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: context.kText,
                ),
              ),
              Text(
                sub,
                style: TextStyle(fontSize: 12, color: context.kTextSub),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _chip(IconData icon, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _kPrimary, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.kText,
            ),
          ),
        ],
      ),
    ),
  );

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _header(),
                // Form card
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: Transform.translate(
                    offset: const Offset(0, -36),
                    child: Card(
                      elevation: 18,
                      shadowColor: _kPrimary.withOpacity(0.14),
                      color: context.kCardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [_kPrimary, _kViolet],
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kPrimary.withOpacity(0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit_note_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Ustvari račun',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: context.kText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vnesite svoje podatke za nov račun.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.kTextSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _anim(
                              0,
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _lbl('Ime *'),
                                        TextField(
                                          key: Key('name_register'),
                                          controller: imeController,
                                          focusNode: _imeFN,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          decoration: _deco(
                                            'Janez',
                                            Icons.badge_outlined,
                                            _imeFN,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _lbl('Priimek *'),
                                        TextField(
                                          key: Key('surname_register'),
                                          controller: priimekController,
                                          focusNode: _priimekFN,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          decoration: _deco(
                                            'Novak',
                                            Icons.person_outline,
                                            _priimekFN,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _anim(
                              1,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _lbl('Email *'),
                                  TextField(
                                    key: Key('email_register'),
                                    controller: emailController,
                                    focusNode: _emailFN,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _deco(
                                      'janez@example.si',
                                      Icons.email_outlined,
                                      _emailFN,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _anim(
                              2,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _lbl('Telefon'),
                                  TextField(
                                    key: Key('phone_register'),
                                    controller: telefonController,
                                    focusNode: _telefonFN,
                                    keyboardType: TextInputType.phone,
                                    decoration: _deco(
                                      '+386 41 000 000',
                                      Icons.phone_android_outlined,
                                      _telefonFN,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _anim(
                              3,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _lbl('Lokacija *'),
                                  TextField(
                                    key: Key('location_register'),
                                    controller: lokacijaController,
                                    focusNode: _lokacijaFN,
                                    decoration: _deco(
                                      'Ljubljana, Slovenija',
                                      Icons.location_on_outlined,
                                      _lokacijaFN,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      key: Key('location_button_register'),
                                      onPressed: isGettingLocation
                                          ? null
                                          : uporabiTrenutnoLokacijo,
                                      icon: isGettingLocation
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location_rounded,
                                            ),
                                      label: Text(
                                        isGettingLocation
                                            ? 'Pridobivanje lokacije...'
                                            : 'Uporabi trenutno lokacijo',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _kPrimary,
                                        side: const BorderSide(
                                          color: _kPrimary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _anim(4, _roleCards()),
                            const SizedBox(height: 20),
                            _anim(
                              5,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _lbl('Geslo *'),
                                  TextField(
                                    key: Key('password_register'),
                                    controller: passwordController,
                                    focusNode: _passwordFN,
                                    obscureText: !showPassword,
                                    decoration: _deco(
                                      '••••••••',
                                      Icons.lock_outline,
                                      _passwordFN,
                                      suffix: IconButton(
                                        key: Key('toggle_password_visibility'),
                                        icon: Icon(
                                          showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: _kPrimaryLight,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => showPassword = !showPassword,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _pwBar(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _anim(
                              6,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _lbl('Ponovite geslo *'),
                                  TextField(
                                    key: Key('confirm_password_register'),
                                    controller: confirmPasswordController,
                                    focusNode: _confirmFN,
                                    obscureText: !showConfirmPassword,
                                    decoration: _deco(
                                      '••••••••',
                                      Icons.lock_reset_outlined,
                                      _confirmFN,
                                      suffix: IconButton(
                                        key: Key(
                                          'toggle_confirm_password_visibility',
                                        ),
                                        icon: Icon(
                                          showConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: _kPrimaryLight,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => showConfirmPassword =
                                              !showConfirmPassword,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            _anim(
                              7,
                              GestureDetector(
                                onTapDown: (_) => _btnCtrl.forward(),
                                onTapUp: (_) => _btnCtrl.reverse(),
                                onTapCancel: () => _btnCtrl.reverse(),
                                child: ScaleTransition(
                                  scale: _btnScale,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: isLoading
                                            ? null
                                            : const LinearGradient(
                                                colors: [_kPrimary, _kViolet],
                                              ),
                                        color: isLoading
                                            ? (context.isDark
                                                  ? const Color(0xFF2A2A3E)
                                                  : const Color(0xFFE2E8F0))
                                            : null,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: isLoading
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: _kPrimary.withOpacity(
                                                    0.42,
                                                  ),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 7),
                                                ),
                                              ],
                                      ),
                                      child: ElevatedButton.icon(
                                        key: Key('register_button'),
                                        onPressed: isLoading ? null : register,
                                        icon: isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.person_add_alt_1_rounded,
                                                size: 20,
                                              ),
                                        label: Text(
                                          isLoading
                                              ? 'Ustvarjanje...'
                                              : 'Ustvari račun',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                key: Key('back_to_login_button'),
                                onPressed: () => Navigator.pop(context),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Že imate račun? ',
                                    style: TextStyle(
                                      color: context.kTextSub,
                                      fontSize: 14,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Prijava →',
                                        style: TextStyle(
                                          color: _kPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _bottom(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
