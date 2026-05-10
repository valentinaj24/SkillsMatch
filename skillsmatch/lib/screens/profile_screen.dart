import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryDark = Color(0xFF312E81);
const _kPrimaryLight = Color(0xFF818CF8);
const _kViolet = Color(0xFF7C3AED);
const _kSurface = Color(0xFFF5F5FF);
const _kCardBg = Color(0xFFFFFFFF);
const _kBg = Color(0xFFF0F0FF);
const _kBorder = Color(0xFFCBD5E1);
const _kText = Color(0xFF1E1B4B);
const _kTextSub = Color(0xFF6B7280);

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final (rx, ry, r, color) in [
      (0.10, 0.20, 80.0, const Color(0x35818CF8)),
      (0.85, 0.10, 58.0, const Color(0x307C3AED)),
      (0.60, 0.82, 65.0, const Color(0x284F46E5)),
      (0.92, 0.55, 44.0, const Color(0x22818CF8)),
      (0.25, 0.88, 50.0, const Color(0x307C3AED)),
    ]) {
      final dx = math.sin(t + rx * 5) * 14;
      final dy = math.cos(t + ry * 4) * 11;
      final cx = size.width * rx + dx;
      final cy = size.height * ry + dy;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter o) => o.t != t;
}

// ─── Animated empty skills state ─────────────────────────────────────────────
class _EmptySkills extends StatefulWidget {
  const _EmptySkills();
  @override
  State<_EmptySkills> createState() => _EmptySkillsState();
}

