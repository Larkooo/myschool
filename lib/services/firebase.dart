import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

CollectionReference users = FirebaseFirestore.instance.collection('users');
CollectionReference codes = FirebaseFirestore.instance.collection('codes');

enum AuthCodes {
  ok,
  accountNotFound,
  badPassword,
  error,
  emailAlreadyUsed,
  codeNotFound
}

Future<AuthCodes> signIn(String email, String password) async {
  try {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    return AuthCodes.ok;
  } on FirebaseAuthException catch (e) {
    if (e.code == "wrong-password") {
      return AuthCodes.badPassword;
    } else if (e.code == "user-not-found") {
      return AuthCodes.accountNotFound;
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
    codes.doc(code).get().then((doc) async {
      if (!doc.exists) {
        return AuthCodes.codeNotFound;
      }
      Map<String, dynamic> data = doc.data();
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      codes.doc(code).update({"usedTimes": data['usedTimes']});
      users.doc(user.user.uid).set({
        "firstName": firstName,
        "lastName": lastName,
        "school": data['school'],
        "usedCode": code,
        "createdAt": DateTime.now()
      });
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
