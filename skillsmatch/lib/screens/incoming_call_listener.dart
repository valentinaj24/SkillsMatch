import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'call_screen.dart'; // Pretpostavljam da je CallScreen u istoj putanji

class IncomingCallListener extends StatefulWidget {
  final Widget child;
  const IncomingCallListener({super.key, required this.child});

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  StreamSubscription? _callsSub;
  String? _currentCallId;
  bool _isPromptShowing = false;

  @override
  void initState() {
    super.initState();
    _listenForCalls();
  }

  void _listenForCalls() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    _callsSub = FirebaseFirestore.instance
        .collection('calls')
        .where('calleeId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          final docId = change.doc.id;
          if (!_isPromptShowing && _currentCallId == null) {
            _showIncomingCall(docId, data);
          }
        } else if (change.type == DocumentChangeType.modified) {
          if (change.doc.id == _currentCallId) {
            final status = change.doc.data()?['status'];
            if (status != 'ringing') {
              // Pozivatelj je otkazao/poziv više ne zvoni → skloni prompt
              if (_isPromptShowing) {
                Navigator.of(context, rootNavigator: true).maybePop();
                _resetState();
              }
            }
          }
        }
      }
    });
  }

  void _showIncomingCall(String docId, Map<String, dynamic>? data) {
    if (data == null) return;
    final callerName = data['callerName'] ?? 'Neznani klicatelj';
    final isVideoCall = data['isVideoCall'] == true;
    final token = data['token'] as String? ?? '';
    final livekitUrl = data['livekitUrl'] as String? ?? '';

    _currentCallId = docId;
    _isPromptShowing = true;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _IncomingCallPrompt(
          callerName: callerName,
          isVideoCall: isVideoCall,
          onAccept: () {
            // Prihvaćen poziv
            FirebaseFirestore.instance.doc('calls/$docId').update({
              'status': 'ongoing',
            });
            _resetState();
            // Zamijeni prompt ekranom poziva
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  roomName: docId,
                  token: token,
                  livekitUrl: livekitUrl,
                  isVideoCall: isVideoCall,
                  otherUserName: callerName,
                ),
              ),
            );
          },
          onDecline: () {
            // Odbijen poziv
            FirebaseFirestore.instance.doc('calls/$docId').update({
              'status': 'declined',
            });
            _resetState();
            Navigator.of(context, rootNavigator: true).maybePop();
          },
        ),
      ),
    ).then((_) {
      // Ako je korisnik zatvorio prompt sistemskim back gumbom
      if (_isPromptShowing) {
        FirebaseFirestore.instance.doc('calls/$docId').update({
          'status': 'declined',
        });
        _resetState();
      }
    });
  }

  void _resetState() {
    _currentCallId = null;
    _isPromptShowing = false;
  }

  @override
  void dispose() {
    _callsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Widget za prikaz dolaznog poziva (zvono)
class _IncomingCallPrompt extends StatelessWidget {
  final String callerName;
  final bool isVideoCall;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingCallPrompt({
    required this.callerName,
    required this.isVideoCall,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_in_talk, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Dohodni klic od',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isVideoCall ? 'Video klic' : 'Glasovni klic',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'decline',
                    backgroundColor: Colors.red,
                    onPressed: onDecline,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: 'accept',
                    backgroundColor: Colors.green,
                    onPressed: onAccept,
                    child: const Icon(Icons.call, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}