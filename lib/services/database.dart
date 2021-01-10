import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myschool/models/Code.dart';
import 'package:myschool/models/announcement.dart';
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
        createdAt: (data['createdAt'] as Timestamp).toDate());
  }

  School _schoolFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    print(snapshot.reference.collection('announcements').id);
    return School(
        uid: uid,
        name: data['name'],
        annoucements: (data['announcements'] as Map).map((id, announcement) =>
            MapEntry(
                id,
                Announcement(
                    uid: id,
                    title: announcement['title'],
                    description: announcement['description'],
                    createdAt:
                        (announcement['createdAt'] as Timestamp).toDate(),
                    author: announcement['author']))));
  }

  Code _codeFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return Code(
        uid: data['uid'],
        school: School(uid: (data['school'] as DocumentReference).id),
        type: data['type'],
        usedTimes: data['usedTimes'],
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
  Stream<Code> get code {
    return codesCollection.doc(uid).snapshots().map(_codeFromSnapshot);
  }

  // School doc stream
  Stream<School> get school {
    return schoolsCollection.doc(uid).snapshots().map(_schoolFromSnapshot);
  }
}
