import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myschool/models/Code.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/group.dart';
import 'package:myschool/models/homework.dart';
import 'package:myschool/models/message.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/messaging.dart';
import 'package:myschool/shared/constants.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final String uid;
  DatabaseService({this.uid});

  static final FirebaseFirestore _database = FirebaseFirestore.instance;

  final CollectionReference _usersCollection = _database.collection('users');
  final CollectionReference _codesCollection = _database.collection('codes');
  final CollectionReference _schoolsCollection =
      _database.collection('schools');

  Future<bool> HWIDBanned() async {
    try {
      return (await _database.collection('banlist').doc(uid).get()).exists;
    } catch (_) {
      return false;
    }
  }

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

  static Future<bool> deleteAnnounce(DocumentReference reference) async {
    try {
      await reference.delete();
      return true;
    } catch (_) {
      print(_);
      return false;
    }
  }

  static Future<bool> deleteHomework(DocumentReference reference) async {
    try {
      await reference.delete();
      return true;
    } catch (_) {
      print(_);
      return false;
    }
  }

  static Future<bool> deleteMessage(DocumentReference reference) async {
    try {
      await reference.delete();
      return true;
    } catch (_) {
      print(_);
      return false;
    }
  }

  Future<bool> sendMessage(
      String content, UserData author, String group) async {
    try {
      await _schoolsCollection
          .doc(uid)
          .collection('groups')
          .doc(group)
          .collection('messages')
          .add({
        'author': _usersCollection.doc(author.uid),
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // notification

      String topic = author.school.uid + '-' + group;
      // unsubscribing to avoid receiving the notification even if its us who sent it
      FirebaseMessaging.instance.unsubscribeFromTopic(topic);

      MessagingService.sendMessageToTopic(
              '${author.firstName} a envoyé un nouveau message dans ' + group,
              content,
              topic,
              'message')
          .then((_) => FirebaseMessaging.instance
              .subscribeToTopic(topic)); // subscribing again

      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> createAnnounce(
      String title, String content, dynamic scope, UserData user) async {
    try {
      if (scope == Scope.school) {
        await _schoolsCollection.doc(uid).collection('announcements').add({
          'title': title,
          'content': content,
          'author': _usersCollection.doc(user.uid),
          'createdAt': FieldValue.serverTimestamp()
        });
        // notification

        String topic = user.school.uid;
        // unsubscribing to avoid receiving the notification even if its us who sent it
        FirebaseMessaging.instance.unsubscribeFromTopic(topic);

        MessagingService.sendMessageToTopic(
                '${user.firstName} a posté une nouvelle annonce!',
                title,
                topic,
                'announce')
            .then((_) => // subscribing again
                FirebaseMessaging.instance.subscribeToTopic(topic));
      } else {
        await _schoolsCollection
            .doc(uid)
            .collection('groups')
            // make sure its a string
            .doc(scope.toString())
            .collection('announcements')
            .add({
          'title': title,
          'content': content,
          'author': _usersCollection.doc(user.uid),
          'createdAt': FieldValue.serverTimestamp()
        });

        // notification

        String topic = user.school.uid + '-' + scope.toString();
        // unsubscribing to avoid receiving the notification even if its us who sent it
        FirebaseMessaging.instance.unsubscribeFromTopic(topic);

        MessagingService.sendMessageToTopic(
                '${user.firstName} a posté une nouvelle annonce!',
                title,
                user.school.uid + '-' + scope.toString(),
                'announce')
            .then((_) => // subscribing again
                FirebaseMessaging.instance.subscribeToTopic(topic));
      }
      return true;
    } catch (_) {
      print(_);
      return false;
    }
  }

  Future<bool> createHomework(String title, String description, String subject,
      UserData user, DateTime due, String group) async {
    try {
      await _schoolsCollection
          .doc(uid)
          .collection('groups')
          .doc(group)
          .collection('homeworks')
          .add({
        'title': title,
        'description': description,
        'subject': subject,
        'author': _usersCollection.doc(user.uid),
        'due': due,
        'createdAt': FieldValue.serverTimestamp()
      });

      // notification

      String topic = user.school.uid + '-' + group;
      // unsubscribing to avoid receiving the notification even if its us who sent it
      FirebaseMessaging.instance.unsubscribeFromTopic(topic);

      MessagingService.sendMessageToTopic(
              '${user.firstName} a posté un nouveau devoir en $subject!',
              title,
              user.school.uid + '-' + group,
              'homework')
          .then((_) => // subscribing again
              FirebaseMessaging.instance.subscribeToTopic(topic));

      return true;
    } catch (_) {
      print(_);
      return false;
    }
  }

  Future incrementCodeUsage() {
    return _codesCollection
        .doc(uid)
        .update({"usedTimes": FieldValue.increment(1)});
  }

  static Announcement announcementFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return Announcement(
        uid: snapshot.reference.id,
        scope: snapshot.reference.parent.parent.parent.id == 'schools'
            ? Scope.school
            : Scope.group,
        title: data['title'],
        content: data['content'],
        createdAt: (data['createdAt'] as Timestamp ??
                Timestamp.fromMillisecondsSinceEpoch(0))
            .toDate(),
        author: data['author'].id,
        reference: snapshot.reference);
  }

  static Homework homeworkFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return Homework(
        uid: snapshot.reference.id,
        author: data['author'].id,
        title: data['title'],
        description: data['description'],
        subject: data['subject'],
        due: (data['createdAt'] as Timestamp ??
                Timestamp.fromMillisecondsSinceEpoch(0))
            .toDate(),
        createdAt: (data['createdAt'] as Timestamp ??
                Timestamp.fromMillisecondsSinceEpoch(0))
            .toDate(),
        reference: snapshot.reference);
  }

  static Message messageFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return Message(
        uid: snapshot.reference.id,
        author: data['author'],
        content: data['content'],
        createdAt: (data['createdAt'] as Timestamp ??
                Timestamp.fromMillisecondsSinceEpoch(0))
            .toDate(),
        reference: snapshot.reference);
  }

  static UserData userDataFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    // Student
    if (userTypeDefinitions[data['type']] == UserType.student)
      return UserData(
        uid: snapshot.id,
        firstName: data['firstName'],
        lastName: data['lastName'],
        type: UserType.student,
        avatarUrl: data['avatarUrl'],
        usedCode: data['usedCode'],
        school: School(
            uid: data['school'].parent.parent.id,
            group: Group(uid: data['school'].id)),
        createdAt: (data['createdAt'] as Timestamp ??
                Timestamp.fromMillisecondsSinceEpoch(0))
            .toDate(),
      );

    // Teacher
    return UserData(
      uid: snapshot.id,
      firstName: data['firstName'],
      lastName: data['lastName'],
      type: UserType.teacher,
      groups: data['groups'],
      avatarUrl: data['avatarUrl'],
      usedCode: data['usedCode'],
      school: School(uid: data['school'].id),
      createdAt: (data['createdAt'] as Timestamp ??
              Timestamp.fromMillisecondsSinceEpoch(0))
          .toDate(),
    );
  }

  School schoolFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();
    return School(uid: uid, name: data['name']);
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

  static Group groupFromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data();

    return Group(uid: snapshot.id);
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

  // School announcements
  Stream<QuerySnapshot> get schoolAnnouncements {
    return _schoolsCollection
        .doc(uid)
        .collection('announcements')
        .orderBy('createdAt')
        .snapshots();
  }

  // Group announcements
  Stream<QuerySnapshot> groupAnnouncements(String groupUid) {
    return _schoolsCollection
        .doc(uid)
        .collection('groups')
        .doc(groupUid)
        .collection('announcements')
        .orderBy('createdAt')
        .snapshots();
  }

  // Group homeworks
  Stream<QuerySnapshot> groupHomeworks(String groupUid) {
    return _schoolsCollection
        .doc(uid)
        .collection('groups')
        .doc(groupUid)
        .collection('homeworks')
        .orderBy('due')
        .snapshots();
  }

  // Group messages
  Stream<QuerySnapshot> groupMessages(String groupUid) {
    return _schoolsCollection
        .doc(uid)
        .collection('groups')
        .doc(groupUid)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
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
