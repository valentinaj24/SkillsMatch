import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veščina je bila dodana.'),
        backgroundColor: Color(0xff009688),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> potrdiBrisanje(Skill skill) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Izbriši veščino?'),
          content: Text('Ali želite odstraniti veščino "${skill.naziv}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Prekliči'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete),
              label: const Text('Izbriši'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        vescine.remove(skill);
      });
    }
  }

  Future<User?> _getOrCreateUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) return user;

    final credential = await FirebaseAuth.instance.signInAnonymously();
    return credential.user;
  }

  Future<void> shraniProfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final user = await _getOrCreateUser();

      if (user == null) {
        throw Exception('Prijava uporabnika ni uspela.');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'ime': imeController.text.trim(),
        'priimek': priimekController.text.trim(),
        'opis': opisController.text.trim(),
        'lokacija': lokacijaController.text.trim(),
        'razpolozljivost': razpolozljivost,
        'vescine': vescine.map((skill) {
          return {
            'naziv': skill.naziv,
            'nivoZnanja': skill.nivoZnanja,
            'tip': skill.tip,
          };
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      prikaziUspesenPopup();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Napaka pri shranjevanju: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void prikaziUspesenPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xff009688),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
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
                    color: Color(0xff004d40),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vaši podatki so bili uspešno posodobljeni.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff009688),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('V redu'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xff009688)),
      filled: true,
      fillColor: const Color(0xfff8fffd),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.teal.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xff009688), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xff009688)),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xff004d40),
          ),
        ),
      ],
    );
  }

  Widget profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff004d40), Color(0xff009688), Color(0xff4db6ac)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.diversity_3, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 18),
          const Text(
            'Skills Match',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ustvari profil, dodaj svoje veščine in poveži generacije skozi znanje.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget skillCard(Skill skill, int index) {
    final bool canTeach = skill.tip == 'Lahko učim druge';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + index * 80),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canTeach
                ? [const Color(0xffe0f2f1), const Color(0xfff8fffd)]
                : [const Color(0xfffff8e1), const Color(0xffffffff)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canTeach ? Colors.teal.shade100 : Colors.amber.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: canTeach
                  ? const Color(0xff009688)
                  : Colors.amber.shade700,
              child: Icon(
                canTeach ? Icons.volunteer_activism : Icons.school,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.naziv,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${skill.nivoZnanja} • ${skill.tip}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => potrdiBrisanje(skill),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    imeController.dispose();
    priimekController.dispose();
    opisController.dispose();
    lokacijaController.dispose();
    vescinaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef7f5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                profileHeader(),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Card(
                    elevation: 12,
                    shadowColor: Colors.teal.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            sectionTitle('Osnovni podatki', Icons.person),
                            const SizedBox(height: 18),

                            TextFormField(
                              controller: imeController,
                              decoration: inputStyle('Ime', Icons.badge),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Vnesite ime'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: priimekController,
                              decoration: inputStyle(
                                'Priimek',
                                Icons.person_outline,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Vnesite priimek'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: opisController,
                              maxLines: 3,
                              decoration: inputStyle(
                                'Kratek opis uporabnika',
                                Icons.description,
                              ),
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: lokacijaController,
                              decoration: inputStyle(
                                'Lokacija',
                                Icons.location_on,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Vnesite lokacijo'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String>(
                              value: razpolozljivost,
                              decoration: inputStyle(
                                'Razpoložljivost',
                                Icons.schedule,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Dopoldan',
                                  child: Text('Dopoldan'),
                                ),
                                DropdownMenuItem(
                                  value: 'Popoldan',
                                  child: Text('Popoldan'),
                                ),
                                DropdownMenuItem(
                                  value: 'Zvečer',
                                  child: Text('Zvečer'),
                                ),
                                DropdownMenuItem(
                                  value: 'Vikend',
                                  child: Text('Vikend'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => razpolozljivost = value!);
                              },
                            ),

                            const SizedBox(height: 30),
                            sectionTitle('Veščine', Icons.auto_awesome),
                            const SizedBox(height: 18),

                            TextFormField(
                              controller: vescinaController,
                              decoration: inputStyle(
                                'Vnesite veščino',
                                Icons.star,
                              ),
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String>(
                              value: nivoZnanja,
                              decoration: inputStyle(
                                'Nivo znanja',
                                Icons.trending_up,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Začetnik',
                                  child: Text('Začetnik'),
                                ),
                                DropdownMenuItem(
                                  value: 'Srednji nivo',
                                  child: Text('Srednji nivo'),
                                ),
                                DropdownMenuItem(
                                  value: 'Napredni nivo',
                                  child: Text('Napredni nivo'),
                                ),
                                DropdownMenuItem(
                                  value: 'Strokovnjak',
                                  child: Text('Strokovnjak'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => nivoZnanja = value!);
                              },
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String>(
                              value: tipVescine,
                              decoration: inputStyle(
                                'Tip veščine',
                                Icons.swap_horiz,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Želim se naučiti',
                                  child: Text('Želim se naučiti'),
                                ),
                                DropdownMenuItem(
                                  value: 'Lahko učim druge',
                                  child: Text('Lahko učim druge'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => tipVescine = value!);
                              },
                            ),

                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: dodajVescino,
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text(
                                  'Dodaj veščino',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xff009688),
                                  side: const BorderSide(
                                    color: Color(0xff009688),
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              child: vescine.isEmpty
                                  ? Container(
                                      key: const ValueKey('empty'),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.teal.shade100,
                                        ),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline,
                                            color: Color(0xff009688),
                                            size: 34,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Dodajte vsaj eno veščino, ki jo ponujate ali se je želite naučiti.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      key: const ValueKey('skills'),
                                      children: vescine
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => skillCard(
                                              entry.value,
                                              entry.key,
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),

                            const SizedBox(height: 26),

                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton.icon(
                                onPressed: isSaving ? null : shraniProfil,
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 21,
                                        height: 21,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_alt),
                                label: Text(
                                  isSaving
                                      ? 'Shranjevanje...'
                                      : 'Shrani profil',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff009688),
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shadowColor: Colors.teal.withOpacity(0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
