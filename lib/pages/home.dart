import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:myschool/components/announce.dart';
import 'package:myschool/components/login.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';
import 'package:dart_date/dart_date.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';
import 'calendar.dart';

class Home extends StatefulWidget {
  //final UserData user;
  //Home({this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static File _schoolTimetable;
  static bool _dayIsHome;
  static Map<DateTime, dynamic> _dayEvents;
  DateTime _now = DateTime.now();
  static Map<String, dynamic> _nextCourse;
  static Map<DateTime, dynamic> _events;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: user.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData userData = snapshot.data;
            return Center(
                child: Column(children: [
              _dayIsHome == null
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
                                      remoteSchoolFile.readAsStringSync());
                                  remoteSchoolDays.forEach((element) {
                                    DateTime remoteDay =
                                        DateTime.parse(element['date']);

                                    if (_now.isSameDay(remoteDay)) {
                                      if ((element['home'] as List).contains(
                                          int.parse(
                                              userData.school.group.uid))) {
                                        _dayIsHome = true;
                                      } else if ((element['home'] as List)
                                          .contains(int.parse(
                                              userData.school.group.uid[0]))) {
                                        _dayIsHome = true;
                                      } else {
                                        _dayIsHome = false;
                                      }
                                    }
                                  });
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 30,
                                    color:
                                        _dayIsHome ? Colors.blue : Colors.green,
                                    child: Center(
                                        child: Text(_dayIsHome
                                            ? "À la maison"
                                            : "À l'école")),
                                  );
                                } else {
                                  return CircularProgressIndicator();
                                }
                              });
                        } else {
                          return CircularProgressIndicator();
                        }
                      })
                  : Container(
                      width: MediaQuery.of(context).size.width,
                      height: 30,
                      color: _dayIsHome ? Colors.blue : Colors.green,
                      child: Center(
                          child:
                              Text(_dayIsHome ? "À la maison" : "À l'école")),
                    ),
              SizedBox(
                height: 10,
              ),
              _schoolTimetable == null ||
                      (DateTime.parse(_nextCourse['dateDebut'] +
                              "T" +
                              _nextCourse['heureDebut'])) <=
                          _now
                  ? FutureBuilder(
                      future: StorageService(
                              ref:
                                  "/schools/${userData.school.uid}/groups/${userData.school.group.uid}/timetable.json")
                          .getDownloadURL(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return FutureBuilder(
                            future: DefaultCacheManager()
                                .getSingleFile(snapshot.data),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                _schoolTimetable = snapshot.data;

                                _events = Map.fromIterable(
                                    jsonDecode(
                                        _schoolTimetable.readAsStringSync()),
                                    key: (e) => DateTime.parse(
                                        e['dateDebut'] + 'T' + e['heureDebut']),
                                    value: (e) => {
                                          "description": e['description'],
                                          "locaux": e['locaux'],
                                          "intervenants": e['intervenants'],
                                          "heureFin": e['heureFin'],
                                          "codeActivite": e['codeActivite']
                                        });

                                _events.forEach((day, data) {
                                  if (day.isSameDay(_now)) {
                                    setState(() {
                                      _dayEvents[day] = data;
                                    });
                                  }
                                });

                                for (final e in (jsonDecode(
                                    _schoolTimetable.readAsStringSync()))) {
                                  DateTime courseStart = DateTime.parse(
                                      e['dateDebut'] + "T" + e['heureDebut']);
                                  if (courseStart > _now) {
                                    _nextCourse = e;
                                    break;
                                  }
                                }

                                return Column(
                                  children: [
                                    Text(
                                      "Prochain cours",
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[400]),
                                    ),
                                    Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                1.3,
                                        child: Card(
                                          child: ListTile(
                                              title: Text(_nextCourse['description'] +
                                                  " (${_nextCourse['locaux'][0]})"),
                                              subtitle: Text(_nextCourse['intervenants']
                                                      [0]['nom'] +
                                                  " " +
                                                  _nextCourse['intervenants'][0]
                                                      ['prenom'] +
                                                  " - " +
                                                  timeCountdownFormat(
                                                      (DateTime.parse(
                                                          _nextCourse['dateDebut'] +
                                                              "T" +
                                                              _nextCourse[
                                                                  'heureDebut'])),
                                                      _now))),
                                        )),
                                  ],
                                );
                              } else {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                            },
                          );
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    )
                  : Column(
                      children: [
                        Text(
                          "Prochain cours",
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[400]),
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width / 1.3,
                            child: Card(
                              child: ListTile(
                                  title: Text(_nextCourse['description'] +
                                      " (${_nextCourse['locaux'][0]})"),
                                  subtitle: Text(_nextCourse['intervenants'][0]
                                          ['nom'] +
                                      " " +
                                      _nextCourse['intervenants'][0]['prenom'] +
                                      " - " +
                                      timeCountdownFormat(
                                          (DateTime.parse(
                                              _nextCourse['dateDebut'] +
                                                  "T" +
                                                  _nextCourse['heureDebut'])),
                                          _now))),
                            )),
                      ],
                    ),
              SizedBox(
                height: 20,
              ),
              Text(
                "Dernière annonce école",
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
              StreamBuilder(
                  stream: DatabaseService(uid: userData.school.uid).school,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      School school = snapshot.data;
                      return Container(
                          width: MediaQuery.of(context).size.width / 1.3,
                          child: Announce(
                              announcement: school.announcements.last));
                    } else {
                      return CircularProgressIndicator();
                    }
                  }),
            ]));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
