import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  }

  Future<User?> _getOrCreateUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return user;
    }

    final credential = await FirebaseAuth.instance.signInAnonymously();
    return credential.user;
  }

  Future<void> shraniProfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final user = await _getOrCreateUser();

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prijava uporabnika ni uspela.')),
        );
        setState(() => isSaving = false);
        return;
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil je bil uspešno shranjen.'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Napaka pri shranjevanju: $e')));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    imeController.dispose();
    priimekController.dispose();
    opisController.dispose();
    lokacijaController.dispose();
    vescinaController.dispose();
    super.dispose();
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef7f5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 58, 24, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff00796b), Color(0xff26a69a)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.diversity_3, color: Colors.white, size: 52),
                    SizedBox(height: 14),
                    Text(
                      'Skills Match',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Ustvari svoj profil, dodaj veščine in se poveži z drugimi generacijami.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.96 + (0.04 * value),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.teal.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
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
                            validator: (value) => value == null || value.isEmpty
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
                            validator: (value) => value == null || value.isEmpty
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
                            validator: (value) => value == null || value.isEmpty
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

                          const SizedBox(height: 28),
                          sectionTitle('Veščine', Icons.school),
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

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: dodajVescino,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text(
                                'Dodaj veščino',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                side: const BorderSide(color: Colors.teal),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: vescine.isEmpty
                                ? Container(
                                    key: const ValueKey('empty'),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Text(
                                      'Dodajte vsaj eno veščino, ki jo ponujate ali se je želite naučiti.',
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Column(
                                    key: const ValueKey('skills'),
                                    children: vescine.map((skill) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: Colors.teal,
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(
                                            skill.naziv,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${skill.nivoZnanja} • ${skill.tip}',
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                vescine.remove(skill);
                                              });
                                            },
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: isSaving ? null : shraniProfil,
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                isSaving ? 'Shranjevanje...' : 'Shrani profil',
                                style: const TextStyle(fontSize: 17),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
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
            ),
          ],
        ),
      ),
    );
  }
}
