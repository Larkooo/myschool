import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:dart_date/dart_date.dart';

class Calendar extends StatefulWidget {
  //final UserData user;
  //Calendar({this.user});

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  CalendarController _calendarController;
  DateTime _selectedDay = DateTime.now().hour > 17
      ? DateTime.now().setHour(15).addDays(1)
      : DateTime.now();
  Map<DateTime, dynamic> _events;
  Map<DateTime, dynamic> _dayEvents = Map<DateTime, dynamic>();
  bool dayIsHome = false;
  List remoteSchoolDays;

  DateTime startDay;
  DateTime endDay;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _calendarController = CalendarController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: user.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData userData = snapshot.data;
            return Column(children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 30,
                color: dayIsHome ? Colors.blue : Colors.green,
                child: Center(
                    child: Text(dayIsHome ? "À la maison" : "À l'école")),
              ),
              TableCalendar(
                initialSelectedDay: _selectedDay,
                startDay: startDay,
                endDay: endDay,
                onCalendarCreated: (first, last, format) async {
                  final schoolTimetableURL = await StorageService(
                          ref:
                              "/schools/${userData.school.uid}/groups/${userData.school.group.uid}/timetable.json")
                      .getDownloadURL();

                  final remoteSchoolURL = await StorageService(
                          ref:
                              "/schools/${userData.school.uid}/remoteschool.json")
                      .getDownloadURL();

                  final schoolTimetableFile = await DefaultCacheManager()
                      .getSingleFile(schoolTimetableURL);

                  final remoteSchoolFile = await DefaultCacheManager()
                      .getSingleFile(remoteSchoolURL);

                  remoteSchoolDays = List.from(
                      jsonDecode(await remoteSchoolFile.readAsString()));

                  _events = Map.fromIterable(
                      jsonDecode(await schoolTimetableFile.readAsString()),
                      key: (e) => DateTime.parse(
                          e['dateDebut'] + 'T' + e['heureDebut']),
                      value: (e) => {
                            "description": e['description'],
                            "locaux": e['locaux'],
                            "intervenants": e['intervenants']
                          });
                  setState(() {
                    startDay = _events.entries.first.key;
                    endDay = _events.entries.last.key;
                  });
                  _events.forEach((day, desc) {
                    if (day.isSameDay(_selectedDay)) {
                      setState(() {
                        _dayEvents[day] = desc;
                      });
                    }
                  });
                  remoteSchoolDays.forEach((element) {
                    DateTime remoteDay = DateTime.parse(element['date']);
                    setState(() {
                      if (_selectedDay.isSameDay(remoteDay)) {
                        if (userData.school.group.uid.startsWith("5")) {
                          dayIsHome = element["5"] == 1 ? true : false;
                        } else if (userData.school.group.uid.startsWith("4")) {
                          dayIsHome = element["4"] == 1 ? true : false;
                        } else if (userData.school.group.uid == "301" ||
                            userData.school.group.uid == "302") {
                          dayIsHome = element["301302"] == 1 ? true : false;
                        } else {
                          dayIsHome = element["303304"] == 1 ? true : false;
                        }
                      }
                    });
                  });
                },
                onDaySelected: (day, events, holidays) {
                  setState(() {
                    _selectedDay = day;
                    _dayEvents.clear();
                  });
                  _events.forEach((day, desc) {
                    if (day.isSameDay(_selectedDay)) {
                      setState(() {
                        _dayEvents[day] = desc;
                      });
                    }
                  });
                  remoteSchoolDays.forEach((element) {
                    DateTime remoteDay = DateTime.parse(element['date']);
                    setState(() {
                      if (day.isSameDay(remoteDay)) {
                        if (userData.school.group.uid.startsWith("5")) {
                          dayIsHome = element["5"] == 1 ? true : false;
                        } else if (userData.school.group.uid.startsWith("4")) {
                          dayIsHome = element["4"] == 1 ? true : false;
                        } else if (userData.school.group.uid == "301" ||
                            userData.school.group.uid == "302") {
                          dayIsHome = element["301302"] == 1 ? true : false;
                        } else {
                          dayIsHome = element["303304"] == 1 ? true : false;
                        }
                      }
                    });
                  });
                },
                calendarController: _calendarController,
                availableCalendarFormats: {
                  CalendarFormat.month: 'Semaine',
                  CalendarFormat.twoWeeks: 'Mois',
                  CalendarFormat.week: '2 semaines'
                },
              ),
              Expanded(
                  child: ListView(
                      children: _dayEvents.entries
                          .map((e) => Card(
                                child: ListTile(
                                  title: Text(e.value['description'] +
                                      " (${e.value['locaux'][0]})"),
                                  subtitle: Text(e.value['intervenants'][0]
                                          ['nom'] +
                                      " " +
                                      e.value['intervenants'][0]['prenom'] +
                                      " - " +
                                      DateFormat.Hm().format(e.key)),
                                ),
                              ))
                          .toList()))
            ]);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
