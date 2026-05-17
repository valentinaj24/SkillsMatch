import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:skillsmatch/accessibility/app_accessibility.dart';
import 'package:skillsmatch/screens/incoming_call_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';


// ─── Background handler ───────────────────────────────────────────────────────
// Poziva se kada app nije aktivan (terminated ili background).
// Prikazuje sistemsku notifikaciju koja korisnika vodi u app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['type'] == 'incoming_call') {
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final callId        = message.data['callId']        ?? '';
    final callerName    = message.data['callerName']    ?? 'Nepoznat';
    final roomName      = message.data['roomName']      ?? '';
    final receiverToken = message.data['receiverToken'] ?? '';
    final liveKitUrl    = message.data['liveKitUrl']    ?? '';
    final isVideoCall   = message.data['isVideoCall'] == 'true' ||
                          message.data['isVideoCall'] == true;

    final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Incoming video/audio call notifications',
      importance:       Importance.max,
      priority:         Priority.max,
      fullScreenIntent: true,
      category:         AndroidNotificationCategory.call,
      playSound:        true,
      enableVibration:  true,
      ongoing:          true,
      autoCancel:       false,
      visibility:       NotificationVisibility.public,
      additionalFlags:  Int32List.fromList([4, 128]),
    );

    await plugin.show(
      id: callId.hashCode,
      title: isVideoCall ? '📹 Dolazni video poziv' : '📞 Dolazni poziv',
      body: callerName,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: '$callId|$callerName|$roomName|$receiverToken|$liveKitUrl|$isVideoCall',
    );
  }
}

