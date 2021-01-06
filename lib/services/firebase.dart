import 'package:firebase_auth/firebase_auth.dart';

Future<void> signIn(String email, String password) async {}
Future<void> register(String email, String password) async {
  try {
    await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
  } catch (e) {
    if (e.code == "email-already-in-use") {
      return "s";
    }
  }
}
