import 'package:myschool/models/announcement.dart';

import 'homework.dart';
import 'message.dart';

class Group {
  final String uid;
  final List<Announcement> announcements;
  final List<Homework> homeworks;
  final List<Message> messages;

  Group({this.uid, this.announcements, this.homeworks, this.messages});
}
