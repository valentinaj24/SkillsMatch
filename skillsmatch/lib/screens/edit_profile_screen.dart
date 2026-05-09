import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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

  String photoUrl = '';
  File? selectedImage;

  List<Map<String, dynamic>> vescine = [];

  static const Color dark = Color(0xff003c35);
  static const Color teal = Color(0xff00796b);
  static const Color bg = Color(0xffeef7f5);

  @override
  void initState() {
    super.initState();
    naloziProfil();
  }

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

      isLoading = false;
    });
  }

  Future<void> izberiSliko() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 900,
    );

    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
    });
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

    final data = jsonDecode(responseData);
    final imageUrl = data['secure_url'].toString();

    setState(() {
      photoUrl = imageUrl;
      isUploadingImage = false;
    });

    return imageUrl;
  }

  void dodajVescino() {
    final naziv = vescinaController.text.trim();

    if (naziv.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vnesite naziv veščine.')));
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
    });
  }

  void odstraniVescino(int index) {
    setState(() {
      vescine.removeAt(index);
    });
  }

  Future<void> shraniSpremembe() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uporabnik ni prijavljen.')));
      return;
    }

    setState(() => isSaving = true);

    try {
      final uploadedPhotoUrl = await uploadProfileImage(uid);

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'ime': imeController.text.trim(),
        'priimek': priimekController.text.trim(),
        'opis': opisController.text.trim(),
        'lokacija': lokacijaController.text.trim(),
        'razpolozljivost': razpolozljivost,
        'vescine': vescine,
        'photoUrl': uploadedPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil je uspešno posodobljen.'),
          backgroundColor: teal,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
        isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Napaka pri shranjevanju: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: teal),
      filled: true,
      fillColor: const Color(0xfff8fffd),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.teal.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.teal.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: teal)),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _profilePhotoCard(),
                    const SizedBox(height: 16),
                    _sectionCard(
                      title: 'Osnovni podatki',
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: imeController,
                            decoration: inputStyle('Ime', Icons.person),
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
                            controller: lokacijaController,
                            decoration: inputStyle(
                              'Lokacija',
                              Icons.location_on,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Vnesite lokacijo'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      title: 'Opis in razpoložljivost',
                      icon: Icons.edit_note,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: opisController,
                            maxLines: 4,
                            decoration: inputStyle(
                              'Kratek opis profila',
                              Icons.description_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: razpolozljivost,
                            decoration: inputStyle(
                              'Razpoložljivost',
                              Icons.access_time,
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
                              setState(() {
                                razpolozljivost = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      title: 'Veščine',
                      icon: Icons.school_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: vescinaController,
                            decoration: inputStyle(
                              'Naziv veščine',
                              Icons.lightbulb_outline,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                value: 'Srednje',
                                child: Text('Srednje'),
                              ),
                              DropdownMenuItem(
                                value: 'Napredno',
                                child: Text('Napredno'),
                              ),
                              DropdownMenuItem(
                                value: 'Strokovnjak',
                                child: Text('Strokovnjak'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                nivoZnanja = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: tipVescine,
                            decoration: inputStyle(
                              'Tip veščine',
                              Icons.swap_horiz,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Lahko učim druge',
                                child: Text('Lahko učim druge'),
                              ),
                              DropdownMenuItem(
                                value: 'Želim se naučiti',
                                child: Text('Želim se naučiti'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                tipVescine = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: dodajVescino,
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'Dodaj veščino',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: teal,
                                side: BorderSide(color: Colors.teal.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (vescine.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xfff8fffd),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.teal.shade50),
                              ),
                              child: const Text(
                                'Trenutno še nimate dodanih veščin.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          else
                            Column(
                              children: List.generate(vescine.length, (index) {
                                final vescina = vescine[index];
                                final isMentor =
                                    vescina['tip'] == 'Lahko učim druge';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isMentor
                                        ? Colors.teal.shade50
                                        : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isMentor
                                          ? Colors.teal.shade100
                                          : Colors.amber.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isMentor
                                            ? Icons.volunteer_activism
                                            : Icons.school,
                                        color: isMentor
                                            ? teal
                                            : Colors.amber.shade800,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vescina['naziv'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${vescina['nivoZnanja'] ?? ''} • ${vescina['tip'] ?? ''}',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => odstraniVescino(index),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : shraniSpremembe,
                        icon: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          isSaving
                              ? isUploadingImage
                                    ? 'Nalaganje slike...'
                                    : 'Shranjevanje...'
                              : 'Shrani profil',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilePhotoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff00796b), Color(0xff26a69a)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: teal.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xffe8f7f3),
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl) as ImageProvider
                      : null,
                  child: selectedImage == null && photoUrl.isEmpty
                      ? const Icon(Icons.person_rounded, size: 60, color: teal)
                      : null,
                ),
              ),
              GestureDetector(
                onTap: izberiSliko,
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Profilna slika',
            style: TextStyle(
              color: dark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Slika se shrani na Cloudinary, a njen URL se čuva u Firestore bazi i vidi se na strani Skupnost.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: izberiSliko,
              icon: const Icon(Icons.image_rounded),
              label: Text(
                photoUrl.isEmpty && selectedImage == null
                    ? 'Dodaj sliko'
                    : 'Spremeni sliko',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: teal,
                side: BorderSide(color: Colors.teal.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff003c35), Color(0xff00796b), Color(0xff26a69a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Text(
                'Uredi profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.manage_accounts_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Posodobi svoj profil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dodaj sliko, opis, lokacijo, razpoložljivost in veščine za boljše povezovanje z drugimi uporabniki.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              height: 1.4,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xffe8f7f3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: teal, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
