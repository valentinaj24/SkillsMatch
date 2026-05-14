import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:skillsmatch/accessibility/app_accessibility.dart';
import 'package:skillsmatch/screens/incoming_call_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';


// ─── Background handler ───────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['type'] == 'incoming_call') {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings();
    
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    
    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'Incoming video/audio call notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    
    final callId = message.data['callId'] ?? '';
    final callerName = message.data['callerName'] ?? 'Nepoznat';
    final roomName = message.data['roomName'] ?? '';
    final receiverToken = message.data['receiverToken'] ?? '';
    final liveKitUrl = message.data['liveKitUrl'] ?? '';
    final isVideoCall = message.data['isVideoCall'] == 'true' || message.data['isVideoCall'] == true;

   final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Incoming video/audio call notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      additionalFlags: Int32List.fromList([4, 128]), 
    );
    
    await flutterLocalNotificationsPlugin.show(
      id: callId.hashCode,
      title: isVideoCall ? '📹 Dolazni video poziv' : '📞 Dolazni poziv',
      body: callerName,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: '${callId}|${callerName}|${roomName}|${receiverToken}|${liveKitUrl}|${isVideoCall}',
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

    // Android kanal za pozive
    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'Incoming video/audio call notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(callChannel);

    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          _handleNotificationTap(details.payload!);
        }
      },
    );

    // Foreground listener - DIREKTNO otvara IncomingCallScreen
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'incoming_call') {
        _openIncomingCallScreenDirectly(message.data);
      }
    });

    // App je otvoren klikom na notifikaciju iz terminated stanja
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && message.data['type'] == 'incoming_call') {
        _handleNotificationTap(_buildPayload(message.data));
      }
    });

    // App je bio u backgroundu, korisnik kliknuo na notifikaciju
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['type'] == 'incoming_call') {
        _handleNotificationTap(_buildPayload(message.data));
      }
    });

    _initialized = true;
  }

  // Direktno otvara IncomingCallScreen (za foreground)
  static void _openIncomingCallScreenDirectly(Map<String, dynamic> data) {
    final callId = data['callId'] ?? '';
    final callerName = data['callerName'] ?? 'Nepoznat';
    final roomName = data['roomName'] ?? '';
    final receiverToken = data['receiverToken'] ?? '';
    final liveKitUrl = data['liveKitUrl'] ?? '';
    // ✅ FIX 1: čitamo isVideoCall
    final isVideoCall = data['isVideoCall'] == 'true' || data['isVideoCall'] == true;
    
    final navigatorKey = AppAccessibility.instance.navigatorKey;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callId: callId,
          callerName: callerName,
          roomName: roomName,
          receiverToken: receiverToken,
          liveKitUrl: liveKitUrl,
          isVideoCall: isVideoCall, // ✅ FIX 1: prosljeđujemo tip poziva
        ),
      ),
    );
  }

  // Prikazuje sistemsku notifikaciju
  static Future<void> showIncomingCallNotification({
    required String callId,
    required String callerName,
    required String roomName,
    required String receiverToken,
    required String liveKitUrl,
    bool isVideoCall = true, // ✅ FIX 1: novi parametar
  }) async {
    final payload = _buildPayloadFromParts(
      callId: callId,
      callerName: callerName,
      roomName: roomName,
      receiverToken: receiverToken,
      liveKitUrl: liveKitUrl,
      isVideoCall: isVideoCall, // ✅ FIX 1
    );

    final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Incoming video/audio call notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      // ✅ FIX 2: FLAG_SHOW_WHEN_LOCKED (4) + FLAG_TURN_SCREEN_ON (128)
      additionalFlags: Int32List.fromList([4, 128]),
      actions: [
        const AndroidNotificationAction(
          'decline_call',
          'Odbij',
          cancelNotification: true,
          showsUserInterface: true, 
        ),
        const AndroidNotificationAction(
          'accept_call',
          'Prihvati',
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );

    await _localNotifications.show(
      id: callId.hashCode,
      title: isVideoCall ? '📹 Dolazni video poziv' : '📞 Dolazni poziv',
      body: callerName,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<void> cancelCallNotification(String callId) async {
    await _localNotifications.cancel(id: callId.hashCode);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String _buildPayload(Map<String, dynamic> data) {
    return _buildPayloadFromParts(
      callId: data['callId'] ?? '',
      callerName: data['callerName'] ?? '',
      roomName: data['roomName'] ?? '',
      receiverToken: data['receiverToken'] ?? '',
      liveKitUrl: data['liveKitUrl'] ?? '',
      // ✅ FIX 1: čitamo isVideoCall
      isVideoCall: data['isVideoCall'] == 'true' || data['isVideoCall'] == true,
    );
  }

  static String _buildPayloadFromParts({
    required String callId,
    required String callerName,
    required String roomName,
    required String receiverToken,
    required String liveKitUrl,
    bool isVideoCall = true, // ✅ FIX 1
  }) {
    // ✅ FIX 1: dodajemo isVideoCall na kraj payloada
    return '$callId|$callerName|$roomName|$receiverToken|$liveKitUrl|$isVideoCall';
  }

  static Map<String, String> parsePayload(String payload) {
    final parts = payload.split('|');
    return {
      'callId': parts.isNotEmpty ? parts[0] : '',
      'callerName': parts.length > 1 ? parts[1] : '',
      'roomName': parts.length > 2 ? parts[2] : '',
      'receiverToken': parts.length > 3 ? parts[3] : '',
      'liveKitUrl': parts.length > 4 ? parts[4] : '',
      // ✅ FIX 1: parsiramo isVideoCall (default 'true' za stare payloade)
      'isVideoCall': parts.length > 5 ? parts[5] : 'true',
    };
  }

  static void _handleNotificationTap(String payload) {
    final data = parsePayload(payload);
    final callId = data['callId'] ?? '';
    
    // Prvo otkaži notifikaciju
    cancelCallNotification(callId);
    
    // Proveri status poziva u Firestore-u
    FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .get()
        .then((doc) {
      if (!doc.exists) return;
      
      final status = doc.data()?['status'] ?? '';
      
      if (status == 'ended' || status == 'declined' || status == 'missed') {
        print('Poziv $callId je već završen (status: $status)');
        return;
      }
      
      // ✅ FIX 1: čitamo isVideoCall iz payloada
      final isVideoCall = data['isVideoCall'] == 'true';

      final navigatorKey = AppAccessibility.instance.navigatorKey;
      final context = navigatorKey.currentContext;
      if (context == null) return;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callId: data['callId']!,
            callerName: data['callerName']!,
            roomName: data['roomName']!,
            receiverToken: data['receiverToken']!,
            liveKitUrl: data['liveKitUrl']!,
            isVideoCall: isVideoCall, // ✅ FIX 1
          ),
        ),
      );
    });
  }
}