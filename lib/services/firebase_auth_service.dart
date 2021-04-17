import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myschool/models/group.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

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
          type: userTypeDefinitions[data['type']],
          school: School(
              uid: doc.get('school').parent.parent.id,
              group: Group(uid: doc.get('school').id)),
          createdAt: data['createdAt']);
    });
  }

  static Stream<User> get user {
    return _auth.authStateChanges();
  }

  static Future<bool> deleteUser(User user) async {
    try {
      await users.doc(user.uid).delete();
      await user.delete();
      print('haha');
      return true;
    } on FirebaseAuthException catch (e) {
      print(e);
      return false;
    }
  }

  static Future<dynamic> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") {
        return AuthCode.badPassword;
      } else if (e.code == "user-not-found") {
        return AuthCode.accountNotFound;
      } else {
        return AuthCode.error;
      }
    } catch (e) {
      print(e.code);
      return AuthCode.error;
    }
  }

  static Future<dynamic> register(String firstName, String lastName,
      String email, String password, String code) async {
    try {
      DocumentSnapshot codeSnapshot = await codes.doc(code).get();

      if (!codeSnapshot.exists) {
        return AuthCode.codeNotFound;
      }
      Map<String, dynamic> codeData = codeSnapshot.data();
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await DatabaseService(uid: code).incrementCodeUsage();

      // Data
      Map<String, dynamic> data = {
        "firstName": firstName,
        "lastName": lastName,
        "type": codeData['type'],
        "avatarUrl": null,
        "school": codeData['school'],
        "usedCode": code,
        "createdAt": FieldValue.serverTimestamp()
      };

      // If teacher, add groups field
      if (codeData['type'] == 1) data['groups'] = [];

      await users.doc(result.user.uid).set(data);

      return UserData(
          uid: result.user.uid,
          firstName: firstName,
          lastName: lastName,
          avatarUrl: null,
          type: codeData['type'] == 0 ? UserType.student : UserType.teacher,
          school: School(uid: (codeData['school'] as DocumentReference).id),
          usedCode: code,
          createdAt: DateTime.now());
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return AuthCode.emailAlreadyUsed;
      } else {
        print(e);
        return AuthCode.error;
      }
    } catch (e) {
      print(e.code);
      return AuthCode.error;
    }
  }

  static Future<void> signOut(UserData user) async {
    try {
      // unsubscribe from user topics
      FirebaseMessaging fcm = FirebaseMessaging.instance;
      fcm.unsubscribeFromTopic(user.school.uid);
      if (user.type == UserType.student) {
        fcm.unsubscribeFromTopic(user.school.group.uid);
      } else {
        user.groups.forEach((group) {
          fcm.unsubscribeFromTopic(user.school.uid + '-' + group);
        });
      }
      await _auth.signOut();
      await LocalStorage.clearSensitiveInfo();
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

  static Future<AuthCode> checkResetPasswordCode(
      String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return AuthCode.ok;
    } on FirebaseAuthException catch (e) {
      if (e.code == "expired-action-code") {
        return AuthCode.passwordResetCodeExpired;
      } else if (e.code == "invalid-action-code") {
        return AuthCode.passwordResetCodeInvalid;
      } else if (e.code == "user-disabled") {
        return AuthCode.accountDisabled;
      } else if (e.code == "user-not-found") {
        return AuthCode.accountNotFound;
      } else {
        return AuthCode.error;
      }
    }
  }
}
