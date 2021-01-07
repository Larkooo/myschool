import 'package:myschool/models/school.dart';

class UserData {
  final String uid;
  final String firstName;
  final String lastName;
  final School school;
  final DateTime createdAt;

  UserData(
      {this.firstName, this.lastName, this.uid, this.school, this.createdAt});
}
