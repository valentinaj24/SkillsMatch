import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kP = Color(0xFF4F46E5);
const _kPD = Color(0xFF312E81);
const _kPL = Color(0xFF818CF8);

const _mascotImages = [
  'assets/images/slika1.png',
  'assets/images/slika2.png',
  'assets/images/slika3.png',
  'assets/images/slika4.png',
  'assets/images/slika5.png',
];

const _appLogo = 'assets/images/slika2.png';

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

class _AnimatedMascot extends StatelessWidget {
  final double t;
  final String imagePath;
  final double size;
  final bool showTyping;

  const _AnimatedMascot({
    required this.t,
    required this.imagePath,
    this.size = 270,
    this.showTyping = true,
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
              width: size * 0.95,
              height: size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.28),
                    _kPL.withOpacity(0.16),
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
                  color: Colors.white.withOpacity(0.24),
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
                child: Image.asset(imagePath, width: size, fit: BoxFit.contain),
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
                color: Colors.white.withOpacity(0.55 + math.sin(t * 2) * 0.35),
                size: 24,
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

class _AnimatedAppLogo extends StatelessWidget {
  final double t;
  final double size;

  const _AnimatedAppLogo({required this.t, this.size = 150});

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
          Transform.rotate(
            angle: rotate,
            child: Transform.scale(
              scale: scale,
              child: Image.asset(_appLogo, width: size, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

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

    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

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
            child: Image.asset('assets/images/slika11.jpeg', fit: BoxFit.cover),
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

class _OBData {
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final Color accent;
  final IconData mainIcon;
  final List<_Feat> features;

  const _OBData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.accent,
    required this.mainIcon,
    required this.features,
  });
}

class _Feat {
  final IconData icon;
  final String title;
  final String text;

  const _Feat(this.icon, this.title, this.text);
}

class OnboardingScreen extends StatefulWidget {
  final Widget nextScreen;

  const OnboardingScreen({super.key, required this.nextScreen});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _ctrl = PageController();
  int _page = 0;

  late AnimationController _orbCtrl;

  static const _pages = [
    _OBData(
      title: 'Skills Match',
      subtitle: 'Dobrodošli v skupnosti',
      description:
          'Odkrij prostor, kjer se znanje, izkušnje in ljudje povežejo v eno pametno skupnost.',
      gradient: [
        Color(0xFF05001A),
        Color(0xFF180044),
        Color(0xFF3B0A78),
        Color(0xFF6D28D9),
      ],
      accent: Color(0xFFA855F7),
      mainIcon: Icons.hub_rounded,
      features: [
        _Feat(
          Icons.groups_rounded,
          'Povezovanje uporabnikov',
          'Poveži se z ljudmi, ki delijo tvoje interese.',
        ),
        _Feat(
          Icons.auto_awesome_rounded,
          'Pametna izmenjava znanja',
          'Deli znanje, uči se in rasti vsak dan.',
        ),
        _Feat(
          Icons.verified_user_rounded,
          'Varna skupnost',
          'Zaupanja vredno okolje za vse generacije.',
        ),
      ],
    ),
    _OBData(
      title: 'Ponudi svoje znanje',
      subtitle: 'Tvoje veščine imajo vrednost',
      description:
          'Predstavi se kot mentor, izpostavi svoje izkušnje in pomagaj drugim napredovati.',
      gradient: [
        Color(0xFF08001F),
        Color(0xFF260057),
        Color(0xFF5B21B6),
        Color(0xFF9333EA),
      ],
      accent: Color(0xFFC084FC),
      mainIcon: Icons.workspace_premium_rounded,
      features: [
        _Feat(
          Icons.badge_rounded,
          'Premium profil',
          'Uredi predstavitev, ki jasno pokaže tvoje znanje.',
        ),
        _Feat(
          Icons.star_rounded,
          'Izpostavljene veščine',
          'Dodaj področja, v katerih lahko pomagaš drugim.',
        ),
        _Feat(
          Icons.school_rounded,
          'Mentorstvo drugim',
          'Postani oseba, od katere se skupnost lahko uči.',
        ),
      ],
    ),
    _OBData(
      title: 'Nauči se novega',
      subtitle: 'Znanje, ki ti je bližje',
      description:
          'Poišči mentorja po veščinah, lokaciji in razpoložljivosti ter začni napredovati.',
      gradient: [
        Color(0xFF020617),
        Color(0xFF082F49),
        Color(0xFF0369A1),
        Color(0xFF0EA5E9),
      ],
      accent: Color(0xFF67E8F9),
      mainIcon: Icons.travel_explore_rounded,
      features: [
        _Feat(
          Icons.manage_search_rounded,
          'Pametno iskanje',
          'Hitro najdi znanje, ki ga trenutno potrebuješ.',
        ),
        _Feat(
          Icons.location_on_rounded,
          'Iskanje po lokaciji',
          'Poveži se z mentorji v svoji bližini.',
        ),
        _Feat(
          Icons.schedule_rounded,
          'Ujemanje po času',
          'Izberi osebe, ki imajo podobno razpoložljivost.',
        ),
      ],
    ),
    _OBData(
      title: 'Poveži generacije',
      subtitle: 'Skupnost, ki raste skupaj',
      description:
          'Mladi in starejši delijo izkušnje, gradijo zaupanje in ustvarjajo močnejšo skupnost.',
      gradient: [
        Color(0xFF021A22),
        Color(0xFF064E3B),
        Color(0xFF047857),
        Color(0xFF3730A3),
      ],
      accent: Color(0xFF6EE7B7),
      mainIcon: Icons.diversity_3_rounded,
      features: [
        _Feat(
          Icons.handshake_rounded,
          'Medgeneracijsko sodelovanje',
          'Poveži različne izkušnje, znanje in poglede.',
        ),
        _Feat(
          Icons.verified_rounded,
          'Preverjeni profili',
          'Več zaupanja pri vsakem novem stiku.',
        ),
        _Feat(
          Icons.trending_up_rounded,
          'Osebna rast',
          'Vsaka izmenjava je nova priložnost za napredek.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  String _pageImage(int idx) {
    if (idx == 0) return _mascotImages[1];
    if (idx == 1) return _mascotImages[4];
    if (idx == 2) return _mascotImages[2];
    if (idx == 3) return _mascotImages[3];
    return _mascotImages[1];
  }

  void _next() {
    if (_page < _pages.length - 1) {
      HapticFeedback.selectionClick();
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 560),
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
        duration: const Duration(milliseconds: 560),
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
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
          Positioned(bottom: 0, left: 0, right: 0, child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildPage(_OBData data, int idx) {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value * 2 * math.pi;
        final heroMove = math.sin(t * 0.9) * 6;

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
              Positioned.fill(child: CustomPaint(painter: _OrbPainter(t))),

              Positioned(
                top: -165,
                right: -155,
                child: _glow(data.accent, 430, 0.52),
              ),
              Positioned(
                bottom: 40,
                left: -190,
                child: _glow(data.accent, 430, 0.30),
              ),

              Positioned(
                top: 145,
                left: -110,
                right: -110,
                child: Transform.rotate(
                  angle: -0.42,
                  child: Container(
                    height: 145,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(140),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.012),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 132),
                  child: Column(
                    children: [
                      _topBar(data),
                      const SizedBox(height: 8),

                      Expanded(
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: Offset(0, heroMove),
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey('hero-$idx'),
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 780),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, child) {
                                  return Opacity(
                                    opacity: v,
                                    child: Transform.translate(
                                      offset: Offset(0, 24 * (1 - v)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        _glow(data.accent, 235, 0.56),
                                        Container(
                                          width: 210,
                                          height: 210,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.22,
                                              ),
                                              width: 2,
                                            ),
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.15),
                                                data.accent.withOpacity(0.10),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                        _AnimatedMascot(
                                          t: t + idx,
                                          imagePath: _pageImage(idx),
                                          size: 195,
                                          showTyping: idx == 2,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 17,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(40),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.28),
                                        ),
                                      ),
                                      child: Text(
                                        data.subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 13),

                                    Text(
                                      data.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 37,
                                        height: 1.0,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.3,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Text(
                                        data.description,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.80),
                                          fontSize: 14.3,
                                          height: 1.36,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: data.features.asMap().entries.map((
                                  e,
                                ) {
                                  final f = e.value;

                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey('feature-$idx-${e.key}'),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds: 560 + e.key * 100,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, child) {
                                      return Opacity(
                                        opacity: v,
                                        child: Transform.translate(
                                          offset: Offset(0, 18 * (1 - v)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 11,
                                      ),
                                      child: _featureTile(data, f),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar(_OBData data) {
    return Row(
      children: [
        const Spacer(),
        if (_page < _pages.length - 1)
          GestureDetector(
            onTap: _finish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: const Text(
                'Preskoči',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _featureTile(_OBData data, _Feat feature) {
    return Container(
      width: double.infinity,
      height: 86,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.082),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: data.accent.withOpacity(0.13),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.accent.withOpacity(0.98),
                  const Color(0xFF4C1D95).withOpacity(0.86),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: data.accent.withOpacity(0.42),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(feature.icon, color: Colors.white, size: 27),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.2,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  feature.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12.8,
                    height: 1.23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.32),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final isLast = _page == _pages.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.50)],
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
                duration: const Duration(milliseconds: 330),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 34 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page
                      ? Colors.white
                      : Colors.white.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              AnimatedOpacity(
                opacity: _page > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _page > 0 ? _back : null,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.28)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _next,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: isLast ? 30 : 30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFEDE9FE)],
                    ),
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.42),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
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
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        isLast
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        color: _kPD,
                        size: 21,
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
