import 'package:myschool/models/school.dart';

class UserData {
  final String uid;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final String usedCode;
  final School school;
  final DateTime createdAt;

  UserData(
      {this.uid,
      this.firstName,
      this.lastName,
      this.avatarUrl,
      this.usedCode,
      this.school,
      this.createdAt});
}
