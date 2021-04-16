import 'package:cloud_firestore/cloud_firestore.dart';

import '../shared/constants.dart';

class Announcement {
  final String uid;
  final String title;
  final String content;
  final DateTime createdAt;
  final dynamic author;
  final Scope scope;
  final DocumentReference reference;

  Announcement({
    this.uid,
    this.title,
    this.content,
    this.createdAt,
    this.author,
    this.scope,
    this.reference,
  });
}
