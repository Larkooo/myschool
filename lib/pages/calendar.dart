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
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, String> _events;
  Map<DateTime, String> _dayEvents = Map<DateTime, String>();

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
              TableCalendar(
                onCalendarCreated: (first, last, format) async {
                  final schoolTimetableURL = await StorageService(
                          ref: "/schools/${userData.school.uid}/timetable.json")
                      .getDownloadURL();
                  final schoolTimetableFile = await DefaultCacheManager()
                      .getSingleFile(schoolTimetableURL);
                  _events = Map.fromIterable(
                      jsonDecode(await schoolTimetableFile.readAsString()),
                      key: (e) => DateTime.parse(
                          e['dateDebut'] + 'T' + e['heureDebut']),
                      value: (e) => e['description']);
                  _events.forEach((day, desc) {
                    if (day.isSameDay(_selectedDay)) {
                      setState(() {
                        _dayEvents[day] = desc;
                      });
                    }
                  });
                  print(_dayEvents);
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
                },
                calendarController: _calendarController,
                availableCalendarFormats: {
                  CalendarFormat.month: 'Mois',
                  CalendarFormat.twoWeeks: '2 semaines',
                  CalendarFormat.week: 'Semaine'
                },
              ),
              Expanded(
                  child: ListView(
                      children: _dayEvents.entries
                          .map((e) => Card(
                                child: ListTile(
                                  title: Text(e.value),
                                  subtitle: Text(DateFormat.Hm().format(e.key)),
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
