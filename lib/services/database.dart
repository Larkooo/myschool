import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myschool/models/Code.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/group.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/constants.dart';

class DatabaseService {
  final String uid;
  DatabaseService({this.uid});

  static final FirebaseFirestore _database = FirebaseFirestore.instance;

  final CollectionReference usersCollection = _database.collection('users');
  final CollectionReference codesCollection = _database.collection('codes');
  final CollectionReference schoolsCollection = _database.collection('schools');

  Future updateUserData(
      {String firstName,
      String lastName,
      DocumentReference schoolReference,
      String avatarUrl,
      String usedCode,
      DateTime createdAt}) {
    Map<String, dynamic> data = {};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (schoolReference != null) data['schoolReference'] = schoolReference;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (usedCode != null) data['usedCode'] = usedCode;
    if (createdAt != null) data['createdAt'] = createdAt;
    return usersCollection.doc(uid).update(data);
  }

  Future incrementCodeUsage() {
    return codesCollection
        .doc(uid)
        .update({"usedTimes": FieldValue.increment(1)});
  }

  UserData userDataFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return UserData(
        uid: uid,
        firstName: data['firstName'],
        lastName: data['lastName'],
        avatarUrl: data['avatarUrl'],
        usedCode: data['usedCode'],
        school: School(
            uid: data['school'].parent.parent.id,
            group: Group(uid: data['school'].id)),
        createdAt: (data['createdAt'] as Timestamp).toDate());
  }

  School schoolFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    //print(snapshot.reference.collection('announcements').id);
    return School(
      uid: uid,
      name: data['name'],
      //annoucements: (data['announcements'] as Map).map((id, announcement) =>
      //    MapEntry(
      //        id,
      //        Announcement(
      //            uid: id,
      //            title: announcement['title'],
      //            description: announcement['description'],
      //            createdAt:
      //                (announcement['createdAt'] as Timestamp).toDate(),
      //            author: announcement['author'])))
    );
  }

  Code codeFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return Code(
        uid: data['uid'],
        school: School(uid: (data['school'] as DocumentReference).id),
        type: data['type'],
        usedTimes: data['usedTimes'],
        createdAt: data['createdAt']);
  }

  Announcement announcementFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return Announcement(
        scope: snapshot.reference.parent.parent.parent.id == "schools"
            ? Scope.school
            : Scope.group,
        uid: data['uid'],
        title: data['title'],
        description: data['description'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        author: data['author'].id);
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

  // School announcements
  Stream<QuerySnapshot> get announcements {
    return schoolsCollection.doc(uid).collection('announcements').snapshots();
  }

  // User doc stream
  Stream<UserData> get user {
    return usersCollection.doc(uid).snapshots().map(userDataFromSnapshot);
  }

  // Code doc stream
  Stream<Code> get code {
    return codesCollection.doc(uid).snapshots().map(codeFromSnapshot);
  }

  // School doc stream
  Stream<School> get school {
    return schoolsCollection.doc(uid).snapshots().map(schoolFromSnapshot);
  }
}
