import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';

class HomeTeacher extends StatefulWidget {
  final UserData user;
  HomeTeacher({this.user});

  @override
  _HomeTeacherState createState() => _HomeTeacherState();
}

class _HomeTeacherState extends State<HomeTeacher> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(widget.user.firstName),
    );
  }
}
