import 'package:cloud_firestore/cloud_firestore.dart';

import '../shared/constants.dart';

class Announcement {
  final int uid;
  final String title;
  final String content;
  final DateTime createdAt;
  final String author;
  final Scope scope;
  final DocumentReference reference;
  final Map<dynamic, dynamic> raw;

  Announcement(
      {this.uid,
      this.title,
      this.content,
      this.createdAt,
      this.author,
      this.scope,
      this.reference,
      this.raw});
}
