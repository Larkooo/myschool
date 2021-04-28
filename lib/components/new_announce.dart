import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:alert/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:provider/provider.dart';

import 'announce.dart';

// ignore: must_be_immutable
class NewAnnounce extends StatefulWidget {
  String group;
  final UserData user;
  NewAnnounce({this.group, this.user});

  @override
  _NewAnnounceState createState() => _NewAnnounceState();
}

class _NewAnnounceState extends State<NewAnnounce> {
  TextEditingController _announceTitle = TextEditingController();
  TextEditingController _announceContent = TextEditingController();

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  Scope _announceScope;

  List<PlatformFile> attachmentFiles;

  @override
  void initState() {
    // TODO: implement initState
    _announceScope = widget.group != null ? Scope.group : Scope.school;
    super.initState();
    if (widget.group == null) widget.group = widget.user.groups[0];
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Nouvelle annonce'),
        ),
        body: SingleChildScrollView(
            child: Form(
          key: _formKey,
          child: Center(
              child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            direction: Axis.vertical,
            children: [
              SizedBox(
                height: 10,
              ),
              Text(
                "Prévisualisation",
                style: TextStyle(fontSize: 20, color: Colors.grey[600]),
              ),
              Container(
                  width: MediaQuery.of(context).size.width / 1.26,
                  child: Announce(
                    announcement: Announcement(
                        uid: '-1',
                        author: widget.user.uid,
                        title: _announceTitle.text,
                        content: _announceContent.text,
                        scope: _announceScope,
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
                    controller: _announceTitle,
                    validator: (value) {
                      if (value.isEmpty) return 'Ce champ est obligatoire.';
                      if (value.length < 3) return 'Titre trop court.';

                      return null;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Titre',
                      hintText: "ex. Mon annonce",
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

                    controller: _announceContent,
                    validator: (value) {
                      if (value.isEmpty) return 'Ce champ est obligatoire.';
                      if (value.length < 10) return 'Contenu trop court.';

                      return null;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Description',
                    ),
                  )),
              Container(
                  width: MediaQuery.of(context).size.width / 2.3,
                  child: DropdownButtonFormField(
                    items: [
                      DropdownMenuItem(
                        child: Text("École"),
                        value: Scope.school,
                      ),
                      DropdownMenuItem(
                        child: Text("Groupe"),
                        value: Scope.group,
                      ),
                    ],
                    value: _announceScope,
                    onChanged: (value) {
                      setState(() {
                        _announceScope = value;
                      });
                    },
                  )),
              if (_announceScope == Scope.group)
                Container(
                    width: MediaQuery.of(context).size.width / 2.3,
                    child: DropdownButtonFormField(
                      items: widget.user.groups
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
              themeIconButton(
                  context, Text('Attacher des fichiers'), Icon(Icons.add),
                  () async {
                final fileType = await showModalActionSheet<FileType>(
                    context: context,
                    title: 'Attacher des fichiers',
                    message: 'Voulez-vous attacher des images ou des fichiers',
                    actions: [
                      SheetAction(label: 'Fichier', key: FileType.any),
                      SheetAction(label: 'Média', key: FileType.media)
                    ]);
                if (fileType == null) return;
                FilePickerResult result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.any,
                );
                if (result == null || result.count == 0) return;
                if (result.count > 8)
                  return Alert(
                          message:
                              'Vous ne pouvez mettre qu\'un maximum de 8 fichiers')
                      .show();
                const double maxSize = 2.5e+7;
                int totalSize = 0;
                result.files.forEach((file) => totalSize += file.size);
                if (totalSize > maxSize)
                  return Alert(
                          message: 'La taille maximum est de 25 mégaoctets')
                      .show();
                setState(() {
                  attachmentFiles = result.files;
                });
              }, size: 1.09),
              if (attachmentFiles != null && attachmentFiles.isNotEmpty)
                Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width),
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 5,
                          children: attachmentFiles
                              .map((file) => Stack(children: [
                                    Container(
                                      constraints: BoxConstraints(
                                          minHeight: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              5,
                                          minWidth: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              3),
                                      child: Material(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.file_present),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Text(
                                              file.name.length > 10
                                                  ? file.name.substring(0, 10) +
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
                                            type: MaterialType.transparency,
                                            clipBehavior: Clip.antiAlias,
                                            borderRadius:
                                                BorderRadius.circular(45),
                                            child: IconButton(
                                                splashRadius: 15,
                                                iconSize: 18,
                                                icon: Icon(Icons.close),
                                                onPressed: () {
                                                  setState(() {
                                                    attachmentFiles
                                                        .remove(file);
                                                  });
                                                }))),
                                  ]))
                              .toList(),
                        ))),
              mainBlueLoadingBtn(context, _btnController, "Envoyer", () async {
                if (_formKey.currentState.validate()) {
                  _btnController.start();
                  bool announce =
                      await DatabaseService(uid: widget.user.school.uid)
                          .createAnnounce(
                              _announceTitle.text,
                              _announceContent.text,
                              _announceScope == Scope.group
                                  ? widget.group
                                  : _announceScope,
                              widget.user,
                              attachments: attachmentFiles);
                  if (announce == true) {
                    _btnController.success();
                    Navigator.pop(context);
                  } else {
                    _btnController.reset();
                    Alert(message: "Erreur").show();
                  }
                }
              }),
              SizedBox(
                height: 10,
              )
            ],
          )),
        )));
  }
}
