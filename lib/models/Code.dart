import 'package:myschool/models/school.dart';

class Code {
  final String uid;
  final School school;
  final int type;
  final int usedTimes;
  final DateTime createdAt;

  Code({this.uid, this.school, this.type, this.usedTimes, this.createdAt});
}
