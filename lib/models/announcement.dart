import '../shared/constants.dart';

class Announcement {
  final String uid;
  final String title;
  final String description;
  final DateTime createdAt;
  final String author;
  final Scope scope;

  Announcement(
      {this.uid,
      this.title,
      this.description,
      this.createdAt,
      this.author,
      this.scope});
}
