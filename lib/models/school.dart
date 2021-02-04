import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/group.dart';

class School {
  final String uid;
  final String name;
  final Group group;
  // String : ID
  final List<Announcement> announcements;
  School({this.uid, this.name, this.group, this.announcements});
}
