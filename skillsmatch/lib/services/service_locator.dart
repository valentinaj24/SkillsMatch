import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceLocator {
  static late FirebaseAuth auth;
  static late FirebaseFirestore firestore;

  static void init({
    required FirebaseAuth authInstance,
    required FirebaseFirestore firestoreInstance,
  }) {
    auth = authInstance;
    firestore = firestoreInstance;
  }
}