import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
const _kRed = Color(0xFFEF4444);

class CallScreen extends StatefulWidget {
  final String roomName;
  final String token;
  final String livekitUrl;
  final bool isVideoCall;
  final String otherUserName;

  const CallScreen({
    super.key,
    required this.roomName,
    required this.token,
    required this.livekitUrl,
    required this.isVideoCall,
    required this.otherUserName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Room? _room;
  bool _connected = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  VideoTrack? _localVideoTrack;
  VideoTrack? _remoteVideoTrack;

  // ✅ ISPRAVAN TIP: void Function()? umesto Future<void> Function()?
  void Function()? _cancelEvents;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndConnect();
  }

  @override
  void dispose() {
    _cancelEvents?.call();   // Otkazujemo osluškivač
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndConnect() async {
    if (widget.isVideoCall) {
      await [Permission.camera, Permission.microphone].request();
    } else {
      await Permission.microphone.request();
    }
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    final room = Room();

    // ✅ room.events.listen vraća void Function(), ne Future<void> Function()
    _cancelEvents = room.events.listen((event) {
      if (event is TrackSubscribedEvent) {
        final track = event.track;
        if (track is RemoteVideoTrack) {
          if (!mounted) return;
          setState(() {
            _remoteVideoTrack = track;
          });
        }
      }
    });

    try {
      await room.connect(
        widget.livekitUrl,
        widget.token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      await room.localParticipant?.setMicrophoneEnabled(true);

      if (widget.isVideoCall) {
        await room.localParticipant?.setCameraEnabled(true);
        // Dohvati lokalni video track
        for (final pub in room.localParticipant!.videoTrackPublications) {
          if (pub.track != null) {
            _localVideoTrack = pub.track as VideoTrack;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _room = room;
          _connected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Napaka pri povezavi: $e'),
            backgroundColor: _kRed,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleMic() async {
    setState(() => _micEnabled = !_micEnabled);
    await _room?.localParticipant?.setMicrophoneEnabled(_micEnabled);
  }

  Future<void> _toggleCamera() async {
    setState(() => _cameraEnabled = !_cameraEnabled);
    await _room?.localParticipant?.setCameraEnabled(_cameraEnabled);
  }

  Future<void> _endCall() async {
    try {
      final callDoc = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.roomName)
          .get();
      
      if (callDoc.exists && callDoc.data()?['status'] != 'ended') {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.roomName)
            .update({'status': 'ended'});
      }
    } catch (_) {}

    await _room?.disconnect();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video ili voice background
            if (widget.isVideoCall && _remoteVideoTrack != null)
              Positioned.fill(
                child: VideoTrackRenderer(_remoteVideoTrack!),
              )
            else
              _voiceBackground(),

            // Lokalni video (mali, gore desno)
            if (widget.isVideoCall && _localVideoTrack != null)
              Positioned(
                top: 16,
                right: 16,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: VideoTrackRenderer(_localVideoTrack!),
                ),
              ),

            // Control buttons
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _controls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kViolet],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 55,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _connected ? 'Klic v teku...' : 'Povezovanje...',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
          color: _micEnabled ? Colors.white24 : _kRed,
          onTap: _toggleMic,
        ),
        const SizedBox(width: 20),
        if (widget.isVideoCall) ...[
          _circleButton(
            icon: _cameraEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            color: _cameraEnabled ? Colors.white24 : _kRed,
            onTap: _toggleCamera,
          ),
          const SizedBox(width: 20),
        ],
        _circleButton(
          icon: Icons.call_end_rounded,
          color: _kRed,
          size: 70,
          iconSize: 32,
          onTap: _endCall,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 58,
    double iconSize = 26,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}