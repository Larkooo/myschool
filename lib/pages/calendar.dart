import 'dart:convert';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
import 'package:modal_progress_hud/modal_progress_hud.dart';

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

  bool loading = false;

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
    return ModalProgressHUD(
      color: Colors.grey[800].withOpacity(0.8),
      progressIndicator: CircularProgressIndicator.adaptive(),
      child: Column(
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
              SharedPreferences prefs = await SharedPreferences.getInstance();

              SchedulerBinding.instance.addPostFrameCallback((_) async {
                dynamic timetable =
                    jsonDecode(prefs.getString('mozaikTimetable') ?? 'null');

                if (CacheManagerMemory.courses.isEmpty && timetable == null) {
                  OkCancelResult result = await showModalActionSheet(
                      context: context,
                      title: 'Calendrier',
                      message:
                          'Pour importer tous vos cours sur le calendrier MonÉcole, vous devez vous connecter à votre compte Mozaik',
                      cancelLabel: 'Annuler',
                      actions: [
                        SheetAction(key: OkCancelResult.ok, label: 'Continuer'),
                      ]);
                  if (result != OkCancelResult.ok) return;
                  setState(() {
                    loading = true;
                  });

                  bool mozaikLoyal = prefs.getBool('mozaikLoyal') ?? false;

                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Opacity(
                                opacity: mozaikLoyal ? 0 : 1,
                                child: MozaikLogin(),
                              )));

                  if (Mozaik.payload == null) return;

                  //print(timetableEncoded);
                  //print(await MozaikService.getMozaikTimetable());

                  timetable = await MozaikService.getMozaikTimetable();
                  prefs.setString('mozaikTimetable', jsonEncode(timetable));
                  CacheManagerMemory.rawMozaikTimetable = timetable;
                }

                // Setting the startday and the endday of the calendar (so the startday/endday of school in this case)
                if (CacheManagerMemory.courses.isEmpty) {
                  setState(() {
                    loading = true;
                    CacheManagerMemory.courses = Map.fromIterable(timetable,
                        key: (e) => DateTime.parse(
                            e['dateDebut'] + 'T' + e['heureDebut']),
                        value: (e) => {
                              "description":
                                  widget.user.type == UserType.student
                                      ? e['description']
                                      : e['descrPeriode'],
                              "locaux": widget.user.type == UserType.student
                                  ? e['locaux']
                                  : [e['local'] as String],
                              "intervenants":
                                  widget.user.type == UserType.student
                                      ? e['intervenants']
                                      : [
                                          {
                                            'prenom': widget.user.firstName,
                                            'nom': widget.user.lastName
                                          }
                                        ],
                              "heureFin": e['heureFin'],
                              "codeActivite": e['codeActivite']
                            });
                    _startDay = CacheManagerMemory.courses.entries.first.key;
                    _endDay = CacheManagerMemory.courses.entries.last.key;
                  });
                }

                CacheManagerMemory.courses.forEach((day, data) {
                  if (day.isSameDay(_selectedDay)) {
                    setState(() {
                      CacheManagerMemory.dayCourses[day] = data;
                    });
                  }
                });
                setState(() {
                  loading = false;
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
            },
            calendarController: _calendarController,
          ),
          /* 
                  lazy to describe everything here, this is just the frontend part of the courses list
                  */
          Expanded(
              child: ListView(children: [
            Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                    leading: Icon(Icons.add_comment),
                    title: Text('Ajouter une note'),
                    onTap: () async {
                      List<String> inputs = await showTextInputDialog(
                          context: context,
                          title: 'Ajouter une note',
                          textFields: [DialogTextField(hintText: 'Note')]);
                      if (inputs == null || inputs.length < 1) return;
                      String noteContent = inputs[0];
                    })),
            ...CacheManagerMemory.dayCourses.entries.map((e) {
              Card card = Card(
                child: ListTile(
                  onTap: () => showBarModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                          height: MediaQuery.of(context).size.height / 1.8,
                          child: Material(
                              child: coursePage(
                                  context,
                                  widget.user,
                                  e.value['codeActivite'],
                                  e.value['description'],
                                  e.key,
                                  e.value['intervenants'],
                                  e.value['heureFin'],
                                  e.value['locaux'])))),
                  title: Text(
                      e.value['description'] + " (${e.value['locaux'][0]})"),
                  subtitle: Text(e.value['intervenants'][0]['nom'] +
                      " " +
                      e.value['intervenants'][0]['prenom'] +
                      " - " +
                      DateFormat.Hm().format(e.key)),
                ),
              );
              return Platform.isAndroid
                  ? card
                  : CupertinoContextMenu(actions: [
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
                          DateTime endTime = DateTime(e.key.year, e.key.month,
                              e.key.day, endHourSplit[0], endHourSplit[1]);
                          final Event event = Event(
                              title: e.value['description'],
                              startDate: e.key,
                              endDate: endTime);
                          Add2Calendar.addEvent2Cal(event);
                        },
                      )
                    ], child: card);
            }).toList()
          ]))
        ],
      ),
      inAsyncCall: loading,
    );
  }
}
