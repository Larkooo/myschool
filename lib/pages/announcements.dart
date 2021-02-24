import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:myschool/components/announce.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/components/register.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/settings.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../services/database.dart';
import '../models/school.dart';

class Announcements extends StatefulWidget {
  //final UserData user;
  //Announcements({this.user});

  @override
  _AnnouncementsState createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  // Default value -> student
  UserType userType = UserType.student;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Scaffold(
      body: StreamBuilder(
          stream: DatabaseService(uid: user.uid).user,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              UserData user = snapshot.data;

              // Calling setstate after build is finisehd
              SchedulerBinding.instance
                  .addPostFrameCallback((_) => setState(() {
                        userType = user.userType;
                      }));

              return StreamBuilder(
                /* 
                  Using StreamZip to merge 2 streams, the group announcements and school ones
                  */
                stream: //CombineLatestStream.list([
                    DatabaseService(uid: user.school.uid).school,
                //DatabaseService(uid: user.school.uid)
                //    .group(user.school.group.uid)
                //]),
                builder: (context, schoolSnapshot) {
                  if (schoolSnapshot.hasData) {
                    List<Announcement> announcements =
                        schoolSnapshot.data.announcements;
                    return StreamBuilder(
                      stream: DatabaseService(uid: user.school.uid)
                          .group(user.school.group.uid),
                      builder: (context, groupSnapshot) {
                        if (groupSnapshot.hasData) {
                          List<Announcement> groupAnnouncements =
                              groupSnapshot.data.announcements;
                          announcements.addAll(groupAnnouncements);
                          return ListView.builder(
                              itemCount: announcements.length,
                              itemBuilder: (context, index) {
                                /* 
                          Sorting the announcements by comparing their time of creation 
                  */
                                announcements.sort((a, b) =>
                                    b.createdAt.compareTo(a.createdAt));

                                /* 
                          Transforming our data to a an Announcement 
                        */
                                Announcement announcement =
                                    announcements[index];
                                    // print(announcement.title);
                                // Rendering part
                                return Announce(announcement: announcement);
                              });
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    );
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
          }),
      floatingActionButton: userType == UserType.teacher
          ? IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => NewAnnounce())))
          : null,
    );
  }
}
