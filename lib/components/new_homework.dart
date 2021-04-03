import 'dart:io';

import 'package:alert/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/homework.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:provider/provider.dart';

import 'announce.dart';
import 'homeworkcomp.dart';

// ignore: must_be_immutable
class NewHomework extends StatefulWidget {
  String group;
  NewHomework({this.group});

  @override
  _NewHomeworkState createState() => _NewHomeworkState();
}

class _NewHomeworkState extends State<NewHomework> {
  TextEditingController _homeworkTitle = TextEditingController();
  TextEditingController _homeworkDescription = TextEditingController();
  TextEditingController _homeworkSubject = TextEditingController();
  DateTime due = DateTime.now().add(Duration(days: 1));

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Scaffold(
        appBar: AppBar(
          title: Text('Nouveau devoir'),
        ),
        body: SingleChildScrollView(
            child: StreamBuilder(
                stream: DatabaseService(uid: user.uid).user,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    UserData user = snapshot.data;
                    if (widget.group == null)
                      widget.group = user.groups[0].toString();
                    return Form(
                      key: _formKey,
                      child: Center(
                          child: Column(
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Preview",
                            style: TextStyle(
                                fontSize: 20, color: Colors.grey[600]),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 1.26,
                              child: HomeworkComp(
                                homework: Homework(
                                    uid: -1,
                                    author: user.uid,
                                    title: _homeworkTitle.text,
                                    description: _homeworkDescription.text,
                                    subject: _homeworkSubject.text,
                                    due: due,
                                    createdAt: DateTime.now()),
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 1.3,
                              child: TextFormField(
                                // dummy setstates to refresh values
                                onChanged: (_) {
                                  setState(() {});
                                },
                                maxLength: 25,
                                controller: _homeworkTitle,
                                validator: (value) {
                                  if (value.isEmpty)
                                    return 'Ce champs est obligatoire.';
                                  if (value.length < 5)
                                    return 'Titre trop court.';

                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Titre',
                                  hintText: "Devoir #1",
                                ),
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 1.3,
                              child: TextFormField(
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                minLines: 5,
                                // dummy setstate to refresh values
                                onChanged: (_) {
                                  setState(() {});
                                },

                                controller: _homeworkDescription,
                                validator: (value) {
                                  if (value.isEmpty)
                                    return 'Ce champs est obligatoire.';
                                  if (value.length < 10)
                                    return 'Contenu trop court.';

                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Description',
                                ),
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 1.3,
                              child: TextFormField(
                                // dummy setstates to refresh values
                                onChanged: (_) {
                                  setState(() {});
                                },
                                maxLength: 15,
                                controller: _homeworkSubject,
                                validator: (value) {
                                  if (value.isEmpty)
                                    return 'Ce champs est obligatoire.';
                                  if (value.length < 3)
                                    return 'Texte trop court.';

                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Matière',
                                  hintText: "Français",
                                ),
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 2.3,
                              child: DropdownButtonFormField(
                                items: user.groups
                                    .map((e) => DropdownMenuItem(
                                          child: Text(e.toString()),
                                          value: e.toString(),
                                        ))
                                    .toList(),
                                value: widget.group,
                                onChanged: (value) {
                                  setState(() {
                                    widget.group = value;
                                  });
                                },
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                              height: MediaQuery.of(context).size.height / 3,
                              width: MediaQuery.of(context).size.height / 2.5,
                              child: adaptiveCalendarPicker(
                                due,
                                DateTime.now(),
                                DateTime.now().add(Duration(days: 90)),
                                Platform.isAndroid
                                    ? (date) {
                                        showTimePicker(
                                          context: context,
                                          initialTime:
                                              TimeOfDay(hour: 12, minute: 30),
                                        ).then((time) {
                                          date = DateTime(date.year, date.month,
                                              date.day, time.hour, time.minute);
                                          setState(() {
                                            due = date;
                                          });
                                        });
                                      }
                                    : (date) {},
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          mainBlueLoadingBtn(context, _btnController, "Publier",
                              () async {
                            if (_formKey.currentState.validate()) {
                              _btnController.start();
                              bool homework =
                                  await DatabaseService(uid: user.school.uid)
                                      .createHomework(
                                          _homeworkTitle.text,
                                          _homeworkDescription.text,
                                          _homeworkSubject.text,
                                          user,
                                          due,
                                          widget.group);
                              if (homework == true) {
                                _btnController.success();
                                Navigator.pop(context);
                              } else {
                                _btnController.reset();
                                Alert(message: "Erreur").show();
                              }
                            }
                          }),
                          SizedBox(
                            height: 15,
                          ),
                        ],
                      )),
                    );
                  } else {
                    return Center(child: CircularProgressIndicator.adaptive());
                  }
                })));
  }
}
