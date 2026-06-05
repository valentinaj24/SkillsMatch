import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillsmatch/main.dart' as app;
import 'package:skillsmatch/screens/login_screen.dart';
import 'package:skillsmatch/screens/profile_screen.dart';
import 'package:skillsmatch/screens/main_navigation_screen.dart';
import 'package:skillsmatch/screens/create_collaboration_screen.dart';
import 'package:skillsmatch/screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const receiverUid = 'lOx6BVNITPu6KhW1vZ0K0ZXZy2qS';


  // Helper za unos teksta sa pauzom
  // Za login koristiti jednostavan enterText jer nema scroll problema
    Future<void> enterTextWithPump(WidgetTester tester, Key key, String text) async {
      await tester.tap(find.byKey(key));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byKey(key), text);
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> typeInField(
      WidgetTester tester,
      Key key,
      String text,
    ) async {
      final finder = find.byKey(key);

      expect(
        finder,
        findsOneWidget,
        reason: 'Widget sa key=$key nije pronađen',
      );

      await tester.ensureVisible(finder);
      await tester.pump();

      await tester.enterText(finder, text);
      await tester.pump();

      final controller =
          tester.widget<TextField>(finder).controller;

      debugPrint('$key => "${controller?.text}"');
    }
      


  testWidgets(
      'Pun flow: registracija -> prijava -> profil -> sodelovanje -> chat',
      (tester) async {

     final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
     const testPassword = 'StrongPass123!';

     await Firebase.initializeApp();
     print('TEST PROJECT: ${Firebase.app().options.projectId}');
     print('TEST AUTH   : ${FirebaseAuth.instance.hashCode}');

      // Registruj direktno kroz Firebase SDK pre pokretanja appa
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: testEmail, password: testPassword);
      
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'ime': 'Test',
        'priimek': 'User',
        'email': testEmail,
        'telefon': '123456789',
        'lokacija': 'Ljubljana, Slovenija',
        'vloga': 'Mentor',
        'opis': '',
        'razpolozljivost': '',
        'vescine': [],
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseAuth.instance.signOut();



    // 1. Pokreni aplikaciju
    app.main();

    bool found = false;
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byKey(const Key('skip-btn')).evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }
    expect(found, isTrue, reason: 'skip-btn nije pronađen nakon 30 sekundi');

    final skipButton = find.byKey(const Key('skip-btn'));
    await tester.tap(skipButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));


        // 3. Prijava
    expect(find.byKey(const Key('email_login')), findsOneWidget);
    await typeInField(tester, const Key('email_login'), testEmail);
    await typeInField(tester, const Key('password_login'), testPassword);

    await tester.scrollUntilVisible(
      find.byKey(const Key('login_button')), 200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle(
      const Duration(seconds: 15),
    );
    debugDumpApp();

    // Debug — vidi šta je na ekranu
    debugPrint('email controller: ${tester.widget<TextField>(find.byKey(const Key('email_login'))).controller?.text}');
    // 4. Kompletiranje profila
    await enterTextWithPump(tester, const Key('ime_profile'), 'Test');
    await enterTextWithPump(tester, const Key('priimek_profile'), 'User');
    await enterTextWithPump(
        tester, const Key('opis_profile'), 'Testni korisnik');
    await enterTextWithPump(tester, const Key('lokacija_profile'), 'Ljubljana');

    await enterTextWithPump(
        tester, const Key('nova_vestina_input'), 'Flutter');
    await tester.tap(find.byKey(const Key('skill_type_Lahko učim druge')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('add_skill_button')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('razpolozljivost_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Popoldan').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save_profile_button')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final okButton = find.text('V redu');
    expect(okButton, findsOneWidget);
    await tester.tap(okButton);
    await tester.pumpAndSettle();

    expect(find.byType(MainNavigationScreen), findsOneWidget);

    // 5. Skupnost tab – slanje povabila
    await tester.tap(find.byKey(const Key('nav_tab_1')));
    await tester.pumpAndSettle();

    final userTile = find.byKey(Key('user_tile_$receiverUid'));
    expect(userTile, findsOneWidget);
    await tester.tap(userTile);
    await tester.pumpAndSettle();

    expect(find.byType(CreateCollaborationScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('skill_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flutter').last);
    await tester.pumpAndSettle();

    await enterTextWithPump(tester, const Key('message_input_collaboration'),
        'Želite li zajedno učiti?');

    await tester.tap(find.byKey(const Key('date_picker')));
    await tester.pumpAndSettle();
    final nextDay = DateTime.now().add(const Duration(days: 2));
    await tester.tap(find.text(nextDay.day.toString()));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('time_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').first);
    await tester.tap(find.text('00').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('send_invitation_button')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Povabilo uspešno poslano!'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 6. Prihvatanje povabila kao Janez
    await FirebaseAuth.instance.signOut();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'janez@example.com',
      password: 'TestPass123!',
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('nav_tab_2')));
    await tester.pumpAndSettle();

    final acceptButton = find.byKey(const Key('accept_button'));
    expect(acceptButton, findsOneWidget);
    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    final confirmDialogButton = find.text('Potrdi');
    expect(confirmDialogButton, findsOneWidget);
    await tester.tap(confirmDialogButton);
    await tester.pumpAndSettle();

    final chatButton = find.text('Sporočila');
    expect(chatButton, findsOneWidget);
    await tester.tap(chatButton);
    await tester.pumpAndSettle();

    // 7. Chat
    expect(find.byType(ChatScreen), findsOneWidget);

    await enterTextWithPump(tester, const Key('message_input'), 'Pozdrav!');
    await tester.tap(find.byKey(const Key('send_button')));
    await tester.pumpAndSettle();

    expect(find.text('Pozdrav!'), findsOneWidget);
  });
}