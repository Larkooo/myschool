import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/announce.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';

import '../../components/mozaik_login.dart';

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
        child: Column(children: [
      StreamBuilder(
          stream:
              DatabaseService(uid: widget.user.school.uid).schoolAnnouncements,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              QuerySnapshot query = snapshot.data;
              List<Announcement> announcements = query.docs
                  .map(DatabaseService.announcementFromSnapshot)
                  .toList();
              if (announcements.length > 0) {
                return Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Dernière annonce école",
                      style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width / 1.3,
                        child: Announce(announcement: announcements.last)),
                  ],
                );
              }
              return Container();
            } else {
              return CircularProgressIndicator.adaptive();
            }
          }),
    ]));
  }
}
