import 'package:cloud_firestore/cloud_firestore.dart';

class Homework {
  final int uid;
  final String title;
  final String description;
  final String subject;
  final dynamic author;
  final DateTime due;
  final DateTime createdAt;
  final DocumentReference reference;
  final Map raw;

  Homework(
      {this.uid,
      this.title,
      this.description,
      this.subject,
      this.author,
      this.due,
      this.createdAt,
      this.reference,
      this.raw});
}
