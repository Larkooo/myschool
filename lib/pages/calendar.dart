import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';

class Calendar extends StatefulWidget {
  final UserData user;
  Calendar({this.user});

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text("Calendrier"),
    );
  }
}
