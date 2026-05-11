import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _kP = Color(0xFF4F46E5);
const _kV = Color(0xFF7C3AED);
const _kBg = Color(0xFFF0F0FF);
const _kTx = Color(0xFF1E1B4B);
const _kTs = Color(0xFF6B7280);
const _kBd = Color(0xFFE2E8F0);

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

  @override
  void initState() {
    super.initState();

    if (widget.skills.isNotEmpty) {
      selectedSkill = widget.skills.first['naziv'];
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Izberi datum in uro.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    setState(() {
      isSending = true;
    });

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentData = currentUserDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('collaborations').add({
        'requesterId': currentUser.uid,
        'receiverId': widget.userData['uid'],

        'requesterName':
            '${currentData['ime'] ?? ''} ${currentData['priimek'] ?? ''}',

        'receiverName':
            '${widget.userData['ime'] ?? ''} ${widget.userData['priimek'] ?? ''}',

        'skillName': selectedSkill,

        'message': _messageController.text.trim(),

        'date': Timestamp.fromDate(selectedDate!),

        'time':
            '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',

        'status': 'pending',

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Povabilo uspešno poslano!',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Napaka: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _kTx,
        title: const Text(
          'Novo sodelovanje',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _kBd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pošiljaš povabilo uporabniku',
                      style: TextStyle(fontSize: 13, color: _kTs),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.userData['ime']} ${widget.userData['priimek']}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: _kTx,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _kBd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Veščina',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _kTx,
                      ),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: selectedSkill,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF5F5FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: widget.skills.map((skill) {
                        return DropdownMenuItem<String>(
                          value: skill['naziv'],
                          child: Text(skill['naziv']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSkill = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Sporočilo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _kTx,
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vnesi sporočilo';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Napiši povabilo...',
                        filled: true,
                        fillColor: const Color(0xFFF5F5FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: _kP,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedDate == null
                                          ? 'Datum'
                                          : '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: GestureDetector(
                            onTap: pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: _kV,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedTime == null
                                          ? 'Ura'
                                          : selectedTime!.format(context),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),

              const SizedBox(height: 22),

              GestureDetector(
                onTap: isSending ? null : sendInvitation,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kP, _kV],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _kP.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Pošlji povabilo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
  }
}
