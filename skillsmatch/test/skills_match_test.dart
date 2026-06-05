import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skillsmatch/services/service_locator.dart';

import 'skills_match_test.mocks.dart';

// ════════════════════════════════════════════════════════════════════════════
// POMOĆNE KLASE (logika izvučena iz ekrana)
// ════════════════════════════════════════════════════════════════════════════

class LoginValidator {
  String? validate(String email, String password) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return 'Vnesite email in geslo.';
    }
    return null;
  }

  String mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':        return 'Email naslov ni pravilen.';
      case 'user-not-found':       return 'Uporabnik s tem emailom ne obstaja.';
      case 'wrong-password':
      case 'invalid-credential':   return 'Email ali geslo ni pravilno.';
      default:                     return 'Prijava ni uspela.';
    }
  }
}

enum PwStr { empty, weak, fair, good, strong }

PwStr evalPw(String p) {
  if (p.isEmpty) return PwStr.empty;
  int s = 0;
  if (p.length >= 8) s++;
  if (p.length >= 12) s++;
  if (RegExp(r'[A-Z]').hasMatch(p)) s++;
  if (RegExp(r'[0-9]').hasMatch(p)) s++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s++;
  if (s <= 1) return PwStr.weak;
  if (s == 2) return PwStr.fair;
  if (s == 3) return PwStr.good;
  return PwStr.strong;
}

class RegisterValidator {
  String? validate({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (name.trim().isEmpty) return 'Vnesite ime.';
    if (email.trim().isEmpty) return 'Vnesite email.';
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim())) {
      return 'Email naslov ni pravilen.';
    }
    if (password.length < 6) return 'Geslo mora imeti vsaj 6 znakov.';
    if (password != confirmPassword) return 'Gesli se ne ujemata.';
    return null;
  }
}

class InvitationValidator {
  String? validate({
    required String requesterId,
    required String receiverId,
    required String? selectedSkill,
    required DateTime? meetingDateTime,
  }) {
    if (requesterId.isEmpty) return 'Uporabnik ni prijavljen.';
    if (receiverId.isEmpty) return 'Napaka: uporabnik nima veljavnega ID-ja.';
    if (requesterId == receiverId) return 'Ne moreš poslati povabila samemu sebi.';
    if (selectedSkill == null || selectedSkill.trim().isEmpty) return 'Izberi veščino.';
    if (meetingDateTime == null) return 'Izberi datum in uro.';
    if (meetingDateTime.isBefore(DateTime.now())) return 'Izberi termin v prihodnosti.';
    return null;
  }
}

List<String> extractSkillNames(List skills) {
  return skills
      .map((skill) {
        if (skill is Map && skill['naziv'] != null) {
          return skill['naziv'].toString().trim();
        }
        return '';
      })
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();
}

String getReceiverName(Map<String, dynamic> userData) {
  final ime = (userData['ime'] ?? '').toString().trim();
  final priimek = (userData['priimek'] ?? '').toString().trim();
  final fullName = '$ime $priimek'.trim();
  return fullName.isEmpty ? 'Neznan uporabnik' : fullName;
}

// Logika iz _sendMessage() u chat_screen.dart
class MessageValidator {
  String? validate({
    required String text,
    required String currentUid,
    required bool isSending,
  }) {
    if (text.trim().isEmpty) return 'Sporočilo je prazno.';
    if (currentUid.isEmpty) return 'Uporabnik ni prijavljen.';
    if (isSending) return 'Že se pošilja.';
    return null;
  }
}

bool isProfileCompleted(Map<String, dynamic>? data) {
  if (data == null) return false;
  if (data['profileCompleted'] == true) return true;
  final ime = (data['ime'] ?? '').toString().trim();
  final lokacija = (data['lokacija'] ?? '').toString().trim();
  final vescine = data['vescine'] as List<dynamic>? ?? [];
  return ime.isNotEmpty && lokacija.isNotEmpty && vescine.isNotEmpty;
}

// ════════════════════════════════════════════════════════════════════════════
// MOCK GENERACIJA
// ════════════════════════════════════════════════════════════════════════════

