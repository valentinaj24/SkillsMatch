import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kP = Color(0xFF4F46E5);
const _kPD = Color(0xFF312E81);
const _kPL = Color(0xFF818CF8);
const _kV = Color(0xFF7C3AED);

const _mascotImages = [
  'assets/images/slika1.png',
  'assets/images/slika2.png',
  'assets/images/slika3.png',
  'assets/images/slika4.png',
  'assets/images/slika5.png',
];

const _appLogo = 'assets/images/slika2.png';

// ─── Orb painter ──────────────────────────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  final double t;

  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final (rx, ry, r, c) in [
      (0.15, 0.12, 120.0, const Color(0x25818CF8)),
      (0.85, 0.08, 90.0, const Color(0x207C3AED)),
      (0.10, 0.85, 100.0, const Color(0x1A4F46E5)),
      (0.88, 0.80, 80.0, const Color(0x18818CF8)),
      (0.50, 0.50, 60.0, const Color(0x107C3AED)),
    ]) {
      final dx = math.sin(t + rx * 4) * 20;
      final dy = math.cos(t + ry * 3) * 16;
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
  bool shouldRepaint(_OrbPainter oldDelegate) => oldDelegate.t != t;
}

// ─── Animated mascot image ────────────────────────────────────────────────────
class _AnimatedMascot extends StatelessWidget {
  final double t;
  final String imagePath;
  final double size;
  final bool showTyping;
  final bool showTapHint;

  const _AnimatedMascot({
    required this.t,
    required this.imagePath,
    this.size = 270,
    this.showTyping = true,
    this.showTapHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final floatY = math.sin(t * 1.4) * 10;
    final rotate = math.sin(t * 1.1) * 0.035;
    final scale = 1 + math.sin(t * 1.8) * 0.025;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1 + math.sin(t) * 0.05,
            child: Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.30),
                    _kPL.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Transform.scale(
            scale: 0.88 + math.sin(t * 1.3) * 0.05,
            child: Container(
              width: size * 0.78,
              height: size * 0.78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 2,
                ),
              ),
            ),
          ),

          ...List.generate(7, (i) {
            final angle = t + i * math.pi / 3.5;
            return Transform.translate(
              offset: Offset(
                math.cos(angle) * size * 0.42,
                math.sin(angle) * size * 0.42,
              ),
              child: Container(
                width: i.isEven ? 8 : 5,
                height: i.isEven ? 8 : 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            );
          }),

          Transform.translate(
            offset: Offset(0, floatY),
            child: Transform.rotate(
              angle: rotate,
              child: Transform.scale(
                scale: scale,
                child: Image.asset(
                  imagePath,
                  width: size,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Positioned(
            top: size * 0.12,
            right: size * 0.13,
            child: Transform.rotate(
              angle: math.sin(t * 2.4) * 0.5,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withOpacity(
                  0.55 + math.sin(t * 2) * 0.35,
                ),
                size: 24,
              ),
            ),
          ),

          Positioned(
            bottom: size * 0.20,
            left: size * 0.12,
            child: Transform.scale(
              scale: 1 + math.sin(t * 2.2) * 0.25,
              child: Icon(
                Icons.star_rounded,
                color: Colors.white.withOpacity(0.70),
                size: 16,
              ),
            ),
          ),

          if (showTyping)
            Positioned(
              bottom: size * 0.08,
              right: size * 0.04,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final opacity =
                        0.35 + 0.65 * ((math.sin(t * 3 + i) + 1) / 2);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _kP.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ),

          
        ],
      ),
    );
  }
}

// ─── Animated app logo ────────────────────────────────────────────────────────
class _AnimatedAppLogo extends StatelessWidget {
  final double t;
  final double size;

