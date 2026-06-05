import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart'; // added for dynamic theme
import '../services/service_locator.dart'; // added for service locator

// Brand / Accent Colors (stay the same)
const _kP = Color(0xFF4F46E5);
const _kV = Color(0xFF7C3AED);
const _kRed = Color(0xFFEF4444);
const _kGreen = Color(0xFF059669);

class CreateCollaborationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List skills;

  const CreateCollaborationScreen({
    super.key,
    required this.userData,
    required this.skills,
  });

  @override
  State<CreateCollaborationScreen> createState() =>
      _CreateCollaborationScreenState();
}

class _CreateCollaborationScreenState extends State<CreateCollaborationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  String? selectedSkill;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isSending = false;

  String get receiverId => (widget.userData['uid'] ?? '').toString();

  String get receiverName {
    final ime = (widget.userData['ime'] ?? '').toString().trim();
    final priimek = (widget.userData['priimek'] ?? '').toString().trim();
    final fullName = '$ime $priimek'.trim();
    return fullName.isEmpty ? 'Neznan uporabnik' : fullName;
  }

  List<String> get skillNames {
    return widget.skills
        .map((skill) {
          if (skill is Map && skill['naziv'] != null) {
            return skill['naziv'].toString().trim();
          }
          return '';
        })
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final names = skillNames;
    if (names.isNotEmpty) {
      selectedSkill = names.first;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showSnack(String text, {Color color = _kP}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _selectedDateTime() {
    if (selectedDate == null || selectedTime == null) return null;
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: selectedDate ?? now,
      helpText: 'Izberi datum',
      cancelText: 'Prekliči',
      confirmText: 'Potrdi',
      builder: (context, child) {
        // Dynamic theme for date picker
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: _kP,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: _kP,
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1E1B4B),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      helpText: 'Izberi uro',
      cancelText: 'Prekliči',
      confirmText: 'Potrdi',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: _kP,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: _kP,
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1E1B4B),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<bool> _hasPendingInvitation(String requesterId) async {
    final existing = await ServiceLocator.firestore
        .collection('collaborations')
        .where('requesterId', isEqualTo: requesterId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return true;

    final reverseExisting = await ServiceLocator.firestore
        .collection('collaborations')
        .where('requesterId', isEqualTo: receiverId)
        .where('receiverId', isEqualTo: requesterId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return reverseExisting.docs.isNotEmpty;
  }

  Future<void> sendInvitation() async {
    if (isSending) return;
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ServiceLocator.auth.currentUser;
    if (currentUser == null) {
      _showSnack('Uporabnik ni prijavljen.', color: _kRed);
      return;
    }
    if (receiverId.isEmpty) {
      _showSnack('Napaka: uporabnik nima veljavnega ID-ja.', color: _kRed);
      return;
    }
    if (receiverId == currentUser.uid) {
      _showSnack('Ne moreš poslati povabila samemu sebi.', color: _kRed);
      return;
    }
    if (selectedSkill == null || selectedSkill!.trim().isEmpty) {
      _showSnack('Izberi veščino.', color: _kRed);
      return;
    }
    if (selectedDate == null || selectedTime == null) {
      _showSnack('Izberi datum in uro.', color: _kRed);
      return;
    }
    final meetingDateTime = _selectedDateTime();
    if (meetingDateTime == null || meetingDateTime.isBefore(DateTime.now())) {
      _showSnack('Izberi termin v prihodnosti.', color: _kRed);
      return;
    }

    setState(() => isSending = true);

    try {
      final alreadyExists = await _hasPendingInvitation(currentUser.uid);
      if (alreadyExists) {
        _showSnack('Med vama že obstaja aktivno povabilo.', color: Colors.orange);
        return;
      }

      final currentUserDoc = await ServiceLocator.firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentData = currentUserDoc.data() ?? {};
      final requesterName = '${currentData['ime'] ?? ''} ${currentData['priimek'] ?? ''}'.trim();

      await ServiceLocator.firestore.collection('collaborations').add({
        'requesterId': currentUser.uid,
        'receiverId': receiverId,
        'requesterName': requesterName.isEmpty ? 'Neznan uporabnik' : requesterName,
        'receiverName': receiverName,
        'skillName': selectedSkill,
        'message': _messageController.text.trim(),
        'date': Timestamp.fromDate(selectedDate!),
        'meetingAt': Timestamp.fromDate(meetingDateTime),
        'time': _formatTime(selectedTime!),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnack('Povabilo uspešno poslano!', color: _kGreen);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Napaka: $e', color: _kRed);
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = skillNames;
    final hasSkills = names.isNotEmpty;

    return Scaffold(
      backgroundColor: context.kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.kBg,
        surfaceTintColor: context.kBg,
        foregroundColor: context.kText,
        centerTitle: false,
        title: Text(
          'Novo sodelovanje',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.2, color: context.kText),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _receiverCard(),
              const SizedBox(height: 16),
              _formCard(names, hasSkills),
              const SizedBox(height: 22),
              _sendButton(hasSkills),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiverCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.kCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.kBorder),
        boxShadow: [
          BoxShadow(
            color: _kP.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kP, _kV]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pošiljaš povabilo uporabniku',
                  style: TextStyle(fontSize: 13, color: context.kTextSub, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Text(
                  receiverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: context.kText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard(List<String> names, bool hasSkills) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.kCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.kBorder),
        boxShadow: [
          BoxShadow(
            color: _kP.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Veščina'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: Key('skill_dropdown'),
            value: hasSkills ? selectedSkill : null,
            isExpanded: true,
            decoration: _inputDecoration(
              hint: hasSkills ? 'Izberi veščino' : 'Uporabnik nima veščin',
              icon: Icons.school_rounded,
            ),
            items: names.map((name) {
              return DropdownMenuItem<String>(
                value: name,
                child: Text(name, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.kText)),
              );
            }).toList(),
            validator: (value) {
              if (!hasSkills) return 'Uporabnik nima dodanih veščin';
              if (value == null || value.trim().isEmpty) return 'Izberi veščino';
              return null;
            },
            onChanged: hasSkills ? (value) => setState(() => selectedSkill = value) : null,
            dropdownColor: context.kCardBg,
            style: TextStyle(color: context.kText),
          ),
          if (!hasSkills) ...[
            const SizedBox(height: 9),
            Text(
              'Temu uporabniku trenutno ne moreš poslati povabila, ker nima dodanih veščin.',
              style: TextStyle(color: context.kTextSub, fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: 18),
          _label('Sporočilo'),
          const SizedBox(height: 10),
          TextFormField(
            key: Key('message_input_collaboration'),
            controller: _messageController,
            maxLines: 4,
            maxLength: 250,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Vnesi sporočilo';
              if (value.trim().length < 5) return 'Sporočilo je prekratko';
              return null;
            },
            decoration: _inputDecoration(
              hint: 'Napiši povabilo...',
              icon: Icons.edit_note_rounded,
            ),
            style: TextStyle(color: context.kText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _pickerBox(
                  icon: Icons.calendar_month_rounded,
                  text: selectedDate == null ? 'Datum' : _formatDate(selectedDate!),
                  onTap: pickDate,
                  pickerKey: Key('date_picker'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickerBox(
                  icon: Icons.access_time_rounded,
                  text: selectedTime == null ? 'Ura' : _formatTime(selectedTime!),
                  onTap: pickTime,
                  violet: true,
                  pickerKey: Key('time_picker'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w900, color: context.kText, fontSize: 14),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.kTextSub, fontSize: 14),
      prefixIcon: Icon(icon, color: _kP, size: 21),
      filled: true,
      fillColor: context.kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kP, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kRed, width: 1.2),
      ),
      counterStyle: TextStyle(color: context.kTextSub),
    );
  }

  Widget _pickerBox({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required Key pickerKey,
    bool violet = false,
  }) {
    return Material(
      color: context.kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: pickerKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.kBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: violet ? _kV : _kP, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, color: context.kText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sendButton(bool hasSkills) {
    return Opacity(
      opacity: (!hasSkills || isSending) ? 0.75 : 1,
      child: GestureDetector(
        onTap: (!hasSkills || isSending) ? null : sendInvitation,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kP, _kV]),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: _kP.withOpacity(0.34),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isSending
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 9),
                      Text(
                        'Pošlji povabilo',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}