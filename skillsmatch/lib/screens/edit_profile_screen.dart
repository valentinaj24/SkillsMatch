import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  String razpolozljivost = 'Dopoldan';
  bool isLoading = true;
  bool isSaving = false;

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
      isLoading = false;
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

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'ime': imeController.text.trim(),
      'priimek': priimekController.text.trim(),
      'opis': opisController.text.trim(),
      'lokacija': lokacijaController.text.trim(),
      'razpolozljivost': razpolozljivost,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spremembe so bile shranjene.'),
        backgroundColor: Colors.teal,
      ),
    );

    Navigator.pop(context);
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    imeController.dispose();
    priimekController.dispose();
    opisController.dispose();
    lokacijaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xffeef7f5),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffeef7f5),
      appBar: AppBar(
        title: const Text('Uredi profil'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.edit_note, size: 70, color: Colors.teal),
                  const SizedBox(height: 10),
                  const Text(
                    'Spremeni svoje podatke',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 22),

                  TextFormField(
                    controller: imeController,
                    decoration: inputStyle('Ime', Icons.person),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Vnesite ime' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: priimekController,
                    decoration: inputStyle('Priimek', Icons.person_outline),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Vnesite priimek'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: opisController,
                    maxLines: 3,
                    decoration: inputStyle('Opis', Icons.description),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: lokacijaController,
                    decoration: inputStyle('Lokacija', Icons.location_on),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Vnesite lokacijo'
                        : null,
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
                      DropdownMenuItem(value: 'Zvečer', child: Text('Zvečer')),
                      DropdownMenuItem(value: 'Vikend', child: Text('Vikend')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        razpolozljivost = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
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
                          : const Icon(Icons.save),
                      label: Text(
                        isSaving ? 'Shranjevanje...' : 'Shrani spremembe',
                        style: const TextStyle(fontSize: 17),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
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
    );
  }
}
