import 'package:myschool/models/school.dart';
import 'package:myschool/shared/constants.dart';

import 'group.dart';

class UserData {
  final String uid;
  final String firstName;
  final String lastName;
  final UserType type;
  final String avatarUrl;
  final String usedCode;
  final School school;
  final DateTime createdAt;
  // Teacher
  List<String> groups;

  UserData(
      {this.uid,
      this.firstName,
      this.lastName,
      this.type,
      this.groups,
      this.avatarUrl,
      this.usedCode,
      this.school,
      this.createdAt});
}