// ─── CallNotificationService ─────────────────────────────────────────────────
class CallNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Kreiraj Android notification kanal za pozive
    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description:     'Incoming video/audio call notifications',
      importance:      Importance.max,
      playSound:       true,
      enableVibration: true,
      enableLights:    true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(callChannel);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          _handleNotificationTap(details.payload!);
        }
      },
    );

    // ─── FOREGROUND: app je otvoren ──────────────────────────────────────────
    // Ne prikazujemo notifikaciju — direktno otvaramo IncomingCallScreen.
    // Ako je Android auto-prikazao notifikaciju, odmah je otkazujemo.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'incoming_call') {
        final callId = message.data['callId'] ?? '';
        if (callId.isNotEmpty) {
          _localNotifications.cancel(id: callId.hashCode);
        }
        _openIncomingCallScreenDirectly(message.data);
      }
    });

    // ─── TERMINATED: app je bio potpuno zatvoren ─────────────────────────────
    // Korisnik je tapnuo na notifikaciju i otvorio app.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && message.data['type'] == 'incoming_call') {
        _handleNotificationTap(_buildPayload(message.data));
      }
    });

    // ─── BACKGROUND: app je bio u backgroundu ────────────────────────────────
    // Korisnik je tapnuo na notifikaciju.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['type'] == 'incoming_call') {
        _handleNotificationTap(_buildPayload(message.data));
      }
    });

    _initialized = true;
  }

  // ─── Direktno otvara IncomingCallScreen (foreground, bez notifikacije) ─────
  static void _openIncomingCallScreenDirectly(Map<String, dynamic> data) {
    final callId        = data['callId']        ?? '';
    final callerName    = data['callerName']    ?? 'Nepoznat';
    final roomName      = data['roomName']      ?? '';
    final receiverToken = data['receiverToken'] ?? '';
    final liveKitUrl    = data['liveKitUrl']    ?? '';
    final isVideoCall   = data['isVideoCall'] == 'true' || data['isVideoCall'] == true;

    final navigatorKey = AppAccessibility.instance.navigatorKey;
    if (navigatorKey.currentContext == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callId:        callId,
          callerName:    callerName,
          roomName:      roomName,
          receiverToken: receiverToken,
          liveKitUrl:    liveKitUrl,
          isVideoCall:   isVideoCall,
        ),
      ),
    );
  }

  // ─── Prikazuje sistemsku notifikaciju (background/terminated) ──────────────
  static Future<void> showIncomingCallNotification({
    required String callId,
    required String callerName,
    required String roomName,
    required String receiverToken,
    required String liveKitUrl,
    bool isVideoCall = true,
  }) async {
    final payload = _buildPayloadFromParts(
      callId:        callId,
      callerName:    callerName,
      roomName:      roomName,
      receiverToken: receiverToken,
      liveKitUrl:    liveKitUrl,
      isVideoCall:   isVideoCall,
    );

    final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Incoming video/audio call notifications',
      importance:       Importance.max,
      priority:         Priority.max,
      fullScreenIntent: true,
      category:         AndroidNotificationCategory.call,
      playSound:        true,
      enableVibration:  true,
      ongoing:          true,
      autoCancel:       false,
      visibility:       NotificationVisibility.public,
      additionalFlags:  Int32List.fromList([4, 128]),
      actions: [
        const AndroidNotificationAction(
          'decline_call',
          'Odbij',
          cancelNotification: true,
          showsUserInterface:  true,
        ),
        const AndroidNotificationAction(
          'accept_call',
          'Prihvati',
          cancelNotification: true,
          showsUserInterface:  true,
        ),
      ],
    );

    await _localNotifications.show(
      id:                  callId.hashCode,
      title:               isVideoCall ? '📹 Dolazni video poziv' : '📞 Dolazni poziv',
      body:                callerName,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload:             payload,
    );
  }

  static Future<void> cancelCallNotification(String callId) async {
    await _localNotifications.cancel(id: callId.hashCode);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String _buildPayload(Map<String, dynamic> data) {
    return _buildPayloadFromParts(
      callId:        data['callId']        ?? '',
      callerName:    data['callerName']    ?? '',
      roomName:      data['roomName']      ?? '',
      receiverToken: data['receiverToken'] ?? '',
      liveKitUrl:    data['liveKitUrl']    ?? '',
      isVideoCall:   data['isVideoCall'] == 'true' || data['isVideoCall'] == true,
    );
  }

  static String _buildPayloadFromParts({
    required String callId,
    required String callerName,
    required String roomName,
    required String receiverToken,
    required String liveKitUrl,
    bool isVideoCall = true,
  }) {
    return '$callId|$callerName|$roomName|$receiverToken|$liveKitUrl|$isVideoCall';
  }

  static Map<String, String> parsePayload(String payload) {
    final parts = payload.split('|');
    return {
      'callId':        parts.isNotEmpty ? parts[0] : '',
      'callerName':    parts.length > 1 ? parts[1] : '',
      'roomName':      parts.length > 2 ? parts[2] : '',
      'receiverToken': parts.length > 3 ? parts[3] : '',
      'liveKitUrl':    parts.length > 4 ? parts[4] : '',
      'isVideoCall':   parts.length > 5 ? parts[5] : 'true',
    };
  }

  static void _handleNotificationTap(String payload) {
    final data   = parsePayload(payload);
    final callId = data['callId'] ?? '';

    cancelCallNotification(callId);

    // Provjeri da li je poziv još aktivan u Firestore-u
    FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .get()
        .then((doc) {
      if (!doc.exists) return;

      final status = doc.data()?['status'] ?? '';
      if (status == 'ended' || status == 'declined' || status == 'missed') return;

      final isVideoCall  = data['isVideoCall'] == 'true';
      final navigatorKey = AppAccessibility.instance.navigatorKey;
      if (navigatorKey.currentContext == null) return;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callId:        data['callId']!,
            callerName:    data['callerName']!,
            roomName:      data['roomName']!,
            receiverToken: data['receiverToken']!,
            liveKitUrl:    data['liveKitUrl']!,
            isVideoCall:   isVideoCall,
          ),
        ),
      );
    });
  }
}