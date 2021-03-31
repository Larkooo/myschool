import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:myschool/components/announce.dart';
import 'package:myschool/components/homeworkcomp.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/components/new_homework.dart';
import 'package:myschool/models/homework.dart';
import 'package:myschool/pages/register.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/settings.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../services/database.dart';
import '../models/school.dart';

class Homeworks extends StatefulWidget {
  //final UserData user;
  //Announcements({this.user});

  @override
  _HomeworksState createState() => _HomeworksState();
}

class _HomeworksState extends State<Homeworks> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: user.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData user = snapshot.data;
            // grouping different streams into a list to then merge them.
            // to get school and group(s) announcements
            List<Stream> streams = [];
            if (user.type == UserType.student) {
              streams.add(DatabaseService(uid: user.school.uid)
                  .group(user.school.group.uid));
            } else {
              user.groups.forEach((group) {
                streams.add(DatabaseService(uid: user.school.uid)
                    .group(group.toString()));
              });
            }
            return Scaffold(
              body: StreamBuilder(
                /* 
                  Merging the streams, the group(s) announcements and school ones
                  */
                stream: CombineLatestStream.list(streams),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<Homework> homeworks = [];
                    snapshot.data.forEach((e) {
                      homeworks.addAll(e.homeworks);
                    });

                    /* 
                      Sorting the homeworks by comparing their due time 
                  */
                    homeworks.sort((a, b) => b.due.compareTo(a.due));

                    // filtering homeworks
                    homeworks.removeWhere((homework) => homework.due
                                    .difference(DateTime.now())
                                    .inDays >
                                // hide homework after 14 days
                                14 ||
                            // if teacher, dont show other teachers given homeworks
                            user.type == UserType.teacher
                        ? homework.author != user.uid
                        : false);

                    return ListView.builder(
                        itemCount: homeworks.length,
                        itemBuilder: (context, index) {
                          /* 
                          Transforming our data to a a Homework 
                        */
                          Homework homework = homeworks[index];

                          // Rendering part
                          return HomeworkComp(homework: homework);
                        });
                  } else {
                    return Center(child: CircularProgressIndicator.adaptive());
                  }
                },
              ),
              floatingActionButton: user.type == UserType.teacher
                  ? IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NewHomework())))
                  : null,
            );
          } else {
            return Center(child: CircularProgressIndicator.adaptive());
          }
        });
  }
}