  const _AnimatedAppLogo({
    required this.t,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 1 + math.sin(t * 1.7) * 0.035;
    final rotate = math.sin(t * 1.2) * 0.025;

    return SizedBox(
      width: size * 1.35,
      height: size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1 + math.sin(t) * 0.08,
            child: Container(
              width: size * 1.22,
              height: size * 1.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.30),
                    _kPL.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          ...List.generate(6, (i) {
            final angle = t + i * math.pi / 3;
            return Transform.translate(
              offset: Offset(
                math.cos(angle) * size * 0.65,
                math.sin(angle) * size * 0.65,
              ),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            );
          }),

          Transform.rotate(
            angle: rotate,
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                _appLogo,
                width: size,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPLASH SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _progressCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );

    _logoFade = CurvedAnimation(
      parent: _logoCtrl,
      curve: Curves.easeOut,
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textFade = CurvedAnimation(
      parent: _textCtrl,
      curve: Curves.easeOut,
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );

    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeInOut,
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    _go();
  }

  Future<void> _go() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    // OVO OBRIŠI KAD ZAVRŠIŠ TESTIRANJE:
    await prefs.remove('onboarding_seen');

    final seen = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => seen
            ? widget.nextScreen
            : OnboardingScreen(nextScreen: widget.nextScreen),
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(opacity: a, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _orbCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  String _progressLabel(double v) {
    if (v < 0.3) return 'Nalaganje...';
    if (v < 0.6) return 'Preverjanje računa...';
    if (v < 0.9) return 'Pripravljamo skupnost...';
    return 'Pripravljeno!';
  }

  @override
Widget build(BuildContext context) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  return Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/slika11.jpeg',
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          bottom: 85,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _textFade,
            child: Column(
              children: [
                SizedBox(
                  width: 190,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) {
                        return Stack(
                          children: [
                            Container(
                              height: 4,
                              color: Colors.white.withOpacity(0.28),
                            ),
                            FractionallySizedBox(
                              widthFactor: _progressAnim.value,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kPL, Colors.white],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) {
                    return Text(
                      _progressLabel(_progressAnim.value),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING DATA
// ═══════════════════════════════════════════════════════════════════════════════
class _OBData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<_Feat> features;

  const _OBData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.features,
  });
}

class _Feat {
  final IconData icon;
  final String text;

  const _Feat(this.icon, this.text);
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  final Widget nextScreen;

  const OnboardingScreen({super.key, required this.nextScreen});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _ctrl = PageController();
  int _page = 0;

  late AnimationController _orbCtrl;

  static const _pages = [
    _OBData(
      title: 'Skills Match',
      subtitle: 'Dobrodošli!',
      description:
          'Platforma, ki združuje generacije skozi izmenjavo znanja, veščin in izkušenj.',
      icon: Icons.hub_rounded,
      gradient: [
        Color(0xFF1E1B4B),
        Color(0xFF3730A3),
        Color(0xFF4F46E5),
      ],
      features: [
        _Feat(Icons.people_alt_rounded, 'Poveži se z drugimi'),
        _Feat(Icons.auto_awesome_rounded, 'Izmenjuj znanje'),
        _Feat(Icons.security_rounded, 'Zaupanja vredna skupnost'),
      ],
    ),
    _OBData(
      title: 'Ponudi svoje znanje',
      subtitle: 'Postani mentor',
      description:
          'Imaš veščine ali izkušnje? Deli jih z drugimi! Ustvari profil in se poveži.',
      icon: Icons.volunteer_activism_rounded,
      gradient: [
        Color(0xFF312E81),
        Color(0xFF7C3AED),
        Color(0xFF818CF8),
      ],
      features: [
        _Feat(Icons.badge_rounded, 'Ustvari profil'),
        _Feat(Icons.star_rounded, 'Dodaj svoje veščine'),
        _Feat(Icons.school_rounded, 'Poučuj druge'),
      ],
    ),
    _OBData(
      title: 'Nauči se novega',
      subtitle: 'Najdi mentorja',
      description:
          'Poišči pravega mentorja glede na veščine, lokacijo in razpoložljivost.',
      icon: Icons.school_rounded,
      gradient: [
        Color(0xFF1E1B4B),
        Color(0xFF0891B2),
        Color(0xFF818CF8),
      ],
      features: [
        _Feat(Icons.search_rounded, 'Išči po veščinah'),
        _Feat(Icons.location_on_rounded, 'Filtriraj po lokaciji'),
        _Feat(Icons.schedule_rounded, 'Prilagodi razpoložljivost'),
      ],
    ),
    _OBData(
      title: 'Poveži generacije',
      subtitle: 'Skupaj rastemo',
      description:
          'Skills Match je most med generacijami. Mladi in starejši skupaj gradijo skupnost.',
      icon: Icons.diversity_3_rounded,
      gradient: [
        Color(0xFF312E81),
        Color(0xFF059669),
        Color(0xFF4F46E5),
      ],
      features: [
        _Feat(Icons.handshake_rounded, 'Sodeluj z drugimi'),
        _Feat(Icons.verified_rounded, 'Preverjeni profili'),
        _Feat(Icons.trending_up_rounded, 'Rasči z vsako izkušnjo'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      HapticFeedback.selectionClick();
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      HapticFeedback.selectionClick();
      _ctrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();

    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_seen', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(opacity: a, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  String _pageImage(int idx) {
  if (idx == 0) return _mascotImages[1]; 
  if (idx == 1) return _mascotImages[4]; 
  if (idx == 2) return _mascotImages[2]; 
  if (idx == 3) return _mascotImages[3]; 
  return _mascotImages[1];
}

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: _pages.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _page = i);
            },
            itemBuilder: (_, i) => _buildPage(_pages[i], i),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OBData data, int idx) {
  return AnimatedBuilder(
    animation: _orbCtrl,
    builder: (_, __) {
      final t = _orbCtrl.value * 2 * math.pi;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _OrbPainter(t),
              ),
            ),

            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 145),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _page < _pages.length - 1
                            ? GestureDetector(
                                onTap: _finish,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: const Text(
                                    'Preskoči',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(height: 34),
                      ),

                      const SizedBox(height: 4),

                      TweenAnimationBuilder<double>(
                        key: ValueKey('visual-$idx'),
                        tween: Tween(begin: 0.4, end: 1.0),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) {
                          return Transform.scale(scale: v, child: child);
                        },
                        child: _AnimatedMascot(
                          t: t + idx,
                          imagePath: _pageImage(idx),
                          size: 155,
                          showTyping: idx == 2,
                          showTapHint: false,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TweenAnimationBuilder<double>(
                        key: ValueKey('sub-$idx'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (_, v, child) {
                          return Opacity(opacity: v, child: child);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            data.subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TweenAnimationBuilder<double>(
                        key: ValueKey('ttl-$idx'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOut,
                        builder: (_, v, child) {
                          return Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - v)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TweenAnimationBuilder<double>(
                        key: ValueKey('dsc-$idx'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 480),
                        curve: Curves.easeOut,
                        builder: (_, v, child) {
                          return Opacity(opacity: v, child: child);
                        },
                        child: Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TweenAnimationBuilder<double>(
                        key: ValueKey('fts-$idx'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOut,
                        builder: (_, v, child) {
                          return Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - v)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: data.features.asMap().entries.map((e) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: e.key < data.features.length - 1
                                      ? 10
                                      : 0,
                                ),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1 + math.sin(t + e.key) * 0.035,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.white.withOpacity(0.18),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.20),
                                          ),
                                        ),
                                        child: Icon(
                                          e.value.icon,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        e.value.text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildControls() {
    final isLast = _page == _pages.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.35),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page
                      ? Colors.white
                      : Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              AnimatedOpacity(
                opacity: _page > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _back,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _next,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: 52,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLast ? 28 : 22,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'Začni z aplikacijo' : 'Naprej',
                        style: const TextStyle(
                          color: _kPD,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLast
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        color: _kPD,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}