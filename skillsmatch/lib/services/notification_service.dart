import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await saveFcmToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _saveTokenToFirestore(token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('FOREGROUND NOTIFICATION: ${message.notification?.title}');
      _showLocalNotification(message);
    });
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings: initSettings);
  }

  static Future<void> saveFcmToken() async {
    final token = await _messaging.getToken();

    print('FCM TOKEN = $token');
    print('CURRENT UID = ${FirebaseAuth.instance.currentUser?.uid}');
    if (token == null) return;

    await _saveTokenToFirestore(token);
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'Chat notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: 1,
      title: message.notification?.title ?? 'Novo sporočilo',
      body: message.notification?.body ?? 'Prejela si novo sporočilo.',
      notificationDetails: details,
      payload: 'chat_message',
    );
  }
}
