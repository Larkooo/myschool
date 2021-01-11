import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/services/database.dart';
import '../models/user.dart';

enum AuthCodes {
  ok,
  accountNotFound,
  badPassword,
  error,
  emailAlreadyUsed,
  codeNotFound,
  passwordResetCodeExpired,
  passwordResetCodeInvalid,
  accountDisabled
}

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  static final CollectionReference codes =
      FirebaseFirestore.instance.collection('codes');

  static Future<UserData> userToUserData(User user) {
    users.doc(user.uid).get().then((doc) {
      if (!doc.exists) {
        return null;
      }
      Map<String, dynamic> data = doc.data();
      return UserData(
          uid: user.uid,
          firstName: data['firstName'],
          lastName: data['lastName'],
          school: School(uid: doc.get('school')['id']),
          createdAt: data['createdAt']);
    });
  }

  static Stream<User> get user {
    return _auth.authStateChanges();
  }

  static Future<bool> deleteUser(User user) async {
    try {
      await user.delete();
      await users.doc(user.uid).delete();
      return true;
    } on FirebaseAuthException catch (e) {
      print(e);
      return false;
    }
  }

  static Future<dynamic> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      return result.user;
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

  static Future<dynamic> register(String firstName, String lastName,
      String email, String password, String code) async {
    try {
      DocumentSnapshot codeSnapshot = await codes.doc(code).get();

      if (!codeSnapshot.exists) {
        return AuthCodes.codeNotFound;
      }
      Map<String, dynamic> codeData = codeSnapshot.data();
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await DatabaseService(uid: code).incrementCodeUsage();
      await users.doc(result.user.uid).set({
        "firstName": firstName,
        "lastName": lastName,
        "avatarUrl": null,
        "school": codeData['school'],
        "usedCode": code,
        "createdAt": DateTime.now()
      });
      return UserData(
          uid: result.user.uid,
          firstName: firstName,
          lastName: lastName,
          avatarUrl: null,
          school: School(uid: (codeData['school'] as DocumentReference).id),
          usedCode: code,
          createdAt: DateTime.now());
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return AuthCodes.emailAlreadyUsed;
      } else {
        print(e);
        return AuthCodes.error;
      }
    } catch (e) {
      print(e.code);
      return AuthCodes.error;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
    }
  }

  static Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<AuthCodes> checkResetPasswordCode(
      String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return AuthCodes.ok;
    } on FirebaseAuthException catch (e) {
      if (e.code == "expired-action-code") {
        return AuthCodes.passwordResetCodeExpired;
      } else if (e.code == "invalid-action-code") {
        return AuthCodes.passwordResetCodeInvalid;
      } else if (e.code == "user-disabled") {
        return AuthCodes.accountDisabled;
      } else if (e.code == "user-not-found") {
        return AuthCodes.accountNotFound;
      } else {
        return AuthCodes.error;
      }
    }
  }
}
