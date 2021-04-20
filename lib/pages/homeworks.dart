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
  final UserData user;
  Homeworks({this.user});

  @override
  _HomeworksState createState() => _HomeworksState();
}

class _HomeworksState extends State<Homeworks> {
  ScrollController _scrollController = ScrollController();

  int _dynamicLimit = 5;

  int _homeworkCount = 0;
  int _streamCount = 0;

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
      if (_scrollController.offset == 0.0 && !(_homeworkCount < totalLimit)) {
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
    // to get school and group(s) homeworks
    List<Stream> streams = [];
    if (widget.user.type == UserType.student) {
      streams.add(DatabaseService(uid: widget.user.school.uid)
          .groupHomeworks(widget.user.school.group.uid));
    } else {
      widget.user.groups.forEach((group) {
        streams.add(DatabaseService(uid: widget.user.school.uid)
            .groupHomeworks(group.toString()));
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
            snapshot.data.forEach((streamData) {
              homeworks.addAll((streamData as QuerySnapshot)
                  .docs
                  .map(DatabaseService.homeworkFromSnapshot)
                  .toList());
            });

            // keep track of the count of homeworks to know when we need
            // to load more of them
            _homeworkCount = homeworks.length;
            _streamCount = snapshot.data.length;

            // filtering homeworks
            homeworks.removeWhere(
                (homework) => homework.due.difference(DateTime.now()).inDays >
                            // hide homework after 14 days
                            14 ||
                        // if teacher, dont show other teachers given homeworks
                        widget.user.type == UserType.teacher
                    ? homework.author != widget.user.uid
                    : false);

            return ListView.builder(
                controller: _scrollController,
                itemCount: homeworks.length,
                itemBuilder: (context, index) {
                  if (index == homeworks.length - 1 &&
                      !(homeworks.length <
                          (_dynamicLimit * snapshot.data.length))) {
                    return Column(
                      children: [
                        HomeworkComp(homework: homeworks[index]),
                        _dynamicBottom
                      ],
                    );
                  }
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
      floatingActionButton: widget.user.type == UserType.teacher ||
              widget.user.type == UserType.direction
          ? FloatingActionButton(
              backgroundColor: Colors.blue[400],
              tooltip: 'Poster un devoir',
              child: Icon(Icons.add),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NewHomework(user: widget.user))))
          : null,
    );
  }
}
