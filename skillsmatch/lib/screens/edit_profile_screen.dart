import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// ─── Color System ──────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryDark = Color(0xFF312E81);
const _kPrimaryLight = Color(0xFF818CF8);
const _kViolet = Color(0xFF7C3AED);
const _kAmber = Color(0xFFD97706);
const _kSurface = Color(0xFFF5F5FF);
const _kCardBg = Color(0xFFFFFFFF);
const _kBg = Color(0xFFF0F0FF);
const _kBorder = Color(0xFFE2E8F0);
const _kText = Color(0xFF1E1B4B);
const _kTextSub = Color(0xFF6B7280);

// ─── Orb Painter ──────────────────────────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final (rx, ry, r, color) in [
      (0.08, 0.18, 80.0, const Color(0x38818CF8)),
      (0.88, 0.08, 58.0, const Color(0x327C3AED)),
      (0.62, 0.82, 65.0, const Color(0x2A4F46E5)),
      (0.92, 0.55, 44.0, const Color(0x22818CF8)),
      (0.22, 0.90, 50.0, const Color(0x307C3AED)),
    ]) {
      final dx = math.sin(t + rx * 5) * 14;
      final dy = math.cos(t + ry * 4) * 11;
      canvas.drawCircle(
        Offset(size.width * rx + dx, size.height * ry + dy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [color, Colors.transparent])
              .createShader(
                Rect.fromCircle(
                  center: Offset(size.width * rx + dx, size.height * ry + dy),
                  radius: r,
                ),
              ),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter o) => o.t != t;
}

