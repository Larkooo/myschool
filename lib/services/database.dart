import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';

class DatabaseService {
  final String uid;
  DatabaseService({this.uid});

  static final FirebaseFirestore _database = FirebaseFirestore.instance;

  final CollectionReference usersCollection = _database.collection('users');
  final CollectionReference codesCollection = _database.collection('codes');
  final CollectionReference schoolsCollection = _database.collection('schools');

  Future updateUserData(String firstName, String lastName,
      DocumentReference schoolReference, String usedCode, DateTime createdAt) {
    return usersCollection.doc(uid).set({
      "firstName": firstName,
      "lastName": lastName,
      "school": schoolReference,
      "usedCode": usedCode,
      "createdAt": DateTime.now()
    });
  }

  Future incrementCodeUsage() {
    return codesCollection
        .doc(uid)
        .update({"usedTimes": FieldValue.increment(1)});
  }

  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return UserData(
        uid: uid,
        firstName: data['firstName'],
        lastName: data['lastName'],
        usedCode: data['usedCode'],
        school: School(uid: data['school'].id),
        createdAt: data['createdAt']);
  }

  // Users stream
  Stream<QuerySnapshot> get users {
    return usersCollection.snapshots();
  }

  // Codes stream
  Stream<QuerySnapshot> get codes {
    return codesCollection.snapshots();
  }

  // Schools stream
  Stream<QuerySnapshot> get schools {
    return schoolsCollection.snapshots();
  }

  // User doc stream
  Stream<UserData> get user {
    return usersCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }

  // Code doc stream
  Stream<DocumentSnapshot> get code {
    return codesCollection.doc(uid).snapshots();
  }

  // School doc stream
  Stream<DocumentSnapshot> get school {
    return schoolsCollection.doc(uid).snapshots();
  }
}