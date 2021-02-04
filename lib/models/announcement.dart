import '../shared/constants.dart';

class Announcement {
  final String uid;
  final String title;
  final String content;
  final DateTime createdAt;
  final String author;
  final Scope scope;

  Announcement(
      {this.uid,
      this.title,
      this.content,
      this.createdAt,
      this.author,
      this.scope});
}
