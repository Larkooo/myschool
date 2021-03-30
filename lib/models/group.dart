import 'package:myschool/models/announcement.dart';

import 'homework.dart';

class Group {
  final String uid;
  final List<Announcement> announcements;
  final List<Homework> homeworks;

  Group({this.uid, this.announcements, this.homeworks});
}
