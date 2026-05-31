import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:skillsmatch/services/call_service.dart';
import 'call_screen.dart';
import 'package:skillsmatch/services/call_notification_service.dart';
import '../services/service_locator.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerName;
  final String roomName;
  final String receiverToken;
  final String liveKitUrl;
  final bool isVideoCall;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerName,
    required this.roomName,
    required this.receiverToken,
    required this.liveKitUrl,
    this.isVideoCall = true,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  Timer? _ringtoneTimer;
  Timer? _autoDeclineTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription? _callStatusSubscription;

  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startRinging();
    _listenToCallStatus();
  }

  void _listenToCallStatus() {
    _callStatusSubscription = ServiceLocator.firestore
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final status = doc.data()?['status'] ?? '';
      if (status == 'ended' || status == 'declined') {
        _stopRinging();
        CallNotificationService.cancelCallNotification(widget.callId);
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _callStatusSubscription?.cancel();
    _stopRinging();
    _autoDeclineTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRinging() async {
    try {
      await _ringtonePlayer.playRingtone(
        looping: true,
        volume: 0.7,
        asAlarm: false,
      );
    } catch (e) {
      print('Greška pri reprodukciji zvona: $e');
    }

    _ringtoneTimer = Timer.periodic(
      const Duration(milliseconds: 1000),
      (timer) {
        if (mounted) {
          HapticFeedback.heavyImpact();
        } else {
          timer.cancel();
        }
      },
    );

    _autoDeclineTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) _declineCall();
    });
  }

  void _stopRinging() {
    try {
      _ringtonePlayer.stop();
    } catch (e) {
      print('Greška pri zaustavljanju zvona: $e');
    }
    _ringtoneTimer?.cancel();
    _autoDeclineTimer?.cancel();
  }

  void _acceptCall() {
    _stopRinging();
    _callStatusSubscription?.cancel(); // ne reaguj na vlastite promjene

    CallNotificationService.cancelCallNotification(widget.callId);

    ServiceLocator.firestore
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'answered'});

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          roomName: widget.roomName,
          token: widget.receiverToken,
          livekitUrl: widget.liveKitUrl,
          isVideoCall: widget.isVideoCall, // ✅ proslijeđen tip poziva
          otherUserName: widget.callerName,
          callId: widget.callId,           // ✅ proslijeđen callId
        ),
      ),
    );
  }

  void _declineCall() {
    _stopRinging();
    _callStatusSubscription?.cancel();

    CallNotificationService.cancelCallNotification(widget.callId);

    ServiceLocator.firestore
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'declined'});

    CallService.declineCall(callId: widget.callId);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            Text(
              widget.isVideoCall ? '📹 Video poziv' : '📞 Glasovni poziv',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Dolazni poziv...',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
              ),
            ),

            const Spacer(flex: 1),

            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 70,
                ),
              ),
            ),

            const Spacer(flex: 2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(
                    icon: Icons.call_end_rounded,
                    color: const Color(0xFFEF4444),
                    label: 'Odbij',
                    onTap: _declineCall,
                  ),
                  _actionButton(
                    icon: Icons.call_rounded,
                    color: const Color(0xFF22C55E),
                    label: 'Prihvati',
                    onTap: _acceptCall,
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}