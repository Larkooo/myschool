import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:dart_date/dart_date.dart';
import 'package:myschool/shared/cachemanager.dart';

class Calendar extends StatefulWidget {
  //final UserData user;
  //Calendar({this.user});

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  CalendarController _calendarController;
  bool _todayAtHome;
  DateTime _selectedDay = DateTime.now().hour > 17
      ? DateTime.now().setHour(15).addDays(1)
      : DateTime.now();

  static DateTime _startDay;
  static DateTime _endDay;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    // Since home page uses the same variable as calendar to know if we're at home, we need to
    // reset it to today for home page to get the correct info
    CacheManagerMemory.dayIsHome = _todayAtHome;
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
              /* 
                  
                  */
              if (CacheManagerMemory.remoteSchoolDays.isNotEmpty)
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 30,
                  color:
                      CacheManagerMemory.dayIsHome ? Colors.blue : Colors.green,
                  child: Center(
                      child: Text(dayIsHomeString)),
                ),
              TableCalendar(
                initialSelectedDay: _selectedDay,
                startDay: _startDay,
                endDay: _endDay,
                onCalendarCreated: (first, last, format) async {
                  /* 
                    If CacheManagerMemory.courses has a length of 0 => get the download URL of our timetable
                    download it,
                    cache it,
                    and decode it as JSON to assign it to our static variable

                  */
                  if (CacheManagerMemory.courses.isEmpty) {
                    final schoolTimetableURL = await StorageService(
                            ref:
                                "/schools/${userData.school.uid}/groups/${userData.school.group.uid}/timetable.json")
                        .getDownloadURL();

                    if (schoolTimetableURL != null) {
                      final schoolTimetableFile = await DefaultCacheManager()
                          .getSingleFile(schoolTimetableURL);
                      CacheManagerMemory.courses = Map.fromIterable(
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
                      // Setting the startday and the endday of the calendar (so the startday/endday of school in this case)
                      setState(() {
                        _startDay =
                            CacheManagerMemory.courses.entries.first.key;
                        _endDay = CacheManagerMemory.courses.entries.last.key;
                      });
                    }
                  }

                  /* 
                    Basically, its the same thing than the timetable, repeating every steps
                  */
                  if (CacheManagerMemory.remoteSchoolDays.isEmpty) {
                    final remoteSchoolURL = await StorageService(
                            ref:
                                "/schools/${userData.school.uid}/remoteschool.json")
                        .getDownloadURL();

                    if (remoteSchoolURL != null) {
                      final remoteSchoolFile = await DefaultCacheManager()
                          .getSingleFile(remoteSchoolURL);
                      CacheManagerMemory.remoteSchoolDays =
                          jsonDecode(await remoteSchoolFile.readAsString());
                    }
                  }

                  // Using future.delayed to resolve the setState error happening on build
                  Future.delayed(Duration.zero, () {
                    /* 
                    Checking the date of each of our events to then assign them to CacheManagerMemory.dayCourses
                    CacheManagerMemory.courses has to be not empty.
                  */
                    if (CacheManagerMemory.courses.isNotEmpty)
                      CacheManagerMemory.courses.forEach((day, data) {
                        if (day.isSameDay(_selectedDay)) {
                          setState(() {
                            CacheManagerMemory.dayCourses[day] = data;
                          });
                        }
                      });
                    /* 
                      Same thing. We're just checking if we're home or at school here.
                  */
                    if (CacheManagerMemory.remoteSchoolDays.isNotEmpty)
                      CacheManagerMemory.remoteSchoolDays.forEach((element) {
                        DateTime remoteDay = DateTime.parse(element['date']);

                        if (_selectedDay.isSameDay(remoteDay)) {
                          setState(() {
                            bool atHome = (element['home'] as List).contains(
                                    int.parse(userData.school.group.uid)) ||
                                (element['home'] as List).contains(
                                    int.parse(userData.school.group.uid[0]));
                            CacheManagerMemory.dayIsHome = atHome;
                            _todayAtHome = atHome;
                          });
                        }
                      });
                  });
                },
                /* 
                  If a day is selected, redo all the calculations that have been done at the creation of the page ^
                  */
                onDaySelected: (day, events, holidays) {
                  setState(() {
                    _selectedDay = day;
                    CacheManagerMemory.dayCourses.clear();
                  });
                  CacheManagerMemory.courses.forEach((day, desc) {
                    if (day.isSameDay(_selectedDay)) {
                      setState(() {
                        CacheManagerMemory.dayCourses[day] = desc;
                      });
                    }
                  });
                  if (CacheManagerMemory.remoteSchoolDays.isNotEmpty)
                    CacheManagerMemory.remoteSchoolDays.forEach((element) {
                      DateTime remoteDay = DateTime.parse(element['date']);

                      if (_selectedDay.isSameDay(remoteDay)) {
                        setState(() {
                          bool atHome = (element['home'] as List).contains(
                                  int.parse(userData.school.group.uid)) ||
                              (element['home'] as List).contains(
                                  int.parse(userData.school.group.uid[0]));
                          CacheManagerMemory.dayIsHome = atHome;
                        });
                      }
                    });
                },
                calendarController: _calendarController,
                availableCalendarFormats: {
                  // Don't mind this, this calendar is weird...
                  CalendarFormat.month: 'Semaine',
                  CalendarFormat.twoWeeks: 'Mois',
                  CalendarFormat.week: '2 semaines'
                },
              ),
              /* 
                  lazy to describe everything here, this is just the frontend part of the courses list
                  */
              Expanded(
                  child: ListView(
                      children: CacheManagerMemory.dayCourses.entries
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
                                                            getNextCourse(
                                                                    e.key,
                                                                    e.value['codeActivite'],
                                                                    CacheManagerMemory.courses)
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
