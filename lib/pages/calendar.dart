import 'dart:convert';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/mozaik.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/services/mozaik_service.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:dart_date/dart_date.dart';
import 'package:myschool/shared/cachemanager.dart';

import '../components/mozaik_login.dart';

class Calendar extends StatefulWidget {
  final UserData user;
  Calendar({this.user});

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
    CacheManagerMemory.dayCourses.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /* 
                  
                  
              if (CacheManagerMemory.remoteSchoolDays.isNotEmpty)
                Container(
                    width: MediaQuery.of(context).size.width,
                    height: 30,
                    color: CacheManagerMemory.dayIsHome
                        ? Colors.blue
                        : Colors.green,
                    child: Center(
                      child: Text(dayIsHome()),
                    )),
                    */
        TableCalendar(
          initialSelectedDay: _selectedDay,
          startDay: _startDay,
          endDay: _endDay,
          events: CacheManagerMemory.courses.isEmpty
              ? null
              : CacheManagerMemory.courses
                  .map((key, value) => MapEntry(key, [value])),
          availableCalendarFormats: {
            CalendarFormat.month: 'Mois',
            CalendarFormat.twoWeeks: '2 semaines',
            CalendarFormat.week: 'Semaine'
          },
          calendarStyle: CalendarStyle(markersColor: Colors.blue),
          onCalendarCreated: (first, last, format) async {
            /* 
                    If CacheManagerMemory.courses has a length of 0 => get the download URL of our timetable
                    download it,
                    cache it,
                    and decode it as JSON to assign it to our static variable

                  */
            if (CacheManagerMemory.courses.isEmpty) {
              SchedulerBinding.instance.addPostFrameCallback((_) async {
                OkCancelResult result = await showModalActionSheet(
                    context: context,
                    title: 'Calendrier',
                    message:
                        'Pour importer tous vos cours sur le calendrier MonÉcole, vous devez vous connecter à votre compte Mozaik',
                    cancelLabel: 'Annuler',
                    actions: [
                      SheetAction(key: OkCancelResult.ok, label: 'Continuer'),
                    ]);
                if (result == OkCancelResult.ok) {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  String timetableEncoded = prefs.getString('mozaikTimetable');
                  bool mozaikLoyal = prefs.getBool('mozaikLoyal') ?? false;

                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Opacity(
                                opacity: mozaikLoyal ? 0 : 1,
                                child: MozaikLogin(),
                              )));

                  if (Mozaik.payload == null && timetableEncoded == null)
                    return;

                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          Center(child: CircularProgressIndicator()));

                  //print(timetableEncoded);
                  //print(await MozaikService.getMozaikTimetable());

                  dynamic timetable = timetableEncoded == null
                      ? await MozaikService.getMozaikTimetable()
                      : jsonDecode(timetableEncoded);

                  prefs.setString('mozaikTimetable', jsonEncode(timetable));
                  CacheManagerMemory.rawMozaikTimetable = timetable;

                  // Setting the startday and the endday of the calendar (so the startday/endday of school in this case)
                  setState(() {
                    CacheManagerMemory.courses = Map.fromIterable(timetable,
                        key: (e) => DateTime.parse(
                            e['dateDebut'] + 'T' + e['heureDebut']),
                        value: (e) => {
                              "description": e['description'],
                              "locaux": e['locaux'],
                              "intervenants": e['intervenants'],
                              "heureFin": e['heureFin'],
                              "codeActivite": e['codeActivite']
                            });
                    _startDay = CacheManagerMemory.courses.entries.first.key;
                    _endDay = CacheManagerMemory.courses.entries.last.key;
                  });

                  Navigator.pop(context);
                }
              });
            }

            /*
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
                  } */

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
                      */
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
            /*
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
                    });*/
          },
          calendarController: _calendarController,
        ),
        /* 
                  lazy to describe everything here, this is just the frontend part of the courses list
                  */
        Expanded(
            child: ListView(
                children: CacheManagerMemory.dayCourses.entries
                    .map((e) => Platform.isAndroid
                        ? Card(
                            child: ListTile(
                              onTap: () => showSlideDialog(
                                  context: context,
                                  child: coursePage(
                                      context,
                                      widget.user,
                                      e.value['codeActivite'],
                                      e.value['description'],
                                      e.key,
                                      e.value['intervenants'],
                                      e.value['heureFin'],
                                      e.value['locaux'])),
                              title: Text(e.value['description'] +
                                  " (${e.value['locaux'][0]})"),
                              subtitle: Text(e.value['intervenants'][0]['nom'] +
                                  " " +
                                  e.value['intervenants'][0]['prenom'] +
                                  " - " +
                                  DateFormat.Hm().format(e.key)),
                            ),
                          )
                        : CupertinoContextMenu(
                            actions: [
                                CupertinoContextMenuAction(
                                  trailingIcon: Icons.calendar_today,
                                  isDefaultAction: true,
                                  child: Text('Ajouter un rappel',
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    List<int> endHourSplit =
                                        (e.value['heureFin'] as String)
                                            .split(':')
                                            .map((e) => int.tryParse(e))
                                            .toList();
                                    DateTime endTime = DateTime(
                                        e.key.year,
                                        e.key.month,
                                        e.key.day,
                                        endHourSplit[0],
                                        endHourSplit[1]);
                                    final Event event = Event(
                                        title: e.value['description'],
                                        startDate: e.key,
                                        endDate: endTime);
                                    Add2Calendar.addEvent2Cal(event);
                                  },
                                )
                              ],
                            child: Card(
                              child: ListTile(
                                onTap: () => showSlideDialog(
                                    context: context,
                                    child: coursePage(
                                        context,
                                        widget.user,
                                        e.value['codeActivite'],
                                        e.value['description'],
                                        e.key,
                                        e.value['intervenants'],
                                        e.value['heureFin'],
                                        e.value['locaux'])),
                                title: Text(e.value['description'] +
                                    " (${e.value['locaux'][0]})"),
                                subtitle: Text(e.value['intervenants'][0]
                                        ['nom'] +
                                    " " +
                                    e.value['intervenants'][0]['prenom'] +
                                    " - " +
                                    DateFormat.Hm().format(e.key)),
                              ),
                            )))
                    .toList()))
      ],
    );
  }
}
