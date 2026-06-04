import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/call_notification_service.dart';
import '../services/service_locator.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
const _kRed = Color(0xFFEF4444);

class CallScreen extends StatefulWidget {
  final String roomName;
  final String token;
  final String livekitUrl;
  final bool isVideoCall;
  final String otherUserName;
  final String callId;

  const CallScreen({
    super.key,
    required this.roomName,
    required this.token,
    required this.livekitUrl,
    required this.isVideoCall,
    required this.otherUserName,
    required this.callId,
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
  bool _timerStarted = false;

  void Function()? _cancelEvents;
  bool _speakerEnabled = false;
  bool _remoteCameraEnabled = true;

  StreamSubscription? _callStatusSubscription;

  // ─── Tajmer trajanja poziva ───────────────────────────────────────────────
  Timer? _durationTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndConnect();
    _listenToCallStatus();
  }

  @override
  void dispose() {
    _callStatusSubscription?.cancel();
    _durationTimer?.cancel();
    _cancelEvents?.call();
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String get _formattedDuration {
    final h = _secondsElapsed ~/ 3600;
    final m = (_secondsElapsed % 3600) ~/ 60;
    final s = _secondsElapsed % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _listenToCallStatus() {
    _callStatusSubscription = ServiceLocator.firestore
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final status = doc.data()?['status'] ?? '';
      if (status == 'answered' && !_timerStarted) {
        _startDurationTimer();
        _timerStarted = true;
      }
      if (status == 'ended') {
        _hangUpLocally();
      }
    });
  }

  Future<void> _hangUpLocally() async {
    if (_isHangingUp) return;
    _isHangingUp = true;
    await _callStatusSubscription?.cancel();
    _durationTimer?.cancel();
    _cancelEvents?.call();
    await Hardware.instance.setSpeakerphoneOn(false);
    await _room?.disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poziv je završen'),
          backgroundColor: Colors.black54,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _addMissedCallMessage() async {
  print('_addMissedCallMessage POZVAN, secondsElapsed=$_secondsElapsed');

  try {
    final callDoc = await ServiceLocator.firestore
        .collection('calls').doc(widget.callId).get();
    final data = callDoc.data();
    if (data == null) return;

    final chatId = data['chatId'] as String?;
    if (chatId == null) return;

    final isVideo = data['isVideo'] ?? false;

    final messageText = isVideo
        ? ' Zamujeni video klic za ${widget.otherUserName}'
        : ' Zamujeni klic za ${widget.otherUserName}';

    final chatRef = ServiceLocator.firestore.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'senderId': ServiceLocator.auth.currentUser?.uid ?? 'system',
      'type': 'call',
      'text': messageText,
      'createdAt': FieldValue.serverTimestamp(),
      'callDuration': 0,
      'isVideo': isVideo,
      'missed': true,
    });

    await chatRef.set({
      'lastMessage': messageText,
      'lastMessageSenderId': 'system',
      'lastMessageSeen': false,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    print('Greška pri pisanju missed call poruke: $e');
  }
}

  Future<void> _requestPermissionsAndConnect() async {
    if (widget.isVideoCall) {
      await [Permission.camera, Permission.microphone].request();
    } else {
      await Permission.microphone.request();
    }
    await _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    final room = Room();

    _cancelEvents = room.events.listen((event) {
      if (event is TrackSubscribedEvent) {
        final track = event.track;
        if (track is RemoteVideoTrack) {
          if (!mounted) return;
          setState(() {
            _remoteVideoTrack = track;
          });
        }
      } else if (event is TrackMutedEvent) {
        if (event.publication.track is RemoteVideoTrack) {
          if (!mounted) return;
          setState(() => _remoteCameraEnabled = false);
        }
      } else if (event is TrackUnmutedEvent) {
        if (event.publication.track is RemoteVideoTrack) {
          if (!mounted) return;
          setState(() => _remoteCameraEnabled = true);
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
        for (final pub in room.localParticipant!.videoTrackPublications) {
          if (pub.track != null && pub.track is VideoTrack) {
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

  Future<void> _toggleSpeaker() async {
    setState(() => _speakerEnabled = !_speakerEnabled);
    await Hardware.instance.setSpeakerphoneOn(_speakerEnabled);
  }

  bool _isHangingUp = false; 
  int _endCallCount = 0;
  Future<void> _endCall() async {
    _endCallCount++;
    print('_endCall POZVAN br.$_endCallCount, _isHangingUp=$_isHangingUp');    
    if (_isHangingUp) return;
    _isHangingUp = true;
    print('_endCall NASTAVLJA br.$_endCallCount');


    await _callStatusSubscription?.cancel();
    _durationTimer?.cancel();

    try {
      await ServiceLocator.firestore
          .collection('calls')
          .doc(widget.callId)
          .update({
            'status': 'ended',
            'endedAt': FieldValue.serverTimestamp(),
            'durationSeconds': _secondsElapsed,
          });
      
      if (_secondsElapsed > 0) {
        print('Pisem _addCallEndMessage');
        await _addCallEndMessage();      // poziv je bio odgovoren
      } else {
        print('Pisem _addMissedCallMessage');
        await _addMissedCallMessage();   // poziv nije bio odgovoren
      }

      await CallNotificationService.cancelCallNotification(widget.callId);
    } catch (e) {
      print('Greška pri ažuriranju statusa: $e');
    }

    _cancelEvents?.call();
    await Hardware.instance.setSpeakerphoneOn(false);
    await _room?.disconnect();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addCallEndMessage() async {
    print('_addCallEndMessage POZVAN, secondsElapsed=$_secondsElapsed');

    final callDoc = await ServiceLocator.firestore
        .collection('calls')
        .doc(widget.callId)
        .get();

    final data = callDoc.data();
    if (data == null) return;

    final chatId = data['chatId'] as String?;
    if (chatId == null) return;

    final callerId = data['callerId'] as String?;
    final isVideo = data['isVideo'] ?? false;
    final durationSec = _secondsElapsed;

    // Formatiranje trajanja (MM:SS)
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;
    final durationStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final currentUserId = ServiceLocator.auth.currentUser?.uid;
    final isCaller = currentUserId == callerId;

    final messageText = isCaller
    ? (isVideo 
        ? ' Video klic k ${widget.otherUserName} – trajanje $durationStr' 
        : ' Glasovni klic k ${widget.otherUserName} – trajanje $durationStr')
    : (isVideo 
        ? ' Video klic od ${widget.otherUserName} – trajanje $durationStr' 
        : ' Glasovni klic od ${widget.otherUserName} – trajanje $durationStr');
        
    final chatRef = ServiceLocator.firestore.collection('chats').doc(chatId);

    // Dodaj poruku u podkolekciju messages
    await chatRef.collection('messages').add({
      'senderId': ServiceLocator.auth.currentUser?.uid ?? 'system',
      'type': 'call',
      'text': messageText,
      'createdAt': FieldValue.serverTimestamp(),
      'callDuration': durationSec,
      'isVideo': isVideo,
      'callerId': callerId,
    });

    // Ažuriraj lastMessage u chatu
    await chatRef.set({
      'lastMessage': messageText,
      'lastMessageSenderId': 'system',
      'lastMessageSeen': false,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.isVideoCall && _remoteVideoTrack != null && _remoteCameraEnabled)
              Positioned.fill(
                child: VideoTrackRenderer(_remoteVideoTrack!),
              )
            else
              _voiceBackground(),

            if (widget.isVideoCall && _localVideoTrack != null)
              Positioned(
                top: 16,
                right: 16,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _cameraEnabled
                      ? VideoTrackRenderer(_localVideoTrack!)
                      : Container(
                          color: const Color(0xFF1A1A2E),
                          child: const Center(
                            child: Icon(
                              Icons.videocam_off_rounded,
                              color: Colors.white38,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),

            // ─── Trajanje poziva (video call - overlay na vrhu) ─────────────
            if (widget.isVideoCall && _connected)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

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
            // ─── Trajanje / status (glasovni poziv) ────────────────────────
            Text(
              _connected ? _formattedDuration : 'Povezovanje...',
              style: TextStyle(
                color: _connected ? Colors.white70 : Colors.white54,
                fontSize: 18,
                fontWeight: _connected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: _connected ? 1.2 : 0,
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
        _circleButton(
          icon: _speakerEnabled ? Icons.volume_up_rounded : Icons.volume_down_rounded,
          color: _speakerEnabled ? _kPrimary : Colors.white24,
          onTap: _toggleSpeaker,
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