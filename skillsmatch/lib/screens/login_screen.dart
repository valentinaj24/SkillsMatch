import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import 'auth_gate.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryDark = Color(0xFF312E81);
const _kPrimaryLight = Color(0xFF818CF8);
const _kViolet = Color(0xFF7C3AED);
const _kSurface = Color(0xFFF5F5FF);
const _kCardBg = Color(0xFFFFFFFF);
const _kBg = Color(0xFFF1F0FF);
const _kBorder = Color(0xFFCBD5E1);
const _kText = Color(0xFF1E1B4B);
const _kTextSub = Color(0xFF6B7280);

const _mascotImage = 'assets/images/slika2.png';

class _OrbPainter extends CustomPainter {
  final double t;

  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (0.15, 0.22, 120.0, const Color(0x30818CF8)),
      (0.85, 0.10, 100.0, const Color(0x407C3AED)),
      (0.55, 0.85, 95.0, const Color(0x254F46E5)),
      (0.92, 0.55, 75.0, const Color(0x22818CF8)),
    ];

    for (final (rx, ry, r, color) in orbs) {
      final dx = math.sin(t + rx * 5) * 16;
      final dy = math.cos(t + ry * 4) * 13;
      final center = Offset(size.width * rx + dx, size.height * ry + dy);

      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => oldDelegate.t != t;
}

class _IllustrationPainter extends CustomPainter {
  final double t;

  _IllustrationPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final center = Offset(w * 0.50, h * 0.48);

    final topLeft = Offset(w * 0.31, h * 0.24 + math.sin(t * 0.7) * 2);

    final topRight = Offset(w * 0.70, h * 0.28 + math.sin(t * 0.7 + 1.5) * 2);

    final bottomLeft = Offset(w * 0.24, h * 0.62 + math.sin(t * 0.7 + 0.5) * 2);

    final bottomRight = Offset(
      w * 0.82,
      h * 0.62 + math.sin(t * 0.7 + 2.0) * 2,
    );

