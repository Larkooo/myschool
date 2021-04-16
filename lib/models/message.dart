import 'package:cloud_firestore/cloud_firestore.dart';

import '../shared/constants.dart';

class Message {
  final String uid;
  final String content;
  final DateTime createdAt;
  final dynamic author;
  final DocumentReference reference;

  Message({
    this.uid,
    this.content,
    this.createdAt,
    this.author,
    this.reference,
  });
}
