import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final imeController = TextEditingController();
  final priimekController = TextEditingController();
  final emailController = TextEditingController();
  final telefonController = TextEditingController();
  final lokacijaController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String vloga = 'Uporabnik';
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

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

  Future<void> register() async {
    final ime = imeController.text.trim();
    final priimek = priimekController.text.trim();
    final email = emailController.text.trim();
    final telefon = telefonController.text.trim();
    final lokacija = lokacijaController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (ime.isEmpty ||
        priimek.isEmpty ||
        email.isEmpty ||
        lokacija.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnack('Izpolnite vsa obvezna polja.', Colors.redAccent);
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Gesli se ne ujemata.', Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'ime': ime,
        'priimek': priimek,
        'email': email,
        'telefon': telefon,
        'lokacija': lokacija,
        'vloga': vloga,
        'opis': '',
        'razpolozljivost': '',
        'vescine': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      await _showSuccessPopup();

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Registracija ni uspela.';

      if (e.code == 'email-already-in-use') {
        message = 'Ta email je že registriran.';
      } else if (e.code == 'invalid-email') {
        message = 'Email naslov ni pravilen.';
      } else if (e.code == 'weak-password') {
        message = 'Geslo mora imeti vsaj 6 znakov.';
      }

      _showSnack(message, Colors.redAccent);
    } catch (e) {
      _showSnack('Napaka: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSuccessPopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
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
                  duration: const Duration(milliseconds: 650),
                  tween: Tween(begin: 0, end: 1),
                  curve: Curves.elasticOut,
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
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Račun je ustvarjen!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff004d40),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registracija je uspešna. Zdaj se lahko prijavite v aplikacijo.',
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
                    child: const Text('Nadaljuj na prijavo'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration inputStyle(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xff009688)),
      suffixIcon: suffixIcon,
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
    );
  }

  Widget _header() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_add_alt_1, color: Colors.white, size: 50),
          SizedBox(height: 16),
          Text(
            'Registracija',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ustvarite račun in se pridružite skupnosti Skills Match.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    imeController.dispose();
    priimekController.dispose();
    emailController.dispose();
    telefonController.dispose();
    lokacijaController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                _header(),
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
                      child: Column(
                        children: [
                          const Text(
                            'Ustvari račun',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff004d40),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Izpolnite osnovne podatke za registracijo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),

                          TextField(
                            controller: imeController,
                            decoration: inputStyle('Ime *', Icons.badge),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: priimekController,
                            decoration: inputStyle(
                              'Priimek *',
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: inputStyle('Email *', Icons.email),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: telefonController,
                            keyboardType: TextInputType.phone,
                            decoration: inputStyle(
                              'Telefon',
                              Icons.phone_android,
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: lokacijaController,
                            decoration: inputStyle(
                              'Lokacija *',
                              Icons.location_on,
                            ),
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            value: vloga,
                            decoration: inputStyle('Vloga', Icons.group),
                            items: const [
                              DropdownMenuItem(
                                value: 'Uporabnik',
                                child: Text('Uporabnik'),
                              ),
                              DropdownMenuItem(
                                value: 'Mentor',
                                child: Text('Mentor'),
                              ),
                              DropdownMenuItem(
                                value: 'Učenec',
                                child: Text('Učenec'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => vloga = value!);
                            },
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            decoration: inputStyle(
                              'Geslo *',
                              Icons.lock,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.teal,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: confirmPasswordController,
                            obscureText: !showConfirmPassword,
                            decoration: inputStyle(
                              'Ponovite geslo *',
                              Icons.lock_reset,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.teal,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showConfirmPassword = !showConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : register,
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 21,
                                      height: 21,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_1),
                              label: Text(
                                isLoading ? 'Ustvarjanje...' : 'Registriraj se',
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

                          const SizedBox(height: 12),

                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Že imate račun? Prijavite se',
                              style: TextStyle(
                                color: Color(0xff009688),
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}
