import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:provider/provider.dart';

class Announcements extends StatefulWidget {
  final UserData user;
  Announcements({this.user});

  @override
  _AnnouncementsState createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: user.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData user = snapshot.data;
            return Center(
              child: StreamBuilder(
                stream: DatabaseService(uid: user.school.uid).school,
                builder: (context, schoolSnapshot) {
                  if (schoolSnapshot.hasData) {
                    School school = schoolSnapshot.data;
                    List<String> keys = school.annoucements.keys.toList();
                    return ListView.builder(
                        itemCount: school.annoucements.length,
                        itemBuilder: (context, index) {
                          Announcement announcement =
                              school.annoucements[keys[index]];
                          return ListTile(
                            title: Text(announcement.title),
                            subtitle: Text(announcement.description),
                          );
                        });
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
