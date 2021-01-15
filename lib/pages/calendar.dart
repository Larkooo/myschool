import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';
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
  static Map<DateTime, dynamic> _events = {};
  Map<DateTime, dynamic> _dayEvents = {};
  bool _dayIsHome = false;
  static List _remoteSchoolDays = [];
  bool yes = false;

  static DateTime _startDay;
  static DateTime _endDay;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _calendarController = CalendarController();
  }

  dynamic getNextCourse(DateTime last, String courseId) {
    for (final element in _events.entries) {
      if (element.key > last && element.value['codeActivite'] == courseId) {
        return element;
      }
    }
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
              if (_remoteSchoolDays.isNotEmpty)
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 30,
                  color: _dayIsHome ? Colors.blue : Colors.green,
                  child: Center(
                      child: Text(_dayIsHome ? "À la maison" : "À l'école")),
                ),
              TableCalendar(
                initialSelectedDay: _selectedDay,
                startDay: _startDay,
                endDay: _endDay,
                onCalendarCreated: (first, last, format) async {
                  yes = true;
                  if (_events.isEmpty) {
                    final schoolTimetableURL = await StorageService(
                            ref:
                                "/schools/${userData.school.uid}/groups/${userData.school.group.uid}/timetable.json")
                        .getDownloadURL();

                    if (schoolTimetableURL != null) {
                      final schoolTimetableFile = await DefaultCacheManager()
                          .getSingleFile(schoolTimetableURL);
                      _events = Map.fromIterable(
                          jsonDecode(await schoolTimetableFile.readAsString()),
                          key: (e) => DateTime.parse(
                              e['dateDebut'] + 'T' + e['heureDebut']),
                          value: (e) => {
                                "description": e['description'],
                                "locaux": e['locaux'],
                                "intervenants": e['intervenants'],
                                "heureFin": e['heureFin'],
                                "codeActivite": e['codeActivite']
                              });
                      setState(() {
                        _startDay = _events.entries.first.key;
                        _endDay = _events.entries.last.key;
                      });
                    }
                    _events.forEach((day, desc) {
                      if (day.isSameDay(_selectedDay)) {
                        setState(() {
                          _dayEvents[day] = desc;
                        });
                      }
                    });
                  }

                  if (_remoteSchoolDays.isEmpty) {
                    final remoteSchoolURL = await StorageService(
                            ref:
                                "/schools/${userData.school.uid}/remoteschool.json")
                        .getDownloadURL();

                    if (remoteSchoolURL != null) {
                      final remoteSchoolFile = await DefaultCacheManager()
                          .getSingleFile(remoteSchoolURL);
                      _remoteSchoolDays =
                          jsonDecode(await remoteSchoolFile.readAsString());
                    }
                  }
                  Future.delayed(Duration(milliseconds: 1), () {
                    _events.forEach((day, data) {
                      if (day.isSameDay(_selectedDay)) {
                        setState(() {
                          _dayEvents[day] = data;
                        });
                      }
                    });
                    _remoteSchoolDays.forEach((element) {
                      DateTime remoteDay = DateTime.parse(element['date']);

                      if (_selectedDay.isSameDay(remoteDay)) {
                        setState(() {
                          if ((element['home'] as List)
                              .contains(int.parse(userData.school.group.uid))) {
                            _dayIsHome = true;
                          } else if ((element['home'] as List).contains(
                              int.parse(userData.school.group.uid[0]))) {
                            _dayIsHome = true;
                          } else {
                            _dayIsHome = false;
                          }
                        });
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
                  if (_remoteSchoolDays.isNotEmpty)
                    _remoteSchoolDays.forEach((element) {
                      DateTime remoteDay = DateTime.parse(element['date']);

                      if (_selectedDay.isSameDay(remoteDay)) {
                        setState(() {
                          if ((element['home'] as List)
                              .contains(int.parse(userData.school.group.uid))) {
                            _dayIsHome = true;
                          } else if ((element['home'] as List).contains(
                              int.parse(userData.school.group.uid[0]))) {
                            _dayIsHome = true;
                          } else {
                            _dayIsHome = false;
                          }
                        });
                      }
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
                                  onTap: () => showSlideDialog(
                                      context: context,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(height: 5),
                                          Text(
                                            e.value['description'],
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            DateFormat.Hm().format(e.key),
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[500]),
                                          ),
                                          SizedBox(
                                            height: 25,
                                          ),
                                          Text(
                                            "Groupe",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            userData.school.group.uid,
                                            style: TextStyle(
                                                color: Colors.grey[500]),
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Column(children: [
                                                Text(
                                                  "Heure de début",
                                                  style:
                                                      TextStyle(fontSize: 15),
                                                ),
                                                Text(
                                                  DateFormat.Hm().format(e.key),
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[500]),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  "Intervenant",
                                                  style:
                                                      TextStyle(fontSize: 15),
                                                ),
                                                Text(
                                                  e.value['intervenants'][0]
                                                          ['nom'] +
                                                      " " +
                                                      e.value['intervenants'][0]
                                                          ['prenom'],
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[500]),
                                                )
                                              ]),
                                              Column(children: [
                                                Text(
                                                  "Heure de fin",
                                                  style:
                                                      TextStyle(fontSize: 15),
                                                ),
                                                Text(
                                                  e.value['heureFin'],
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[500]),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  "Local",
                                                  style:
                                                      TextStyle(fontSize: 15),
                                                ),
                                                Text(
                                                  e.value['locaux'][0],
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[500]),
                                                )
                                              ]),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 30,
                                          ),
                                          Text(
                                            "Prochain cours",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  1.3,
                                              child: Card(
                                                child: ListTile(
                                                    title: Text(e.value['description'] +
                                                        " (${e.value['locaux'][0]})"),
                                                    subtitle: Text(e.value['intervenants']
                                                            [0]['nom'] +
                                                        " " +
                                                        e.value['intervenants']
                                                            [0]['prenom'] +
                                                        " - " +
                                                        DateFormat.MEd().format(
                                                            getNextCourse(e.key,
                                                                    e.value['codeActivite'])
                                                                .key))),
                                              )),
                                        ],
                                      )),
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
