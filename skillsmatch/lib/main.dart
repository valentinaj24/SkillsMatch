import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ ADD THIS for kDebugMode
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/splash_onboarding.dart';
import 'screens/profile_screen.dart';
import 'accessibility/app_accessibility.dart';
import 'accessibility/accessibility_wrapper.dart';
import 'screens/auth_gate.dart';
import 'services/notification_service.dart';
import 'services/call_notification_service.dart';
import 'theme/app_colors.dart';
import 'services/service_locator.dart';

// ─── Global theme notifier ────────────────────────────────────────────────────
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> _checkPermissions() async {
  var status = await Permission.bluetooth.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Permission disabled');
  }
  status = await Permission.bluetoothConnect.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Connect Permission disabled');
  }
}

Future<void> _initializeAndroidAudioSettings() async {
  await webrtc.WebRTC.initialize(
    options: {
      'androidAudioConfiguration': webrtc
          .AndroidAudioConfiguration
          .communication
          .toMap(),
    },
  );
  await webrtc.Helper.setAndroidAudioConfiguration(
    webrtc.AndroidAudioConfiguration.communication,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final fcm = FirebaseMessaging.instance;
  NotificationSettings settings = await fcm.requestPermission();
  print('🔔 FCM permission: ${settings.authorizationStatus}');
  String? token = await fcm.getToken();
  print('🔑 FCM token: $token');
  if (token == null) print('❌ FCM token is NULL! Check google-services.json and permissions.');


  // Inicijalizuj oba servisa
  await NotificationService.init();
  await CallNotificationService.init();

  // Postavi background handler za FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await AppAccessibility.instance.load();
  await _checkPermissions();
  await _initializeAndroidAudioSettings();

  ServiceLocator.init(
    authInstance: FirebaseAuth.instance,
    firestoreInstance: FirebaseFirestore.instance,
  );

  runApp(const SkillsMatchApp());
}

class SkillsMatchApp extends StatelessWidget {
  const SkillsMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, _, __) => AnimatedBuilder(
        animation: AppAccessibility.instance,
        builder: (context, _) {
          final senior = AppAccessibility.instance.seniorMode;

          return MaterialApp(
            title: 'Skills Match',
            debugShowCheckedModeBanner: false,

            navigatorKey: AppAccessibility.instance.navigatorKey,

            builder: (context, child) {
              return AccessibilityWrapper(
                child: child ?? const SizedBox.shrink(),
              );
            },

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4F46E5),
              ),
              useMaterial3: true,

              textTheme: senior
                  ? ThemeData.light().textTheme.copyWith(
                      bodySmall: ThemeData.light().textTheme.bodySmall
                          ?.copyWith(fontSize: 16),
                      bodyMedium: ThemeData.light().textTheme.bodyMedium
                          ?.copyWith(fontSize: 20),
                      bodyLarge: ThemeData.light().textTheme.bodyLarge
                          ?.copyWith(fontSize: 22),
                      titleSmall: ThemeData.light().textTheme.titleSmall
                          ?.copyWith(fontSize: 20),
                      titleMedium: ThemeData.light().textTheme.titleMedium
                          ?.copyWith(fontSize: 24),
                      titleLarge: ThemeData.light().textTheme.titleLarge
                          ?.copyWith(fontSize: 30),
                      headlineSmall: ThemeData.light().textTheme.headlineSmall
                          ?.copyWith(fontSize: 34),
                      headlineMedium: ThemeData.light().textTheme.headlineMedium
                          ?.copyWith(fontSize: 38),
                    )
                  : ThemeData.light().textTheme,

              inputDecorationTheme: InputDecorationTheme(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: senior ? 22 : 16,
                ),
              ),

              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(senior ? 66 : 50),
                  textStyle: TextStyle(
                    fontSize: senior ? 20 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(senior ? 64 : 48),
                  textStyle: TextStyle(
                    fontSize: senior ? 19 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4F46E5),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              brightness: Brightness.dark,

              textTheme: senior
                  ? ThemeData.dark().textTheme.copyWith(
                      bodySmall: ThemeData.dark().textTheme.bodySmall?.copyWith(
                        fontSize: 16,
                      ),
                      bodyMedium: ThemeData.dark().textTheme.bodyMedium
                          ?.copyWith(fontSize: 20),
                      bodyLarge: ThemeData.dark().textTheme.bodyLarge?.copyWith(
                        fontSize: 22,
                      ),
                      titleSmall: ThemeData.dark().textTheme.titleSmall
                          ?.copyWith(fontSize: 20),
                      titleMedium: ThemeData.dark().textTheme.titleMedium
                          ?.copyWith(fontSize: 24),
                      titleLarge: ThemeData.dark().textTheme.titleLarge
                          ?.copyWith(fontSize: 30),
                      headlineSmall: ThemeData.dark().textTheme.headlineSmall
                          ?.copyWith(fontSize: 34),
                      headlineMedium: ThemeData.dark().textTheme.headlineMedium
                          ?.copyWith(fontSize: 38),
                    )
                  : ThemeData.dark().textTheme,

              inputDecorationTheme: InputDecorationTheme(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: senior ? 22 : 16,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(senior ? 66 : 50),
                  textStyle: TextStyle(
                    fontSize: senior ? 20 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(senior ? 64 : 48),
                  textStyle: TextStyle(
                    fontSize: senior ? 19 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            themeMode: themeModeNotifier.value,

            home: SplashScreen(
              nextScreen: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AppAccessibility.instance.setFloatingVisible(false);
                  });

                  return const AuthGate();
                },
              ),
            ),
          );
        },
      ), // AnimatedBuilder
    ); // ValueListenableBuilder
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  bool _isProfileCompleted(Map<String, dynamic>? data) {
    if (data == null) return false;

    if (data['profileCompleted'] == true) return true;

    final ime = (data['ime'] ?? '').toString().trim();
    final lokacija = (data['lokacija'] ?? '').toString().trim();
    final vescine = data['vescine'] as List<dynamic>? ?? [];

    return ime.isNotEmpty && lokacija.isNotEmpty && vescine.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;

        // Sačuvaj FCM token čim se user uloguje
        NotificationService.saveFcmToken();

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
              return const ProfileScreen();
            }

            final data = profileSnapshot.data!.data();

            if (_isProfileCompleted(data)) {
              return const MainNavigationScreen();
            }

            return const ProfileScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kBg,
      body: const Center(child: CircularProgressIndicator(color: kPrimary)),
    );
  }
}
