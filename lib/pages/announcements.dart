import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';

class Announcements extends StatefulWidget {
  final UserData user;
  Announcements({this.user});

  @override
  _AnnouncementsState createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Annonces"));
  }
}
