import 'package:myschool/models/announcement.dart';

class School {
  final String uid;
  final String name;
  // String : ID
  final Map<String, Announcement> annoucements;
  School({this.uid, this.name, this.annoucements});
}
