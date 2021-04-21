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
import '../shared/platform_utility.dart';

class Announcements extends StatefulWidget {
  final UserData user;
  Announcements({this.user});

  @override
  _AnnouncementsState createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  Scope _scope = Scope.none;
  ScrollController _scrollController = ScrollController();

  int _announcementCount = 0;
  int _streamCount = 0;

  int _dynamicLimit = 5;

  Widget _dynamicBottom;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(
        Duration.zero,
        () => _dynamicBottom = loadButton(context, () {
              setState(() {
                _dynamicLimit += 10;
              });
            }));

    _scrollController.addListener(() {
      final totalLimit = _dynamicLimit * _streamCount;
      // if we have more messages to load and we're scrolled up at top
      if (_scrollController.offset == 0.0 &&
          !(_announcementCount < totalLimit)) {
        setState(() {
          _dynamicBottom = Center(child: CircularProgressIndicator.adaptive());
          _dynamicLimit += 10;
        });
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            _dynamicBottom = loadButton(context, () {
              setState(() {
                _dynamicLimit += 10;
              });
            });
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // grouping different streams into a list to then merge them.
    // to get school and group(s) announcements
    List<Stream> streams = [];
    if (_scope == Scope.school || _scope == Scope.none)
      streams.add(DatabaseService(uid: widget.user.school.uid)
          .schoolAnnouncements(limit: _dynamicLimit));
    if (widget.user.type == UserType.student) {
      if (_scope == Scope.group || _scope == Scope.none)
        streams.add(DatabaseService(uid: widget.user.school.uid)
            .groupAnnouncements(widget.user.school.group.uid,
                limit: _dynamicLimit));
    } else if (_scope == Scope.group || _scope == Scope.none) {
      widget.user.groups.forEach((group) {
        streams.add(DatabaseService(uid: widget.user.school.uid)
            .groupAnnouncements(group, limit: _dynamicLimit));
      });
    }
    return Scaffold(
      // only for ios for now
      appBar: PlatformUtils.isIOS
          ? AppBar(
              title: Container(
                  width: MediaQuery.of(context).size.width / 1.2,
                  child: CupertinoSlidingSegmentedControl(
                      groupValue: _scope,
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
                          _scope = v;
                        });
                      })),
            )
          : null,
      body: StreamBuilder(
        /* 
                  Merging the streams, the group announcements and school ones
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

            // keep track of the count of announcements to know when we need
            // to load more of them
            _announcementCount = announcements.length;
            _streamCount = snapshot.data.length;

            // we need to sort the data ourselves because we have multiple separate
            // streams
            announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return ListView.builder(
                controller: _scrollController,
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  // we have multiple streams

                  if (index == announcements.length - 1 &&
                      !(announcements.length <
                          (_dynamicLimit * snapshot.data.length))) {
                    return Column(
                      children: [
                        Announce(announcement: announcements[index]),
                        _dynamicBottom
                      ],
                    );
                  }
                  /* 
                          Transforming our data to a an Announcement 
                        */
                  Announcement announcement = announcements[index];

                  // Rendering part
                  return Announce(announcement: announcement);
                });
          } else {
            print(snapshot.error);
            return Center(child: CircularProgressIndicator.adaptive());
          }
        },
      ),
      floatingActionButton: widget.user.type == UserType.teacher ||
              widget.user.type == UserType.direction
          ? FloatingActionButton(
              tooltip: 'Publier une annonce',
              backgroundColor: Colors.blue[400],
              child: Icon(Icons.add),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NewAnnounce(user: widget.user))))
          : null,
    );
  }
}
