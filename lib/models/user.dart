import 'package:myschool/models/school.dart';
import 'package:myschool/shared/constants.dart';

class UserData {
  final String uid;
  final String firstName;
  final String lastName;
  final UserType userType;
  final String avatarUrl;
  final String usedCode;
  final School school;
  final DateTime createdAt;

  UserData(
      {this.uid,
      this.firstName,
      this.lastName,
      this.userType,
      this.avatarUrl,
      this.usedCode,
      this.school,
      this.createdAt});
}
