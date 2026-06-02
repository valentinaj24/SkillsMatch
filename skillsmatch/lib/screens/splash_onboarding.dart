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
    this.size = 200,
    this.showTyping = true,
  });

  @override
  Widget build(BuildContext context) {
    final floatY = math.sin(t * 1.4) * 8;
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
                    Colors.white.withOpacity(0.24),
                    _kPL.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Transform.scale(
            scale: 0.88 + math.sin(t * 1.3) * 0.04,
            child: Container(
              width: size * 0.78,
              height: size * 0.78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1.5,
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
                width: i.isEven ? 7 : 4,
                height: i.isEven ? 7 : 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.70),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.40),
                      blurRadius: 10,
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
                color: Colors.white.withOpacity(0.50 + math.sin(t * 2) * 0.35),
                size: 20,
              ),
            ),
          ),

          if (showTyping)
            Positioned(
              bottom: size * 0.08,
              right: size * 0.04,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
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
                      width: 5,
                      height: 5,
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
    await _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    await _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    await _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    await _go();
  }

  Future<void> _go() async {
  if (!mounted) return;

  final prefs = await SharedPreferences.getInstance();

  final seen = prefs.getBool('onboarding_seen') ?? false;

  if (!mounted) return;

  await Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => seen
          ? widget.nextScreen
          : OnboardingScreen(nextScreen: widget.nextScreen),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
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
                        builder: (_, __) => Stack(
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
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => Text(
                      _progressLabel(_progressAnim.value),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
    await HapticFeedback.mediumImpact();

    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_seen', true);

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = constraints.maxHeight;
        final isSmall = screenH < 700;

        final mascotSize = isSmall ? 150.0 : 205.0;
        final titleSize = isSmall ? 27.0 : 34.0;
        final subtitleSize = isSmall ? 11.0 : 12.0;
        final descSize = isSmall ? 12.0 : 13.5;

        final featureTileH = isSmall ? 68.0 : 78.0;
        final featureIconSize = isSmall ? 20.0 : 24.0;
        final featureTitleSize = isSmall ? 13.5 : 15.5;
        final featureSubSize = isSmall ? 11.0 : 12.0;

        return AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) {
            final t = _orbCtrl.value * 2 * math.pi;
            final heroMove = math.sin(t * 0.9) * 5;

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
                    top: -120,
                    right: -120,
                    child: _glow(data.accent, 340, 0.48),
                  ),

                  Positioned(
                    bottom: 60,
                    left: -150,
                    child: _glow(data.accent, 340, 0.26),
                  ),

                  Positioned(
                    top: screenH * 0.18,
                    left: -80,
                    right: -80,
                    child: Transform.rotate(
                      angle: -0.42,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(120),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.01),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 145),
                      child: Column(
                        children: [
                          _topBar(data),

                          SizedBox(height: isSmall ? 6 : 12),

                          Transform.translate(
                            offset: Offset(0, heroMove),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey('hero-$idx'),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - v)),
                                  child: child,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _glow(data.accent, mascotSize * 1.18, 0.50),

                                  Container(
                                    width: mascotSize * 1.05,
                                    height: mascotSize * 1.05,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.20),
                                        width: 1.5,
                                      ),
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.12),
                                          data.accent.withOpacity(0.08),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),

                                  _AnimatedMascot(
                                    t: t + idx,
                                    imagePath: _pageImage(idx),
                                    size: mascotSize,
                                    showTyping: idx == 2,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isSmall ? 14 : 20),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: isSmall ? 5 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.26),
                              ),
                            ),
                            child: Text(
                              data.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                          SizedBox(height: isSmall ? 8 : 10),

                          Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleSize,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),

                          SizedBox(height: isSmall ? 8 : 10),

                          Text(
                            data.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontSize: descSize,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: isSmall ? 16 : 22),

                          ...data.features.asMap().entries.map((e) {
                            final f = e.value;

                            return TweenAnimationBuilder<double>(
                              key: ValueKey('feature-$idx-${e.key}'),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 500 + e.key * 90,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - v)),
                                  child: child,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: isSmall ? 9 : 12,
                                ),
                                child: _featureTile(
                                  data,
                                  f,
                                  tileHeight: featureTileH,
                                  iconSize: featureIconSize,
                                  titleSize: featureTitleSize,
                                  subSize: featureSubSize,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
            key: const Key('skip-btn'),
            onTap: _finish, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: const Text(
                'Preskoči',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _featureTile(
    _OBData data,
    _Feat feature, {
    required double tileHeight,
    required double iconSize,
    required double titleSize,
    required double subSize,
  }) {
    return Container(
      width: double.infinity,
      height: tileHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.082),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: data.accent.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: tileHeight * 0.60,
            height: tileHeight * 0.60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.accent.withOpacity(0.95),
                  const Color(0xFF4C1D95).withOpacity(0.82),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: data.accent.withOpacity(0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(feature.icon, color: Colors.white, size: iconSize),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  feature.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: subSize,
                    height: 1.22,
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
            color.withOpacity(opacity * 0.30),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final isLast = _page == _pages.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.48)],
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
                width: i == _page ? 30 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page
                      ? Colors.white
                      : Colors.white.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              AnimatedOpacity(
                opacity: _page > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _page > 0 ? _back : null,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.26)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _next,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFEDE9FE)],
                    ),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.38),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
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
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Icon(
                        isLast
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        color: _kPD,
                        size: 20,
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