class _EmptySkillsState extends State<_EmptySkills>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kViolet, _kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dodajte vsaj eno veščino',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _kText,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'ki jo ponujate ali se je želite naučiti.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextSub, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final imeController = TextEditingController();
  final priimekController = TextEditingController();
  final opisController = TextEditingController();
  final lokacijaController = TextEditingController();
  final vescinaController = TextEditingController();

  String razpolozljivost = 'Dopoldan';
  String nivoZnanja = 'Začetnik';
  String tipVescine = 'Želim se naučiti';

  final List<Skill> vescine = [];
  bool isSaving = false;

  final _imeFN = FocusNode();
  final _priimekFN = FocusNode();
  final _opisFN = FocusNode();
  final _lokacijaFN = FocusNode();
  final _vescinaFN = FocusNode();

  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _btnCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _btnScale;
  late List<Animation<double>> _secFade;
  late List<Animation<Offset>> _secSlide;

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
    _secFade = [];
    _secSlide = [];
    for (int i = 0; i < 3; i++) {
      final s = (0.10 + i * 0.15).clamp(0.0, 0.9);
      final e = (s + 0.30).clamp(0.0, 1.0);
      _secFade.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: Interval(s, e, curve: Curves.easeOut),
          ),
        ),
      );
      _secSlide.add(
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
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
    _entryCtrl.forward();
    for (final fn in [_imeFN, _priimekFN, _opisFN, _lokacijaFN, _vescinaFN]) {
      fn.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    _btnCtrl.dispose();
    for (final c in [
      imeController,
      priimekController,
      opisController,
      lokacijaController,
      vescinaController,
    ]) {
      c.dispose();
    }
    for (final f in [_imeFN, _priimekFN, _opisFN, _lokacijaFN, _vescinaFN]) {
      f.dispose();
    }
    super.dispose();
  }

  void dodajVescino() {
    if (vescinaController.text.trim().isEmpty) return;
    setState(() {
      vescine.add(
        Skill(
          naziv: vescinaController.text.trim(),
          nivoZnanja: nivoZnanja,
          tip: tipVescine,
        ),
      );
      vescinaController.clear();
    });
    _snack('Veščina je bila dodana.', _kPrimary);
  }

  Future<void> potrdiBrisanje(Skill skill) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: _kCardBg,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Izbriši veščino?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ali želite odstraniti veščino "${skill.naziv}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextSub, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextSub,
                        side: const BorderSide(color: _kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Prekliči'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.delete_rounded, size: 18),
                      label: const Text('Izbriši'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
    if (result == true) setState(() => vescine.remove(skill));
  }

  Future<void> shraniProfil() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null)
        throw Exception('Za ustvarjanje profila se morate prijaviti.');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'ime': imeController.text.trim(),
        'priimek': priimekController.text.trim(),
        'opis': opisController.text.trim(),
        'lokacija': lokacijaController.text.trim(),
        'razpolozljivost': razpolozljivost,
        'vescine': vescine
            .map(
              (s) => {
                'naziv': s.naziv,
                'nivoZnanja': s.nivoZnanja,
                'tip': s.tip,
              },
            )
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      _prikaziUspeh();
    } catch (e) {
      if (!mounted) return;
      _snack('Napaka pri shranjevanju: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _snack(
    String msg,
    Color color,
  ) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ),
  );

  void _prikaziUspeh() => showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
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
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Profil shranjen!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _kPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vaši podatki so bili uspešno posodobljeni.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kTextSub, height: 1.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'V redu',
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

  InputDecoration _deco(
    String hint,
    IconData icon,
    FocusNode fn, {
    int? maxLines,
  }) {
    final focused = fn.hasFocus;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(
          bottom: maxLines != null && maxLines > 1 ? 48 : 0,
        ),
        child: Icon(
          icon,
          color: focused ? _kPrimary : const Color(0xFFA5B4FC),
          size: 20,
        ),
      ),
      filled: true,
      fillColor: focused ? const Color(0xFFF0F0FF) : _kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kBorder, width: 1.2),
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _kText,
      ),
    ),
  );

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _secFade[i],
    child: SlideTransition(position: _secSlide[i], child: child),
  );

  Widget _sectionHeader(String title, IconData icon, Color accent) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _kText,
        ),
      ),
    ],
  );

  Widget _header() => AnimatedBuilder(
    animation: _orbCtrl,
    builder: (_, __) {
      final t = _orbCtrl.value * 2 * math.pi;

      return Container(
        width: double.infinity,
        height: 355,
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 30),
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
          children: [
            // BACKGROUND ORBS
            Positioned.fill(child: CustomPaint(painter: _OrbPainter(t))),

            // RAKUN + KRUG
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 125,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // KRUG
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                          width: 1.2,
                        ),
                      ),
                    ),

                    // ZVEZDICA
                    Transform.translate(
                      offset: Offset(math.sin(t) * 34, math.cos(t) * 14),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white.withOpacity(0.75),
                        size: 14,
                      ),
                    ),

                    // TACKICA
                    Transform.translate(
                      offset: Offset(
                        math.sin(t * 1.4) * -34,
                        math.cos(t * 1.4) * 16,
                      ),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // RAKUN
                    Transform.translate(
                      offset: Offset(0, math.sin(t) * 4),
                      child: Image.asset(
                        'assets/images/rakun.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // NASLOV + OPIS
            Positioned(
              left: 0,
              right: 0,
              top: 145,
              child: Column(
                children: [
                  const Text(
                    'Skills Match',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Ustvari profil, dodaj svoje veščine in\npoveži generacije skozi znanje.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // BUTTONS
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statPill(Icons.star_rounded, '${vescine.length} veščin'),

                  const SizedBox(width: 8),

                  _statPill(Icons.schedule_rounded, razpolozljivost),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _statPill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _skillCard(Skill skill, int index) {
    final canTeach = skill.tip == 'Lahko učim druge';
    final color = canTeach ? _kPrimary : const Color(0xFFD97706);
    final bg = canTeach ? const Color(0xFFEEF2FF) : const Color(0xFFFFFBEB);
    final border = canTeach ? const Color(0xFFC7D2FE) : const Color(0xFFFDE68A);
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + index * 70),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canTeach
                      ? [_kPrimary, _kViolet]
                      : [const Color(0xFFD97706), const Color(0xFFF59E0B)],
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
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.naziv,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          skill.nivoZnanja,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          skill.tip,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _kTextSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => potrdiBrisanje(skill),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(String tip, IconData icon, Color color, Color bg) {
    final sel = tipVescine == tip;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tipVescine = tip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: sel ? bg : _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? color : _kBorder,
              width: sel ? 2 : 1.2,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.14) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: sel ? color : const Color(0xFFA5B4FC),
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tip,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  color: sel ? color : _kTextSub,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? color : Colors.transparent,
                  border: Border.all(color: sel ? color : _kBorder, width: 1.5),
                ),
                child: sel
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _anim(
                        0,
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: Card(
                            elevation: 14,
                            shadowColor: _kPrimary.withOpacity(0.12),
                            color: _kCardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionHeader(
                                    'Osnovni podatki',
                                    Icons.person_rounded,
                                    _kPrimary,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _lbl('Ime *'),
                                            TextFormField(
                                              controller: imeController,
                                              focusNode: _imeFN,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: _deco(
                                                'Janez',
                                                Icons.badge_outlined,
                                                _imeFN,
                                              ),
                                              validator: (v) =>
                                                  v == null || v.trim().isEmpty
                                                  ? 'Vnesite ime'
                                                  : null,
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
                                            TextFormField(
                                              controller: priimekController,
                                              focusNode: _priimekFN,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: _deco(
                                                'Novak',
                                                Icons.person_outline,
                                                _priimekFN,
                                              ),
                                              validator: (v) =>
                                                  v == null || v.trim().isEmpty
                                                  ? 'Vnesite priimek'
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _lbl('Kratek opis'),
                                  TextFormField(
                                    controller: opisController,
                                    focusNode: _opisFN,
                                    maxLines: 3,
                                    decoration: _deco(
                                      'Opišite se v nekaj besedah...',
                                      Icons.description_outlined,
                                      _opisFN,
                                      maxLines: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _lbl('Lokacija *'),
                                  TextFormField(
                                    controller: lokacijaController,
                                    focusNode: _lokacijaFN,
                                    decoration: _deco(
                                      'Ljubljana, Slovenija',
                                      Icons.location_on_outlined,
                                      _lokacijaFN,
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Vnesite lokacijo'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _lbl('Razpoložljivost'),
                                  DropdownButtonFormField<String>(
                                    value: razpolozljivost,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.schedule_outlined,
                                        color: Color(0xFFA5B4FC),
                                        size: 20,
                                      ),
                                      filled: true,
                                      fillColor: _kSurface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: _kBorder,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: _kPrimary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.expand_more,
                                      color: Color(0xFFA5B4FC),
                                    ),
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(
                                      color: _kText,
                                      fontSize: 15,
                                    ),
                                    items:
                                        [
                                              'Dopoldan',
                                              'Popoldan',
                                              'Zvečer',
                                              'Vikend',
                                            ]
                                            .map(
                                              (v) => DropdownMenuItem(
                                                value: v,
                                                child: Text(v),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) =>
                                        setState(() => razpolozljivost = v!),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _anim(
                        1,
                        Card(
                          elevation: 14,
                          shadowColor: _kViolet.withOpacity(0.12),
                          color: _kCardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader(
                                  'Veščine',
                                  Icons.auto_awesome_rounded,
                                  _kViolet,
                                ),
                                const SizedBox(height: 20),
                                _lbl('Nova veščina'),
                                TextFormField(
                                  controller: vescinaController,
                                  focusNode: _vescinaFN,
                                  decoration: _deco(
                                    'Vnesite veščino',
                                    Icons.star_outline_rounded,
                                    _vescinaFN,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _lbl('Nivo znanja'),
                                DropdownButtonFormField<String>(
                                  value: nivoZnanja,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.trending_up_rounded,
                                      color: Color(0xFFA5B4FC),
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: _kSurface,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: _kBorder,
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: _kPrimary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.expand_more,
                                    color: Color(0xFFA5B4FC),
                                  ),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    color: _kText,
                                    fontSize: 15,
                                  ),
                                  items:
                                      [
                                            'Začetnik',
                                            'Srednji nivo',
                                            'Napredni nivo',
                                            'Strokovnjak',
                                          ]
                                          .map(
                                            (v) => DropdownMenuItem(
                                              value: v,
                                              child: Text(v),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) =>
                                      setState(() => nivoZnanja = v!),
                                ),
                                const SizedBox(height: 14),
                                _lbl('Tip veščine'),
                                Row(
                                  children: [
                                    _tipCard(
                                      'Želim se naučiti',
                                      Icons.school_rounded,
                                      const Color(0xFFD97706),
                                      const Color(0xFFFFFBEB),
                                    ),
                                    const SizedBox(width: 10),
                                    _tipCard(
                                      'Lahko učim druge',
                                      Icons.volunteer_activism_rounded,
                                      _kPrimary,
                                      const Color(0xFFEEF2FF),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _kPrimary,
                                        width: 1.8,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: OutlinedButton.icon(
                                      onPressed: dodajVescino,
                                      icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Dodaj veščino',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _kPrimary,
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Empty state ali seznam veščin ──────────────────
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: vescine.isEmpty
                                      ? const _EmptySkills() // ← animiran empty state
                                      : Column(
                                          key: const ValueKey('skills'),
                                          children: vescine
                                              .asMap()
                                              .entries
                                              .map(
                                                (e) =>
                                                    _skillCard(e.value, e.key),
                                              )
                                              .toList(),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _anim(
                        2,
                        GestureDetector(
                          onTapDown: (_) => _btnCtrl.forward(),
                          onTapUp: (_) => _btnCtrl.reverse(),
                          onTapCancel: () => _btnCtrl.reverse(),
                          child: ScaleTransition(
                            scale: _btnScale,
                            child: SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: isSaving
                                      ? null
                                      : const LinearGradient(
                                          colors: [_kPrimary, _kViolet],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                  color: isSaving
                                      ? const Color(0xFFE2E8F0)
                                      : null,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: isSaving
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: _kPrimary.withOpacity(0.42),
                                            blurRadius: 18,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: isSaving ? null : shraniProfil,
                                  icon: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_alt_rounded,
                                          size: 20,
                                        ),
                                  label: Text(
                                    isSaving
                                        ? 'Shranjevanje...'
                                        : 'Shrani profil',
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
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
}
