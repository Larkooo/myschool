import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

CollectionReference users = FirebaseFirestore.instance.collection('users');

enum AuthCodes { ok, notFound, badPassword, error, emailAlreadyUsed }

Future<AuthCodes> signIn(String email, String password) async {
  try {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    return AuthCodes.ok;
  } on FirebaseAuthException catch (e) {
    if (e.code == "wrong-password") {
      return AuthCodes.badPassword;
    } else if (e.code == "user-not-found") {
      return AuthCodes.notFound;
    } else {
      return AuthCodes.error;
    }
  } catch (e) {
    print(e.code);
    return AuthCodes.error;
  }
}

Future<AuthCodes> register(String firstName, String lastName, String email,
    String password, String code) async {
  try {
    UserCredential user = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    users.add({
      "id": user.user.uid,
      "firstName": firstName,
      "lastName": lastName,
      "usedCode": code,
      "createdAt": DateTime.now(),
    });
    return AuthCodes.ok;
  } on FirebaseAuthException catch (e) {
    if (e.code == "email-already-in-use") {
      return AuthCodes.emailAlreadyUsed;
    } else {
      return AuthCodes.error;
    }
  } catch (e) {
    print(e.code);
    return AuthCodes.error;
  }
}
