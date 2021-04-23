import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:myschool/components/announce.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/pages/login.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';
import 'package:dart_date/dart_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';
import 'package:myschool/shared/cachemanager.dart';

class Home extends StatefulWidget {
  final UserData user;
  Home({this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DateTime _now = DateTime.now();

  SharedPreferences _prefs;

  Future initializeSharedPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //initializeSharedPrefs();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    CacheManagerMemory.dayCourses.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(children: [
      /* Container(
                width: MediaQuery.of(context).size.width,
                height: 30,
                child: Center(
                    child: CacheManagerMemory.dayIsHome == null
                        ? FutureBuilder(
                            future: StorageService(
                                    ref:
                                        "/schools/${userData.school.uid}/remoteschool.json")
                                .getDownloadURL(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return FutureBuilder(
                                    future: DefaultCacheManager()
                                        .getSingleFile(snapshot.data),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        File remoteSchoolFile = snapshot.data;
                                        List remoteSchoolDays = jsonDecode(
                                            remoteSchoolFile
                                                .readAsStringSync());
                                        remoteSchoolDays.forEach((element) {
                                          DateTime remoteDay =
                                              DateTime.parse(element['date']);

                                          if (_now.isSameDay(remoteDay)) {
                                            CacheManagerMemory.dayIsHome =
                                                (element['home'] as List)
                                                        .contains(int.parse(
                                                            userData.school
                                                                .group.uid)) ||
                                                    (element['home'] as List)
                                                        .contains(int.parse(
                                                            userData.school
                                                                .group.uid[0]));
                                          }
                                        });
                                        return Text(dayIsHome());
                                      } else {
                                        return CircularProgressIndicator
                                            .adaptive();
                                      }
                                    });
                              } else {
                                return CircularProgressIndicator.adaptive();
                              }
                            })
                        : Text(dayIsHome())),
                color: Colors.blue,
              ), */
      SizedBox(
        height: 10,
      ),
      FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              SharedPreferences prefs = snapshot.data;
              if (prefs.getString('mozaikTimetable') == null)
                return Container();

              List decodedTimetable =
                  jsonDecode(prefs.getString('mozaikTimetable'));

              CacheManagerMemory.courses = Map.fromIterable(decodedTimetable,
                  key: (e) =>
                      DateTime.parse(e['dateDebut'] + 'T' + e['heureDebut']),
                  value: (e) => {
                        "description": e['description'],
                        "locaux": e['locaux'],
                        "intervenants": e['intervenants'],
                        "heureFin": e['heureFin'],
                        "codeActivite": e['codeActivite']
                      });

              CacheManagerMemory.courses.forEach((day, data) {
                if (day.isSameDay(_now)) {
                  CacheManagerMemory.dayCourses[day] = data;
                }
              });

              for (final e in decodedTimetable) {
                DateTime courseStart =
                    DateTime.parse(e['dateDebut'] + "T" + e['heureDebut']);
                if (courseStart > _now) {
                  CacheManagerMemory.nextCourse = e;
                  break;
                }
              }

              return Column(
                children: [
                  Text(
                    "Prochain cours",
                    style: TextStyle(fontSize: 18),
                  ),
                  Container(
                      width: MediaQuery.of(context).size.width / 1.2,
                      child: Card(
                        child: ListTile(
                            onTap: () => showSlideDialog(
                                context: context,
                                child: coursePage(
                                    context,
                                    widget.user,
                                    CacheManagerMemory
                                        .nextCourse['codeActivite'],
                                    CacheManagerMemory
                                        .nextCourse['description'],
                                    DateTime.parse(CacheManagerMemory
                                            .nextCourse['dateDebut'] +
                                        "T" +
                                        CacheManagerMemory
                                            .nextCourse['heureDebut']),
                                    CacheManagerMemory
                                        .nextCourse['intervenants'],
                                    CacheManagerMemory.nextCourse['heureFin'],
                                    CacheManagerMemory.nextCourse['locaux'])),
                            title: Text(CacheManagerMemory.nextCourse['description'] +
                                " (${CacheManagerMemory.nextCourse['locaux'][0]})"),
                            subtitle: Text(CacheManagerMemory
                                    .nextCourse['intervenants'][0]['nom'] +
                                " " +
                                CacheManagerMemory.nextCourse['intervenants'][0]
                                    ['prenom'] +
                                " - " +
                                timeCountdownFormat(
                                    (DateTime.parse(CacheManagerMemory.nextCourse['dateDebut'] + "T" + CacheManagerMemory.nextCourse['heureDebut'])), _now))),
                      )),
                ],
              );
            } else {
              return Container();
            }
          }),
      StreamBuilder(
          stream: DatabaseService(uid: widget.user.school.uid)
              .schoolAnnouncements(limit: 1),
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
                      style: TextStyle(fontSize: 18),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width / 1.2,
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
