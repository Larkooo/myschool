import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:myschool/components/login.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:dart_date/dart_date.dart';

class Home extends StatefulWidget {
  //final UserData user;
  //Home({this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List remoteSchoolDays;
  bool dayIsHome = false;
  DateTime now = DateTime.now();
  Map<String, dynamic> nextCourse;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: user.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData userData = snapshot.data;
            return FutureBuilder(
              future: Future.wait([
                StorageService(
                        ref:
                            "/schools/${userData.school.uid}/remoteschool.json")
                    .getDownloadURL(),
                StorageService(
                        ref:
                            "/schools/${userData.school.uid}/groups/${userData.school.group.uid}/timetable.json")
                    .getDownloadURL()
              ]),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FutureBuilder(
                    future: Future.wait([
                      DefaultCacheManager().getSingleFile(snapshot.data[0]),
                      DefaultCacheManager().getSingleFile(snapshot.data[1])
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        File remoteSchoolDays = snapshot.data[0];
                        File schoolTimetable = snapshot.data[1];
                        (jsonDecode(remoteSchoolDays.readAsStringSync()))
                            .forEach((element) {
                          DateTime remoteDay = DateTime.parse(element['date']);
                          if (now.isSameDay(remoteDay)) {
                            if (userData.school.group.uid.startsWith("5")) {
                              dayIsHome = element["5"] == 1 ? true : false;
                            } else if (userData.school.group.uid
                                .startsWith("4")) {
                              dayIsHome = element["4"] == 1 ? true : false;
                            } else if (userData.school.group.uid == "301" ||
                                userData.school.group.uid == "302") {
                              dayIsHome = element["301302"] == 1 ? true : false;
                            } else {
                              dayIsHome = element["303304"] == 1 ? true : false;
                            }
                          }
                        });
                        for (final e in (jsonDecode(
                            schoolTimetable.readAsStringSync()))) {
                          DateTime courseStart = DateTime.parse(
                              e['dateDebut'] + "T" + e['heureDebut']);
                          if (courseStart > now) {
                            nextCourse = e;
                            break;
                          }
                        }

                        return Column(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 30,
                              color: dayIsHome ? Colors.blue : Colors.green,
                              child: Center(
                                  child: Text(
                                      dayIsHome ? "À la maison" : "À l'école")),
                            ),
                            SizedBox(
                              height: 50,
                            ),
                            Text(
                              "Prochain cours",
                              style: TextStyle(fontSize: 18),
                            ),
                            Container(
                                width: MediaQuery.of(context).size.width / 1.3,
                                child: Card(
                                  child: ListTile(
                                      title: Text(nextCourse['description'] +
                                          " (${nextCourse['locaux'][0]})"),
                                      subtitle: Text(nextCourse['intervenants']
                                              [0]['nom'] +
                                          " " +
                                          nextCourse['intervenants'][0]
                                              ['prenom'] +
                                          " - Dans " +
                                          (DateTime.parse(nextCourse[
                                                          'dateDebut'] +
                                                      "T" +
                                                      nextCourse['heureDebut'])
                                                  .differenceInHours(now))
                                              .toString() +
                                          " heures")),
                                )),
                          ],
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
