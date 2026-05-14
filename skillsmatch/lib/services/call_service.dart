import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'call_notification_service.dart';

class CallService {
  
  static const String serverUrl = 'https://skillsmatch-server.onrender.com';

  /// Inicira poziv - poziva server endpoint /call/initiate
  static Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required String receiverName,
    required bool isVideoCall,
  }) async {
    final caller = FirebaseAuth.instance.currentUser;
    if (caller == null) throw Exception('Niste prijavljeni');

    // Dobavi ime callera iz Firestore-a
    final callerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(caller.uid)
        .get();
    final callerName = callerDoc.data()?['ime'] ?? 'Nepoznat';

    // Dobavi FCM token primaoca
    final receiverDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .get();
    
    final receiverFcmToken = receiverDoc.data()?['fcmToken'];

    if (receiverFcmToken == null) {
      throw Exception('Korisnik nije dostupan za pozive');
    }

    // Pozovi server
    final response = await http.post(
      Uri.parse('$serverUrl/call/initiate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'callerIdentity': caller.uid,
        'receiverIdentity': receiverId,
        'receiverFcmToken': receiverFcmToken,
        'callerName': callerName,
        'isVideoCall': isVideoCall,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Server greška: ${response.body}');
    }
  }

  /// Odbija poziv
  static Future<void> declineCall({
    required String callId,
    String? callerFcmToken,
  }) async {
    try {
      await http.post(
        Uri.parse('$serverUrl/call/decline'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'callId': callId,
          'callerFcmToken': callerFcmToken,
        }),
      );
      CallNotificationService.cancelCallNotification(callId);

    } catch (e) {
      print('Greška pri odbijanju poziva: $e');
    }
  }
}