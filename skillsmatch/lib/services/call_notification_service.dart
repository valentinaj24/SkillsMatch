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
    
    // ✅ Za verziju 20.1.0 - koristi named parametar 'settings'
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    
    // ✅ KLJUČNO: Koristi poseban channel za full-screen
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
      // ✅ Dodaj ovo za full-screen
      additionalFlags: Int32List.fromList([4]), // FLAG_SHOW_WHEN_LOCKED
    );
    
    // ✅ Za verziju 20.1.0 - koristi named parametre
    await flutterLocalNotificationsPlugin.show(
      id: callId.hashCode,
      title: '📞 Dolazni poziv',
      body: callerName,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: '${callId}|${callerName}|${roomName}|${receiverToken}|${liveKitUrl}',
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

    // ✅ Za verziju 20.1.0 - koristi named parametre
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
  }) async {
    final payload = _buildPayloadFromParts(
      callId: callId,
      callerName: callerName,
      roomName: roomName,
      receiverToken: receiverToken,
      liveKitUrl: liveKitUrl,
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
      additionalFlags: Int32List.fromList([4]), 
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

    // ✅ Za verziju 20.1.0 - koristi named parametre
    await _localNotifications.show(
      id: callId.hashCode,
      title: '📞 Dolazni poziv',
      body: callerName,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<void> cancelCallNotification(String callId) async {
    // ✅ Za verziju 20.1.0 - koristi named parametar 'id'
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
    );
  }

  static String _buildPayloadFromParts({
    required String callId,
    required String callerName,
    required String roomName,
    required String receiverToken,
    required String liveKitUrl,
  }) {
    return '$callId|$callerName|$roomName|$receiverToken|$liveKitUrl';
  }

  static Map<String, String> parsePayload(String payload) {
    final parts = payload.split('|');
    return {
      'callId': parts.isNotEmpty ? parts[0] : '',
      'callerName': parts.length > 1 ? parts[1] : '',
      'roomName': parts.length > 2 ? parts[2] : '',
      'receiverToken': parts.length > 3 ? parts[3] : '',
      'liveKitUrl': parts.length > 4 ? parts[4] : '',
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
    
    // Ako je poziv već završen ili odbijen, ne otvaraj ekran
    if (status == 'ended' || status == 'declined' || status == 'missed') {
      print('Poziv $callId je već završen (status: $status)');
      return;
    }
    
    // Inače otvori IncomingCallScreen
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
        ),
      ),
    );
  });
}
}