// lib/screens/incoming_call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'call_screen.dart';
import 'package:flutter/services.dart';
import 'package:skillsmatch/services/call_service.dart';


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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Kreiraj instancu FlutterRingtonePlayer
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  @override
  void initState() {
    super.initState();
    
    // Pulse animacija za avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Zvono i vibracija
    _startRinging();
    
    // Auto-odbijanje nakon 30s
    Timer(const Duration(seconds: 30), () {
      if (mounted) _declineCall();
    });
  }

  @override
  void dispose() {
    _stopRinging();
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
  
  // Jednostavna vibracija koristeći HapticFeedback
  Timer.periodic(const Duration(milliseconds: 1000), (timer) {
    HapticFeedback.heavyImpact();
    if (!mounted) timer.cancel();
  });
}

  void _stopRinging() {
    try {
      _ringtonePlayer.stop();
    } catch (e) {
      print('Greška pri zaustavljanju zvona: $e');
    }
    
    Vibration.cancel();
    _ringtoneTimer?.cancel();
  }

  void _acceptCall() {
    _stopRinging();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          roomName: widget.roomName,
          token: widget.receiverToken,
          livekitUrl: widget.liveKitUrl,
          isVideoCall: widget.isVideoCall,
          otherUserName: widget.callerName,
        ),
      ),
    );
  }

  void _declineCall() {
  _stopRinging();
  
  // Pošalji decline na server
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
            
            // Caller info
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
            
            // Pulsirajući avatar
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
            
            // Accept / Decline dugmići
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  _actionButton(
                    icon: Icons.call_end_rounded,
                    color: const Color(0xFFEF4444),
                    label: 'Odbij',
                    onTap: _declineCall,
                  ),
                  
                  // Accept
                  _actionButton(
                    icon: Icons.call_rounded,
                    color: const Color(0xFF22C55E),
                    label: 'Prihvati',
                    onTap: _acceptCall,
                    pulse: true,
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
    bool pulse = false,
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