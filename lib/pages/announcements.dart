import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:provider/provider.dart';

class Announcements extends StatefulWidget {
  //final UserData user;
  //Announcements({this.user});

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
            return StreamBuilder(
              stream: DatabaseService(uid: user.school.uid).announcements,
              builder: (context, announcementsSnapshot) {
                if (announcementsSnapshot.hasData) {
                  QuerySnapshot announcements = announcementsSnapshot.data;
                  return ListView.builder(
                      itemCount: announcements.docs.length,
                      itemBuilder: (context, index) {
                        var announcement =
                            // Reversing it to get the latest added document
                            List.from(announcements.docs.reversed)[index]
                                .data();
                        return Card(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              ListTile(
                                leading: RichText(
                                    text: TextSpan(children: [
                                  WidgetSpan(child: Icon(Icons.person)),
                                  TextSpan(text: announcement['author'])
                                ])),
                                title: Text(announcement['title']),
                                subtitle: Text(announcement['description']),
                              ),
                              Row(
                                //mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Posté le " +
                                      DateFormat.yMMMMEEEEd().format(
                                          (announcement['createdAt']
                                                  as Timestamp)
                                              .toDate())),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                            ]));
                      });
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