@GenerateMocks([FirebaseAuth, FirebaseFirestore, UserCredential, User])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUserCredential mockCredential;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockCredential = MockUserCredential();

    ServiceLocator.init(
      authInstance: mockAuth,
      firestoreInstance: mockFirestore,
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // LOGIN
  // ══════════════════════════════════════════════════════════════════════════

  group('Login - validacija polja', () {
    final v = LoginValidator();

    test('greška ako su oba polja prazna', () {
      expect(v.validate('', ''), equals('Vnesite email in geslo.'));
    });

    test('greška ako je email prazan', () {
      expect(v.validate('', 'geslo123'), equals('Vnesite email in geslo.'));
    });

    test('greška ako je geslo prazno', () {
      expect(v.validate('janez@test.si', ''), equals('Vnesite email in geslo.'));
    });

    test('greška ako su polja samo whitespace', () {
      expect(v.validate('   ', '   '), equals('Vnesite email in geslo.'));
    });

    test('OK ako su oba polja popunjena', () {
      expect(v.validate('janez@test.si', 'geslo123'), isNull);
    });
  });

  group('Login - mapiranje Firebase grešaka', () {
    final v = LoginValidator();

    test('invalid-email', () {
      expect(v.mapFirebaseError('invalid-email'), equals('Email naslov ni pravilen.'));
    });

    test('user-not-found', () {
      expect(v.mapFirebaseError('user-not-found'), equals('Uporabnik s tem emailom ne obstaja.'));
    });

    test('wrong-password', () {
      expect(v.mapFirebaseError('wrong-password'), equals('Email ali geslo ni pravilno.'));
    });

    test('invalid-credential', () {
      expect(v.mapFirebaseError('invalid-credential'), equals('Email ali geslo ni pravilno.'));
    });

    test('nepoznat kod → generična poruka', () {
      expect(v.mapFirebaseError('network-request-failed'), equals('Prijava ni uspela.'));
    });
  });

  group('Login - uspješan scenarij', () {
    test('ispravni podaci → login prolazi bez greške', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: 'janez@test.si',
        password: 'geslo123',
      )).thenAnswer((_) async => mockCredential);

      await expectLater(
        ServiceLocator.auth.signInWithEmailAndPassword(
          email: 'janez@test.si',
          password: 'geslo123',
        ),
        completes,
      );
    });

    test('login vraća UserCredential', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: 'janez@test.si',
        password: 'geslo123',
      )).thenAnswer((_) async => mockCredential);

      final result = await ServiceLocator.auth.signInWithEmailAndPassword(
        email: 'janez@test.si',
        password: 'geslo123',
      );

      expect(result, isA<UserCredential>());
    });

    test('baca FirebaseAuthException za pogrešne kredencijale', () {
      when(mockAuth.signInWithEmailAndPassword(
        email: 'janez@test.si',
        password: 'pogresno',
      )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => ServiceLocator.auth.signInWithEmailAndPassword(
          email: 'janez@test.si',
          password: 'pogresno',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // REGISTER
  // ══════════════════════════════════════════════════════════════════════════

  group('Register - jačina passworda', () {
    test('prazan string → empty', () {
      expect(evalPw(''), equals(PwStr.empty));
    });

    test('kratko bez specijalnih → weak', () {
      expect(evalPw('abc'), equals(PwStr.weak));
    });

    test('8 znakova + veliko slovo → fair', () {
      expect(evalPw('abcdefgH'), equals(PwStr.fair));
    });

    test('8 znakova + veliko + broj → good', () {
      expect(evalPw('Abcdef12'), equals(PwStr.good));
    });

    test('12+ znakova + veliko + broj + specijal → strong', () {
      expect(evalPw('Geslo@123456!'), equals(PwStr.strong));
    });
  });

  group('Register - validacija forme', () {
    final v = RegisterValidator();

    test('greška ako je ime prazno', () {
      expect(
        v.validate(name: '', email: 'a@b.si', password: 'geslo123', confirmPassword: 'geslo123'),
        equals('Vnesite ime.'),
      );
    });

    test('greška za nevažeći email', () {
      expect(
        v.validate(name: 'Janez', email: 'nije-email', password: 'geslo123', confirmPassword: 'geslo123'),
        equals('Email naslov ni pravilen.'),
      );
    });

    test('greška ako je geslo kraće od 6 znakova', () {
      expect(
        v.validate(name: 'Janez', email: 'a@b.si', password: '123', confirmPassword: '123'),
        equals('Geslo mora imeti vsaj 6 znakov.'),
      );
    });

    test('greška ako se gesla ne podudaraju', () {
      expect(
        v.validate(name: 'Janez', email: 'a@b.si', password: 'geslo123', confirmPassword: 'drugogeslo'),
        equals('Gesli se ne ujemata.'),
      );
    });

    test('OK za ispravne podatke', () {
      expect(
        v.validate(name: 'Janez', email: 'janez@test.si', password: 'geslo123', confirmPassword: 'geslo123'),
        isNull,
      );
    });
  });

  group('Register - uspješan scenarij', () {
    test('ispravni podaci → registracija prolazi bez greške', () async {
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'novi@test.si',
        password: 'geslo123',
      )).thenAnswer((_) async => mockCredential);

      await expectLater(
        ServiceLocator.auth.createUserWithEmailAndPassword(
          email: 'novi@test.si',
          password: 'geslo123',
        ),
        completes,
      );
    });

    test('registracija vraća UserCredential', () async {
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'novi@test.si',
        password: 'geslo123',
      )).thenAnswer((_) async => mockCredential);

      final result = await ServiceLocator.auth.createUserWithEmailAndPassword(
        email: 'novi@test.si',
        password: 'geslo123',
      );

      expect(result, isA<UserCredential>());
    });

    test('baca exception za već postojeći email', () {
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'postoji@test.si',
        password: 'geslo123',
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        () => ServiceLocator.auth.createUserWithEmailAndPassword(
          email: 'postoji@test.si',
          password: 'geslo123',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SLANJE POZIVNICE
  // ══════════════════════════════════════════════════════════════════════════

  group('Pozivnica - uspješan scenarij', () {
    final v = InvitationValidator();

    test('korisnik A šalje pozivnicu korisniku B za vještinu Flutter', () {
      final result = v.validate(
        requesterId: 'korisnik-a',
        receiverId: 'korisnik-b',
        selectedSkill: 'Flutter',
        meetingDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      expect(result, isNull);
    });
  });

  group('Pozivnica - neuspješni scenariji', () {
    final v = InvitationValidator();

    test('greška ako korisnik nije ulogovan', () {
      expect(
        v.validate(requesterId: '', receiverId: 'user-b', selectedSkill: 'Flutter', meetingDateTime: DateTime.now().add(const Duration(days: 1))),
        equals('Uporabnik ni prijavljen.'),
      );
    });

    test('greška ako receiverId prazan', () {
      expect(
        v.validate(requesterId: 'user-a', receiverId: '', selectedSkill: 'Flutter', meetingDateTime: DateTime.now().add(const Duration(days: 1))),
        equals('Napaka: uporabnik nima veljavnega ID-ja.'),
      );
    });

    test('greška ako korisnik šalje sebi', () {
      expect(
        v.validate(requesterId: 'isti', receiverId: 'isti', selectedSkill: 'Flutter', meetingDateTime: DateTime.now().add(const Duration(days: 1))),
        equals('Ne moreš poslati povabila samemu sebi.'),
      );
    });

    test('greška ako vještina nije odabrana', () {
      expect(
        v.validate(requesterId: 'user-a', receiverId: 'user-b', selectedSkill: null, meetingDateTime: DateTime.now().add(const Duration(days: 1))),
        equals('Izberi veščino.'),
      );
    });

    test('greška ako je termin u prošlosti', () {
      expect(
        v.validate(requesterId: 'user-a', receiverId: 'user-b', selectedSkill: 'Flutter', meetingDateTime: DateTime.now().subtract(const Duration(hours: 1))),
        equals('Izberi termin v prihodnosti.'),
      );
    });
  });

  group('Pozivnica - skillNames ekstrakcija', () {
    test('B ima Flutter i Dart → lista sadrži oboje', () {
      final names = extractSkillNames([
        {'naziv': 'Flutter'},
        {'naziv': 'Dart'},
      ]);
      expect(names, containsAll(['Flutter', 'Dart']));
    });

    test('prazna lista → nema opcija', () {
      expect(extractSkillNames([]), isEmpty);
    });

    test('duplikati se uklanjaju', () {
      final names = extractSkillNames([
        {'naziv': 'Flutter'},
        {'naziv': 'Flutter'},
      ]);
      expect(names.length, equals(1));
    });
  });

  group('Pozivnica - receiverName', () {
    test('ime i priimek → puno ime', () {
      expect(getReceiverName({'ime': 'Ana', 'priimek': 'Novak'}), equals('Ana Novak'));
    });

    test('prazni podaci → Neznan uporabnik', () {
      expect(getReceiverName({}), equals('Neznan uporabnik'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // CHAT - SLANJE PORUKE
  // ══════════════════════════════════════════════════════════════════════════

  group('Chat - validacija poruke', () {
    final v = MessageValidator();

    test('greška ako je poruka prazna', () {
      expect(
        v.validate(text: '', currentUid: 'user-a', isSending: false),
        equals('Sporočilo je prazno.'),
      );
    });

    test('greška ako je poruka samo whitespace', () {
      expect(
        v.validate(text: '   ', currentUid: 'user-a', isSending: false),
        equals('Sporočilo je prazno.'),
      );
    });

    test('greška ako korisnik nije ulogovan', () {
      expect(
        v.validate(text: 'Zdravo!', currentUid: '', isSending: false),
        equals('Uporabnik ni prijavljen.'),
      );
    });

    test('greška ako se već šalje poruka', () {
      expect(
        v.validate(text: 'Zdravo!', currentUid: 'user-a', isSending: true),
        equals('Že se pošilja.'),
      );
    });

    test('OK za ispravnu poruku', () {
      expect(
        v.validate(text: 'Zdravo!', currentUid: 'user-a', isSending: false),
        isNull,
      );
    });
  });

  group('Chat - uspješan scenarij slanja poruke', () {
    final v = MessageValidator();

    test('korisnik A šalje poruku korisniku B', () {
      final result = v.validate(
        text: 'Živjo, bi se učil Flutter?',
        currentUid: 'korisnik-a',
        isSending: false,
      );
      expect(result, isNull);
    });

    test('poruka sa emojiem prolazi validaciju', () {
      final result = v.validate(
        text: 'Zdravo! 👋',
        currentUid: 'korisnik-a',
        isSending: false,
      );
      expect(result, isNull);
    });

    test('duga poruka prolazi validaciju', () {
      final result = v.validate(
        text: 'Pozdravljeni! Zanima me vaša veščina Flutter razvoja. '
            'Ali bi bili pripravljeni na sodelovanje?',
        currentUid: 'korisnik-a',
        isSending: false,
      );
      expect(result, isNull);
    });
  });
}