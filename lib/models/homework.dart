import 'package:cloud_firestore/cloud_firestore.dart';

class Homework {
  final String uid;
  final String title;
  final String description;
  final String subject;
  final dynamic author;
  final DateTime due;
  final List<String> attachments;
  final DateTime createdAt;
  final DocumentReference reference;

  Homework({
    this.uid,
    this.title,
    this.description,
    this.subject,
    this.author,
    this.due,
    this.attachments,
    this.createdAt,
    this.reference,
  });
}
