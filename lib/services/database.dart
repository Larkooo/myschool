import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final CollectionReference _usersCollection = _database.collection('users');
  final CollectionReference _codesCollection = _database.collection('codes');
  final CollectionReference _schoolsCollection =
      _database.collection('schools');

  Future updateUserData(
      {String firstName,
      String lastName,
      UserType userType,
      DocumentReference school,
      String avatarUrl,
      String usedCode,
      DateTime createdAt}) {
    Map<String, dynamic> data = {};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (school != null) data['schoolReference'] = school;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (usedCode != null) data['usedCode'] = usedCode;
    if (createdAt != null) data['createdAt'] = createdAt;
    return _usersCollection.doc(uid).update(data);
  }

  Future<bool> deleteAnnounce(
      Map<dynamic, dynamic> data, DocumentReference reference) async {
    try {
      if (reference.parent.id == 'schools') {
        await _schoolsCollection.doc(reference.id).update({
          'announcements': FieldValue.arrayRemove([data])
        });
      } else {
        await _schoolsCollection
            .doc(reference.parent.parent.id)
            .collection('groups')
            .doc(reference.id)
            .update({
          'announcements': FieldValue.arrayRemove([data])
        });
      }
      return true;
    } catch (_) {
      print(_);
      return false;
    }
  }

  Future<bool> createAnnounce(
      String title, String content, Scope scope, UserData user) async {
    try {
      if (scope == Scope.school) {
        await _schoolsCollection.doc(uid).update({
          'announcements': FieldValue.arrayUnion([
            {
              'title': title,
              'content': content,
              'author': _usersCollection.doc(user.uid),
              'createdAt': FieldValue.serverTimestamp()
            }
          ])
        });
      } else {
        await _schoolsCollection
            .doc(uid)
            .collection('groups')
            .doc(user.school.group.uid)
            .update({
          'announcements': FieldValue.arrayUnion([
            {
              'title': title,
              'content': content,
              'author': _usersCollection.doc(user.uid),
              'createdAt': FieldValue.serverTimestamp()
            }
          ])
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future incrementCodeUsage() {
    return _codesCollection
        .doc(uid)
        .update({"usedTimes": FieldValue.increment(1)});
  }

  Announcement announcementFromData(int index, Map<String, dynamic> data,
      Scope scope, DocumentReference reference) {
    return Announcement(
        uid: index,
        scope: scope,
        title: data['title'],
        content: data['content'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        author: data['author'].id,
        reference: reference,
        raw: data);
  }

  UserData userDataFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    // Student
    if (userTypeDefinitions[data['type']] == UserType.student)
      return UserData(
          uid: uid,
          firstName: data['firstName'],
          lastName: data['lastName'],
          userType: UserType.student,
          avatarUrl: data['avatarUrl'],
          usedCode: data['usedCode'],
          school: School(
              uid: data['school'].parent.parent.id,
              group: Group(uid: data['school'].id)),
          createdAt: (data['createdAt'] as Timestamp).toDate());

    // Teacher
    return UserData(
        uid: uid,
        firstName: data['firstName'],
        lastName: data['lastName'],
        userType: UserType.teacher,
        groups: data['groups'],
        avatarUrl: data['avatarUrl'],
        usedCode: data['usedCode'],
        school: School(uid: data['school'].id),
        createdAt: (data['createdAt'] as Timestamp).toDate());
  }

  School schoolFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    List<Announcement> announcements = List();
    int announcementCount = 0;
    data['announcements'].forEach((data) {
      announcements.add(announcementFromData(
          announcementCount,
          data,
          snapshot.reference.parent.id == "schools"
              ? Scope.school
              : Scope.group,
          snapshot.reference));
      announcementCount++;
    });
    return School(uid: uid, name: data['name'], announcements: announcements);
  }

  Code codeFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return Code(
        uid: snapshot.id,
        school: School(uid: (data['school'] as DocumentReference).id),
        type: data['type'],
        usedTimes: data['usedTimes'],
        createdAt: data['createdAt']);
  }

  Group groupFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    List<Announcement> announcements = List();
    int announcementCount = 0;
    data['announcements'].forEach((data) {
      announcements.add(announcementFromData(
          announcementCount,
          data,
          snapshot.reference.parent.id == "schools"
              ? Scope.school
              : Scope.group,
          snapshot.reference));
      announcementCount++;
    });
    return Group(uid: snapshot.id, announcements: announcements);
  }

  // Users stream
  Stream<QuerySnapshot> get users {
    return _usersCollection.snapshots();
  }

  // Codes stream
  Stream<QuerySnapshot> get codes {
    return _codesCollection.snapshots();
  }

  // Schools stream
  Stream<QuerySnapshot> get schools {
    return _schoolsCollection.snapshots();
  }

  // Groups
  Stream<QuerySnapshot> get groups {
    return _schoolsCollection.doc(uid).collection('groups').snapshots();
  }

  // User doc stream
  Stream<UserData> get user {
    return _usersCollection.doc(uid).snapshots().map(userDataFromSnapshot);
  }

  // Code doc stream
  Stream<Code> get code {
    return _codesCollection.doc(uid).snapshots().map(codeFromSnapshot);
  }

  // School doc stream
  Stream<School> get school {
    return _schoolsCollection.doc(uid).snapshots().map(schoolFromSnapshot);
  }

  // Group
  Stream<Group> group(String groupUid) {
    return _schoolsCollection
        .doc(uid)
        .collection('groups')
        .doc(groupUid)
        .snapshots()
        .map(groupFromSnapshot);
  }
}
