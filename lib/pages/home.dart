import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
  DateTime today = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: user.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData userData = snapshot.data;
            return FutureBuilder(
              future: StorageService(
                      ref: "/schools/${userData.school.uid}/remoteschool.json")
                  .getDownloadURL(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FutureBuilder(
                    future: DefaultCacheManager().getSingleFile(snapshot.data),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        (jsonDecode((snapshot.data as File).readAsStringSync()))
                            .forEach((element) {
                          DateTime remoteDay = DateTime.parse(element['date']);
                          if (today.isSameDay(remoteDay)) {
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
