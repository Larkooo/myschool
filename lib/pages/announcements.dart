import 'dart:io';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:myschool/components/announce.dart';
import 'package:myschool/components/new_announce.dart';
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

class Announcements extends StatefulWidget {
  final UserData user;
  Announcements({this.user});

  @override
  _AnnouncementsState createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  Scope scope = Scope.none;

  @override
  Widget build(BuildContext context) {
    // grouping different streams into a list to then merge them.
    // to get school and group(s) announcements
    List<Stream> streams = [];
    if (scope == Scope.school || scope == Scope.none)
      streams.add(
          DatabaseService(uid: widget.user.school.uid).schoolAnnouncements);
    if (widget.user.type == UserType.student) {
      if (scope == Scope.group || scope == Scope.none)
        streams.add(DatabaseService(uid: widget.user.school.uid)
            .groupAnnouncements(widget.user.school.group.uid));
    } else if (scope == Scope.group || scope == Scope.none) {
      widget.user.groups.forEach((group) {
        streams.add(DatabaseService(uid: widget.user.school.uid)
            .groupAnnouncements(group.toString()));
      });
    }
    return Scaffold(
      // only for ios for now
      appBar: Platform.isIOS
          ? AppBar(
              title: Container(
                  width: MediaQuery.of(context).size.width / 1.2,
                  child: CupertinoSlidingSegmentedControl(
                      groupValue: scope,
                      children: {
                        Scope.school:
                            Text('École', style: TextStyle(fontSize: 12)),
                        Scope.none:
                            Text('Tous', style: TextStyle(fontSize: 12)),
                        Scope.group:
                            Text('Groupe', style: TextStyle(fontSize: 12))
                      },
                      onValueChanged: (v) {
                        setState(() {
                          scope = v;
                        });
                      })),
            )
          : null,
      body: StreamBuilder(
        /* 
                  Merging the streams, the group(s) announcements and school ones
                  */
        stream: CombineLatestStream.list(streams),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            //print(snapshot.data.length);
            List<Announcement> announcements = [];
            snapshot.data.forEach((streamData) {
              announcements.addAll((streamData as QuerySnapshot)
                  .docs
                  .map(DatabaseService.announcementFromSnapshot)
                  .toList());
            });

            return ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  /* 
                          Transforming our data to a an Announcement 
                        */
                  Announcement announcement = announcements[index];

                  // Rendering part
                  return Announce(announcement: announcement);
                });
          } else {
            return Center(child: CircularProgressIndicator.adaptive());
          }
        },
      ),
      floatingActionButton: widget.user.type == UserType.teacher
          ? FloatingActionButton(
              tooltip: 'Publier une annonce',
              backgroundColor: Colors.grey[700].withOpacity(0.4),
              child: Icon(Icons.add),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NewAnnounce(user: widget.user))))
          : null,
    );
  }
}
