import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:alert/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
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
  final UserData user;
  String group;
  NewHomework({this.group, this.user});

  @override
  _NewHomeworkState createState() => _NewHomeworkState();
}

class _NewHomeworkState extends State<NewHomework> {
  TextEditingController _homeworkTitle = TextEditingController();
  TextEditingController _homeworkDescription = TextEditingController();
  TextEditingController _homeworkSubject = TextEditingController();
  DateTime due = DateTime.now().add(Duration(days: 1));

  List<PlatformFile> attachmentFiles;

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
                    if (widget.group == null) widget.group = user.groups[0];
                    return Form(
                      key: _formKey,
                      child: Center(
                          child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 20,
                        direction: Axis.vertical,
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Prévisualisation",
                            style: TextStyle(fontSize: 20),
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 1.26,
                              child: HomeworkComp(
                                homework: Homework(
                                    uid: '-1',
                                    author: user.uid,
                                    title: _homeworkTitle.text,
                                    description: _homeworkDescription.text,
                                    subject: _homeworkSubject.text,
                                    due: due,
                                    attachments: [],
                                    createdAt: DateTime.now()),
                              )),
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
                                    return 'Ce champ est obligatoire.';
                                  if (value.length < 3)
                                    return 'Titre trop court.';

                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Titre',
                                  hintText: "ex. Devoir #1",
                                ),
                              )),
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
                                    return 'Ce champ est obligatoire.';
                                  if (value.length < 5)
                                    return 'Contenu trop court.';

                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Description',
                                  hintText: "ex. Pages 8 à 11",
                                ),
                              )),
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
                                    return 'Ce champ est obligatoire.';
                                  if (value.length < 3)
                                    return 'Texte trop court.';

                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Matière',
                                  hintText: "ex. Français",
                                ),
                              )),
                          Container(
                              width: MediaQuery.of(context).size.width / 2.3,
                              child: DropdownButtonFormField(
                                items: user.groups
                                    .map((group) => DropdownMenuItem(
                                          child: Text(group),
                                          value: group,
                                        ))
                                    .toList(),
                                value: widget.group,
                                onChanged: (value) {
                                  setState(() {
                                    widget.group = value;
                                  });
                                },
                              )),
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
                          themeIconButton(
                              context,
                              Text('Attacher des fichiers'),
                              Icon(Icons.add), () async {
                            final fileType = await showModalActionSheet<
                                    FileType>(
                                context: context,
                                title: 'Attacher des fichiers',
                                message:
                                    'Voulez-vous attacher des images ou des fichiers',
                                actions: [
                                  SheetAction(
                                      label: 'Fichier', key: FileType.any),
                                  SheetAction(
                                      label: 'Média', key: FileType.media)
                                ]);
                            if (fileType == null) return;
                            FilePickerResult result =
                                await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                              type: fileType,
                            );
                            if (result == null || result.count == 0) return;
                            if (result.count > 8)
                              return Alert(
                                      message:
                                          'Vous ne pouvez mettre qu\'un maximum de 8 fichiers')
                                  .show();
                            const double maxSize = 2.5e+7;
                            int totalSize = 0;
                            result.files
                                .forEach((file) => totalSize += file.size);
                            if (totalSize > maxSize)
                              return Alert(
                                      message:
                                          'La taille maximum est de 25 mégaoctets')
                                  .show();
                            setState(() {
                              attachmentFiles = result.files;
                            });
                          }, size: 1.09),
                          if (attachmentFiles != null &&
                              attachmentFiles.isNotEmpty)
                            Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width),
                                child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Wrap(
                                      spacing: 5,
                                      children: attachmentFiles
                                          .map((file) => Stack(children: [
                                                Container(
                                                  constraints: BoxConstraints(
                                                      minHeight:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height /
                                                              5,
                                                      minWidth:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              3),
                                                  child: Material(
                                                    color: Theme.of(context)
                                                        .cardColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                            Icons.file_present),
                                                        SizedBox(
                                                          height: 5,
                                                        ),
                                                        Text(
                                                          file.name.length > 10
                                                              ? file.name
                                                                      .substring(
                                                                          0,
                                                                          10) +
                                                                  '...'
                                                              : file.name,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: Material(
                                                        type: MaterialType
                                                            .transparency,
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(45),
                                                        child: IconButton(
                                                            splashRadius: 15,
                                                            iconSize: 18,
                                                            icon: Icon(
                                                                Icons.close),
                                                            onPressed: () {
                                                              setState(() {
                                                                attachmentFiles
                                                                    .remove(
                                                                        file);
                                                              });
                                                            }))),
                                              ]))
                                          .toList(),
                                    ))),
                          mainBlueLoadingBtn(context, _btnController, "Envoyer",
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
                                          widget.group,
                                          attachments: attachmentFiles);
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