    // background glow
    canvas.drawCircle(
      Offset(w * 0.54, h * 0.50),
      w * 0.43,
      Paint()..color = Colors.white.withOpacity(0.06),
    );

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.32)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    for (final pair in [
      (center, topLeft),
      (center, topRight),
      (center, bottomLeft),
      (center, bottomRight),
      (topLeft, bottomLeft),
      (topRight, bottomRight),
    ]) {
      canvas.drawLine(pair.$1, pair.$2, linePaint);
    }

    // glowing moving dots
    final pulsePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final pulse1 = (math.sin(t * 1.35) + 1) / 2;

    canvas.drawCircle(
      Offset(
        center.dx + (topRight.dx - center.dx) * pulse1,
        center.dy + (topRight.dy - center.dy) * pulse1,
      ),
      3.7,
      pulsePaint,
    );

    final pulse2 = (math.sin(t * 1.15 + math.pi) + 1) / 2;

    canvas.drawCircle(
      Offset(
        center.dx + (bottomLeft.dx - center.dx) * pulse2,
        center.dy + (bottomLeft.dy - center.dy) * pulse2,
      ),
      3.4,
      pulsePaint,
    );

    void drawNode(Offset pos, double radius, Color color, IconData icon) {
      // shadow
      canvas.drawCircle(
        pos + const Offset(0, 5),
        radius,
        Paint()
          ..color = Colors.black.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // fill
      canvas.drawCircle(pos, radius, Paint()..color = color);

      // border
      canvas.drawCircle(
        pos,
        radius + 3,
        Paint()
          ..color = Colors.white.withOpacity(0.78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: radius * 0.76,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    void drawCenterNode(Offset pos, double radius) {
      // shadow
      canvas.drawCircle(
        pos + const Offset(0, 6),
        radius,
        Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // fill
      canvas.drawCircle(pos, radius, Paint()..color = _kPrimary);

      // white ring
      canvas.drawCircle(
        pos,
        radius + 3,
        Paint()
          ..color = Colors.white.withOpacity(0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '🔐',
          style: TextStyle(fontSize: radius * 1.05),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    void drawBadge(Offset center, String text, Color color) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: tp.width + 22,
          height: tp.height + 10,
        ),
        const Radius.circular(11),
      );

      canvas.drawRRect(rect, Paint()..color = color.withOpacity(0.96));

      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
      );
    }

    // nodes
    drawNode(topLeft, 23, const Color(0xFF10B981), Icons.check_rounded);

    drawNode(topRight, 23, const Color(0xFFFF8A00), Icons.flash_on_rounded);

    drawNode(bottomLeft, 23, _kViolet, Icons.person_rounded);

    drawNode(bottomRight, 23, const Color(0xFF0891B2), Icons.person_rounded);

    drawCenterNode(center, 34);

    // badges
    drawBadge(Offset(w * 0.14, h * 0.37), '✓ Varno', const Color(0xFF10B981));

    drawBadge(Offset(w * 0.84, h * 0.24), '⚡ Hitro', const Color(0xFFF59E0B));

    drawBadge(
      Offset(w * 0.57, h * 0.82),
      '🌐 Skupnost',
      const Color(0xFF818CF8),
    );
  }

  @override
  bool shouldRepaint(_IllustrationPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

class _MascotHeader extends StatelessWidget {
  final double t;

  const _MascotHeader({required this.t});

  @override
  Widget build(BuildContext context) {
    final moveY = math.sin(t * 1.2) * 7;

    return Transform.translate(
      offset: Offset(0, moveY),
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.28),
                    _kPrimaryLight.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.34),
                  width: 2,
                ),
              ),
            ),

            ...List.generate(8, (i) {
              final angle = t + i * math.pi / 4;
              final radius = 69 + math.sin(t * 1.4 + i) * 5;

              return Transform.translate(
                offset: Offset(
                  math.cos(angle) * radius,
                  math.sin(angle) * radius,
                ),
                child: Container(
                  width: i.isEven ? 7 : 5,
                  height: i.isEven ? 7 : 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.78),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.55),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              );
            }),

            Positioned(
              top: 28,
              right: 26,
              child: Transform.rotate(
                angle: math.sin(t * 2) * 0.4,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white.withOpacity(0.82),
                  size: 25,
                ),
              ),
            ),

            Positioned(
              left: 24,
              bottom: 42,
              child: Transform.scale(
                scale: 1 + math.sin(t * 2.2) * 0.2,
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white.withOpacity(0.78),
                  size: 17,
                ),
              ),
            ),

            Image.asset(_mascotImage, width: 140, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;

  final _emailFN = FocusNode();
  final _passwordFN = FocusNode();

  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _illuCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _btnScale;

  late List<Animation<double>> _fFade;
  late List<Animation<Offset>> _fSlide;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _fFade = [];
    _fSlide = [];

    for (int i = 0; i < 4; i++) {
      final s = 0.12 + i * 0.12;
      final e = s + 0.30;

      _fFade.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: Interval(s, e.clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
      );

      _fSlide.add(
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: Interval(s, e.clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
      );
    }

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _illuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );

    _btnScale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();

    _emailFN.addListener(() => setState(() {}));
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
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Vnesite email in geslo.', Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );

      if (!mounted) return;
      _snack('Prijava uspešna.', _kPrimary);
    } on FirebaseAuthException catch (e) {
      String msg = 'Prijava ni uspela.';

      if (e.code == 'invalid-email') {
        msg = 'Email naslov ni pravilen.';
      } else if (e.code == 'user-not-found') {
        msg = 'Uporabnik s tem emailom ne obstaja.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'Email ali geslo ni pravilno.';
      }

      _snack(msg, Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
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

  InputDecoration _deco(
    String hint,
    IconData icon,
    FocusNode fn, {
    Widget? suffix,
  }) {
    final focused = fn.hasFocus;

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Icon(
        icon,
        color: focused ? _kPrimary : const Color(0xFFA5B4FC),
        size: 21,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: focused ? const Color(0xFFF0F0FF) : _kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _kBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _kPrimary, width: 2),
      ),
    );
  }

  Widget _lbl(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kText,
        ),
      ),
    );
  }

  Widget _anim(int i, Widget child) {
    return FadeTransition(
      opacity: _fFade[i],
      child: SlideTransition(position: _fSlide[i], child: child),
    );
  }

  Widget _header() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value * 2 * math.pi;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 46, 24, 42),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF08001F),
                Color(0xFF24105F),
                Color(0xFF4F46E5),
                Color(0xFF818CF8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: CustomPaint(painter: _OrbPainter(t))),

              Positioned(
                top: 54,
                left: -110,
                right: -110,
                child: Transform.rotate(
                  angle: -0.36,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(140),
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MascotHeader(t: t),

                  const SizedBox(height: 2),

                  const Text(
                    'Dobrodošli nazaj',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Prijavite se in nadaljujte z uporabo\naplikacije Skills Match.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _hChip(Icons.school_rounded, 'Učenje'),
                      _hChip(Icons.groups_rounded, 'Skupnost'),
                      _hChip(Icons.handshake_rounded, 'Povezovanje'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Transform.translate(
        offset: const Offset(0, -22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            color: _kCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(34),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
              child: Column(
                children: [
                  _anim(
                    0,
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimary, _kViolet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.40),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  _anim(
                    0,
                    const Text(
                      'Prijava',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _kText,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  _anim(
                    0,
                    const Text(
                      'Vnesite svoje podatke za dostop do profila.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _kTextSub),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),

                  _anim(
                    1,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Email'),
                        TextField(
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
                        _lbl('Geslo'),
                        TextField(
                          controller: passwordController,
                          focusNode: _passwordFN,
                          obscureText: !showPassword,
                          decoration: _deco(
                            '••••••••',
                            Icons.lock_outline,
                            _passwordFN,
                            suffix: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _kPrimaryLight,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => showPassword = !showPassword);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  _anim(
                    3,
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
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                              color: isLoading ? const Color(0xFFE2E8F0) : null,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: _kPrimary.withOpacity(0.40),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : login,
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded, size: 20),
                              label: Text(
                                isLoading ? 'Prijavljanje...' : 'Prijavi se',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  _anim(
                    3,
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Nimate računa? ',
                          style: TextStyle(color: _kTextSub, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Registracija →',
                              style: TextStyle(
                                color: _kPrimary,
                                fontWeight: FontWeight.w800,
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
    );
  }

  Widget _illustrationSection() => Container(
    margin: const EdgeInsets.fromLTRB(14, 18, 14, 0),
    child: Column(
      children: [
        Container(
          height: 210,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _orbCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _OrbPainter(_orbCtrl.value * 2 * math.pi),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _illuCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _IllustrationPainter(
                      _illuCtrl.value * 2 * math.pi,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Text(
                    'Skills Match Network',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
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
          ],
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E8F8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
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
                      'Prvič tukaj?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _kText,
                      ),
                    ),
                    Text(
                      'Ustvarite brezplačen račun v 2 minutah.',
                      style: TextStyle(fontSize: 12, color: _kTextSub),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Registracija',
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

        const SizedBox(height: 20),

        Center(
          child: Text(
            '© 2026 Skills Match · Vse pravice pridržane',
            style: TextStyle(fontSize: 11, color: _kTextSub.withOpacity(0.5)),
          ),
        ),

        const SizedBox(height: 14),
      ],
    ),
  );

  Widget _infoCard(
    IconData icon,
    String title,
    String sub,
    Color color,
    Color bg,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 7),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: _kTextSub, height: 1.4),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [_header(), _formCard(), _illustrationSection()],
            ),
          ),
        ),
      ),
    );
  }
}