// ─── Edit Profile Screen ──────────────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final imeController = TextEditingController();
  final priimekController = TextEditingController();
  final opisController = TextEditingController();
  final lokacijaController = TextEditingController();
  final vescinaController = TextEditingController();

  String razpolozljivost = 'Dopoldan';
  String nivoZnanja = 'Začetnik';
  String tipVescine = 'Lahko učim druge';

  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingImage = false;
  bool _addingSkill = false;
  bool isGettingLocation = false;

  bool showLocation = true;
  bool showDescription = true;
  bool showAvailability = true;
  bool showSkills = true;

  String photoUrl = '';
  File? selectedImage;

  List<Map<String, dynamic>> vescine = [];

  // Focus nodes
  final _imeFN = FocusNode();
  final _priimekFN = FocusNode();
  final _lokacijaFN = FocusNode();
  final _opisFN = FocusNode();
  final _vescinaFN = FocusNode();

  late AnimationController _orbCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _addPanelCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _btnScale;
  late Animation<double> _addPanelAnim;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _btnScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
    _addPanelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _addPanelAnim = CurvedAnimation(
      parent: _addPanelCtrl,
      curve: Curves.easeOutCubic,
    );

    for (final fn in [_imeFN, _priimekFN, _lokacijaFN, _opisFN, _vescinaFN]) {
      fn.addListener(() => setState(() {}));
    }
    naloziProfil();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entryCtrl.dispose();
    _btnCtrl.dispose();
    _addPanelCtrl.dispose();
    for (final c in [
      imeController,
      priimekController,
      opisController,
      lokacijaController,
      vescinaController,
    ]) {
      c.dispose();
    }
    for (final f in [_imeFN, _priimekFN, _lokacijaFN, _opisFN, _vescinaFN]) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Logika (nespremenjena) ─────────────────────────────────────────────────
  Future<void> naloziProfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      setState(() => isLoading = false);
      return;
    }

    final data = doc.data()!;

    final privacy = Map<String, dynamic>.from(data['privacy'] ?? {});

    setState(() {
      imeController.text = data['ime'] ?? '';
      priimekController.text = data['priimek'] ?? '';
      opisController.text = data['opis'] ?? '';
      lokacijaController.text = data['lokacija'] ?? '';
      razpolozljivost = data['razpolozljivost'] ?? 'Dopoldan';
      photoUrl = (data['photoUrl'] ?? '').toString();

      vescine = (data['vescine'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      showLocation = privacy['showLocation'] ?? true;
      showDescription = privacy['showDescription'] ?? true;
      showAvailability = privacy['showAvailability'] ?? true;
      showSkills = privacy['showSkills'] ?? true;

      isLoading = false;
    });

    _entryCtrl.forward();
  }

  Future<void> izberiSliko() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 900,
    );
    if (picked == null) return;
    setState(() => selectedImage = File(picked.path));
  }

  Future<String> uploadProfileImage(String uid) async {
    if (selectedImage == null) return photoUrl;
    setState(() => isUploadingImage = true);
    const cloudName = 'dm4zcxqa4';
    const uploadPreset = 'skillsmatch_upload';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'skillsmatch_profiles'
      ..files.add(
        await http.MultipartFile.fromPath('file', selectedImage!.path),
      );
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    if (response.statusCode != 200 && response.statusCode != 201) {
      setState(() => isUploadingImage = false);
      throw Exception('Cloudinary upload napaka: $responseData');
    }
    final imageUrl = jsonDecode(responseData)['secure_url'].toString();
    setState(() {
      photoUrl = imageUrl;
      isUploadingImage = false;
    });
    return imageUrl;
  }

  void dodajVescino() {
    final naziv = vescinaController.text.trim();
    if (naziv.isEmpty) {
      _snack('Vnesite naziv veščine.', Colors.redAccent);
      return;
    }
    setState(() {
      vescine.add({
        'naziv': naziv,
        'nivoZnanja': nivoZnanja,
        'tip': tipVescine,
      });
      vescinaController.clear();
      nivoZnanja = 'Začetnik';
      tipVescine = 'Lahko učim druge';
      _addingSkill = false;
    });
    _addPanelCtrl.reverse();
    _snack('✓  Veščina dodana!', _kPrimary);
  }

  void odstraniVescino(int index) => setState(() => vescine.removeAt(index));

  Future<void> shraniSpremembe() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('Uporabnik ni prijavljen.', Colors.redAccent);
      return;
    }
    setState(() => isSaving = true);
    try {
      final uploadedUrl = await uploadProfileImage(uid);
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'ime': imeController.text.trim(),
        'priimek': priimekController.text.trim(),
        'opis': opisController.text.trim(),
        'lokacija': lokacijaController.text.trim(),
        'razpolozljivost': razpolozljivost,
        'vescine': vescine,
        'photoUrl': uploadedUrl,

        'privacy': {
          'showLocation': showLocation,
          'showDescription': showDescription,
          'showAvailability': showAvailability,
          'showSkills': showSkills,
        },

        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => isSaving = false);
      _snack('Profil je uspešno posodobljen.', _kPrimary);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        isUploadingImage = false;
      });
      _snack('Napaka pri shranjevanju: $e', Colors.redAccent);
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
      if (mounted) {
        setState(() => isGettingLocation = false);
      }
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

  void _toggleAdd() {
    setState(() => _addingSkill = !_addingSkill);
    _addingSkill ? _addPanelCtrl.forward() : _addPanelCtrl.reverse();
  }

  // ── Input decoration ───────────────────────────────────────────────────────
  InputDecoration _deco(
    String hint,
    IconData icon,
    FocusNode fn, {
    bool multiline = false,
  }) {
    final focused = fn.hasFocus;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: multiline ? 52 : 0),
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

  InputDecoration _dropDeco(IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: const Color(0xFFA5B4FC), size: 20),
    filled: true,
    fillColor: _kSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kBorder, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kPrimary, width: 2),
    ),
  );

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

  // ── Section card ───────────────────────────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _kBorder),
      boxShadow: [
        BoxShadow(
          color: accent.withOpacity(0.07),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kText,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
        child,
      ],
    ),
  );

  // ── Razpoložljivost chips ──────────────────────────────────────────────────
  Widget _availChips() {
    final opts = [
      ('Dopoldan', Icons.wb_sunny_outlined),
      ('Popoldan', Icons.wb_cloudy_outlined),
      ('Zvečer', Icons.nights_stay_outlined),
      ('Vikend', Icons.weekend_outlined),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts.map((o) {
        final (label, icon) = o;
        final sel = razpolozljivost == label;
        return GestureDetector(
          onTap: () => setState(() => razpolozljivost = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _kPrimary : _kSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: sel ? _kPrimary : _kBorder, width: 1.2),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: sel ? Colors.white : _kTextSub),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : _kTextSub,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Nivo chips ─────────────────────────────────────────────────────────────
  Widget _nivoChips() {
    final opts = [
      ('Začetnik', const Color(0xFF10B981), Icons.eco_rounded),
      ('Srednje', const Color(0xFF3B82F6), Icons.trending_up_rounded),
      ('Napredno', const Color(0xFF8B5CF6), Icons.rocket_launch_rounded),
      ('Strokovnjak', const Color(0xFFF59E0B), Icons.military_tech_rounded),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts.map((o) {
        final (label, color, icon) = o;
        final sel = nivoZnanja == label;
        return GestureDetector(
          onTap: () => setState(() => nivoZnanja = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? color : _kSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: sel ? color : _kBorder, width: 1.2),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: sel ? Colors.white : _kTextSub),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : _kTextSub,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Tip toggle ─────────────────────────────────────────────────────────────
  Widget _tipToggle() {
    final opts = [
      ('Lahko učim druge', Icons.volunteer_activism_rounded, _kPrimary),
      ('Želim se naučiti', Icons.school_rounded, _kAmber),
    ];
    return Row(
      children: opts.map((o) {
        final (label, icon, color) = o;
        final sel = tipVescine == label;
        final isFirst = o == opts.first;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => tipVescine = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: isFirst ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.10) : _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? color : _kBorder,
                  width: sel ? 2 : 1.2,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: sel ? color : const Color(0xFFA5B4FC),
                    size: 20,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                      color: sel ? color : _kTextSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Skill card ─────────────────────────────────────────────────────────────
  Widget _skillCard(Map<String, dynamic> v, int i) {
    final canTeach = v['tip'] == 'Lahko učim druge';
    final accent = canTeach ? _kPrimary : _kAmber;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + i * 60),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - val)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canTeach
                      ? [_kPrimary, _kViolet]
                      : [_kAmber, const Color(0xFFF59E0B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canTeach
                      ? [_kPrimary, _kViolet]
                      : [_kAmber, const Color(0xFFF59E0B)],
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
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v['naziv'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${v['nivoZnanja']} • ${canTeach ? "Učim" : "Učim se"}',
                          style: TextStyle(
                            fontSize: 10,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => odstraniVescino(i),
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo card ─────────────────────────────────────────────────────────────
  Widget _photoCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _kBorder),
      boxShadow: [
        BoxShadow(
          color: _kPrimary.withOpacity(0.07),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: _kPrimary.withOpacity(0.3), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: selectedImage != null
                  ? ClipOval(
                      child: Image.file(selectedImage!, fit: BoxFit.cover),
                    )
                  : photoUrl.isNotEmpty
                  ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
                  : const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: _kPrimaryLight,
                    ),
            ),
            GestureDetector(
              onTap: izberiSliko,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Profilna slika',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _kText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Slika se shrani na Cloudinary.\nURL se hrani v Firestore bazi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _kTextSub, height: 1.45),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: _kPrimary, width: 1.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: OutlinedButton.icon(
              onPressed: izberiSliko,
              icon: const Icon(Icons.image_rounded, size: 18),
              label: Text(
                photoUrl.isEmpty && selectedImage == null
                    ? 'Dodaj sliko'
                    : 'Spremeni sliko',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header(BuildContext ctx) => AnimatedBuilder(
    animation: _orbCtrl,
    builder: (_, __) => Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 32),
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
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(34),
            bottomRight: Radius.circular(34),
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
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Uredi profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 22),
              // Ikona
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.28),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.manage_accounts_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Posodobi svoj profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dodaj sliko, opis, lokacijo in veščine\nza boljše povezovanje z drugimi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _privacySwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimary, _kViolet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextSub,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          Switch(value: value, onChanged: onChanged, activeColor: _kPrimary),
        ],
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _header(context),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
                    child: Column(
                      children: [
                        // ── Foto ─────────────────────────────────────────────
                        Transform.translate(
                          offset: const Offset(0, 12),
                          child: _photoCard(),
                        ),
                        const SizedBox(height: 26),

                        // ── Osnovni podatki ───────────────────────────────────
                        _card(
                          title: 'Osnovni podatki',
                          icon: Icons.person_rounded,
                          accent: _kPrimary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ime + Priimek
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
                                              v == null || v.isEmpty
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
                                              v == null || v.isEmpty
                                              ? 'Vnesite priimek'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Vnesite lokacijo'
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
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
                                      : const Icon(Icons.my_location_rounded),
                                  label: Text(
                                    isGettingLocation
                                        ? 'Pridobivanje lokacije...'
                                        : 'Uporabi trenutno lokacijo',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _kPrimary,
                                    side: const BorderSide(color: _kPrimary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
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
                        const SizedBox(height: 14),

                        // ── Opis + Razpoložljivost ─────────────────────────────
                        _card(
                          title: 'Opis in razpoložljivost',
                          icon: Icons.edit_note_rounded,
                          accent: _kViolet,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _lbl('Kratek opis'),
                              TextFormField(
                                controller: opisController,
                                focusNode: _opisFN,
                                maxLines: 3,
                                decoration: _deco(
                                  'Opišite se v nekaj besedah...',
                                  Icons.description_outlined,
                                  _opisFN,
                                  multiline: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _lbl('Razpoložljivost'),
                              _availChips(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _card(
                          title: 'Zasebnost profila',
                          icon: Icons.visibility_off_rounded,
                          accent: _kAmber,
                          child: Column(
                            children: [
                              _privacySwitch(
                                title: 'Prikaži lokacijo',
                                subtitle:
                                    'Drugi uporabniki lahko vidijo vašo lokacijo.',
                                value: showLocation,
                                onChanged: (v) =>
                                    setState(() => showLocation = v),
                                icon: Icons.location_on_outlined,
                              ),
                              _privacySwitch(
                                title: 'Prikaži opis',
                                subtitle:
                                    'Drugi uporabniki lahko vidijo vaš opis.',
                                value: showDescription,
                                onChanged: (v) =>
                                    setState(() => showDescription = v),
                                icon: Icons.description_outlined,
                              ),
                              _privacySwitch(
                                title: 'Prikaži razpoložljivost',
                                subtitle:
                                    'Drugi uporabniki lahko vidijo, kdaj ste dosegljivi.',
                                value: showAvailability,
                                onChanged: (v) =>
                                    setState(() => showAvailability = v),
                                icon: Icons.schedule_outlined,
                              ),
                              _privacySwitch(
                                title: 'Prikaži veščine',
                                subtitle:
                                    'Drugi uporabniki lahko vidijo vaše veščine.',
                                value: showSkills,
                                onChanged: (v) =>
                                    setState(() => showSkills = v),
                                icon: Icons.auto_awesome_rounded,
                              ),
                            ],
                          ),
                        ),

                        // ── Veščine ───────────────────────────────────────────
                        _card(
                          title: 'Veščine',
                          icon: Icons.auto_awesome_rounded,
                          accent: const Color(0xFF7C3AED),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Seznam obstoječih
                              if (vescine.isNotEmpty) ...[
                                ...vescine.asMap().entries.map(
                                  (e) => _skillCard(e.value, e.key),
                                ),
                                const SizedBox(height: 4),
                              ] else ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF5F3FF),
                                        Color(0xFFEEF2FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFDDD6FE),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [_kViolet, _kPrimary],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.lightbulb_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Še nimate veščin',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _kText,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Dodajte svojo prvo veščino spodaj.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _kTextSub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Add toggle gumb
                              GestureDetector(
                                onTap: _toggleAdd,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: _addingSkill
                                        ? null
                                        : const LinearGradient(
                                            colors: [_kPrimary, _kViolet],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                    color: _addingSkill
                                        ? const Color(0xFFF1F5F9)
                                        : null,
                                    borderRadius: BorderRadius.circular(14),
                                    border: _addingSkill
                                        ? Border.all(color: _kBorder)
                                        : null,
                                    boxShadow: _addingSkill
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: _kPrimary.withOpacity(
                                                0.32,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _addingSkill
                                            ? Icons.close_rounded
                                            : Icons.add_rounded,
                                        color: _addingSkill
                                            ? _kTextSub
                                            : Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        _addingSkill
                                            ? 'Zapri'
                                            : 'Dodaj veščino',
                                        style: TextStyle(
                                          color: _addingSkill
                                              ? _kTextSub
                                              : Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Collapsible add panel
                              SizeTransition(
                                sizeFactor: _addPanelAnim,
                                child: FadeTransition(
                                  opacity: _addPanelAnim,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 14),
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                      const SizedBox(height: 14),
                                      _lbl('Naziv veščine'),
                                      TextFormField(
                                        controller: vescinaController,
                                        focusNode: _vescinaFN,
                                        decoration: _deco(
                                          'Npr. Python, kuhanje...',
                                          Icons.star_outline_rounded,
                                          _vescinaFN,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _lbl('Nivo znanja'),
                                      _nivoChips(),
                                      const SizedBox(height: 12),
                                      _lbl('Tip veščine'),
                                      _tipToggle(),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 46,
                                        child: ElevatedButton.icon(
                                          onPressed: dodajVescino,
                                          icon: const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 17,
                                          ),
                                          label: const Text(
                                            'Potrdi in dodaj',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF059669,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            elevation: 2,
                                            shadowColor: const Color(
                                              0xFF059669,
                                            ).withOpacity(0.35),
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

                        const SizedBox(height: 16),

                        // ── Shrani gumb ──────────────────────────────────────
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
                                  onPressed: isSaving ? null : shraniSpremembe,
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
                                        ? (isUploadingImage
                                              ? 'Nalaganje slike...'
                                              : 'Shranjevanje...')
                                        : 'Shrani spremembe',
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
                      ],
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
}
