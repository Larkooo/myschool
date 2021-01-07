import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myschool/models/school.dart';
import '../models/user.dart';

enum AuthCodes {
  ok,
  accountNotFound,
  badPassword,
  error,
  emailAlreadyUsed,
  codeNotFound
}

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  static final CollectionReference codes =
      FirebaseFirestore.instance.collection('codes');

  static Future<UserData> userToUserData(User user,
      [Map<String, dynamic> data]) async {
    if (data.isEmpty) {
      codes.doc(user.uid).get().then((doc) async {
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
    } else {
      return UserData(
          uid: user.uid,
          firstName: data['firstName'],
          lastName: data['lastName'],
          school: School(uid: data['id']),
          createdAt: data['createdAt']);
    }
  }

  static Stream<User> get user {
    return _auth.authStateChanges();
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
      codes.doc(code).get().then((doc) async {
        if (!doc.exists) {
          return AuthCodes.codeNotFound;
        }
        Map<String, dynamic> data = doc.data();
        UserCredential result = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        codes.doc(code).update({"usedTimes": FieldValue.increment(1)});
        users.doc(result.user.uid).set({
          "firstName": firstName,
          "lastName": lastName,
          "school": data['school'],
          "usedCode": code,
          "createdAt": DateTime.now()
        });
        return result.user;
        //return UserData(
        //    uid: result.user.uid,
        //    firstName: firstName,
        //    lastName: lastName,
        //    school: School(uid: doc.get("school")['id']),
        //    createdAt: DateTime.now());
      });
      //return AuthCodes.ok;
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

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
    }
  }
}
