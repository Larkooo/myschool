import 'package:alert/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:provider/provider.dart';

import 'announce.dart';

class NewAnnounce extends StatefulWidget {
  @override
  _NewAnnounceState createState() => _NewAnnounceState();
}

class _NewAnnounceState extends State<NewAnnounce> {
  String _announceTitleText = "";
  String _announceContentText = "";
  TextEditingController _announceTitle = TextEditingController();
  TextEditingController _announceContent = TextEditingController();

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  Scope _announceScope = Scope.group;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
            child: StreamBuilder(
                stream: DatabaseService(uid: user.uid).user,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    UserData user = snapshot.data;
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
                              child: Announce(
                                announcement: Announcement(
                                    uid: -1,
                                    author: user.uid,
                                    title: _announceTitleText,
                                    content: _announceContent.text,
                                    scope: _announceScope,
                                    createdAt: DateTime.now()),
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 1.3,
                              child: TextFormField(
                                onChanged: (text) {
                                  setState(() {
                                    _announceTitleText = text;
                                  });
                                },
                                controller: _announceTitle,
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
                                  hintText: "Mon annonce",
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
                                onChanged: (value) {
                                  setState(() {
                                    _announceContentText = value;
                                  });
                                },
                                controller: _announceContent,
                                validator: (value) {
                                  if (value.isEmpty)
                                    return 'Ce champs est obligatoire.';
                                  if (value.length < 10)
                                    return 'Contenu trop court.';

                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Contenu',
                                ),
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 2.3,
                              child: DropdownButtonFormField(
                                items: [
                                  DropdownMenuItem(
                                    child: Text("École"),
                                    value: Scope.school,
                                  ),
                                  DropdownMenuItem(
                                    child: Text("Foyer"),
                                    value: Scope.group,
                                  ),
                                ],
                                value: Scope.group,
                                onChanged: (value) {
                                  setState(() {
                                    _announceScope = value;
                                  });
                                },
                              )),
                          SizedBox(
                            height: 15,
                          ),
                          mainBlueLoadingBtn(context, _btnController, "Publier",
                              () async {
                            if (_formKey.currentState.validate()) {
                              _btnController.start();
                              bool announce =
                                  await DatabaseService(uid: user.school.uid)
                                      .createAnnounce(
                                          _announceTitle.text,
                                          _announceContent.text,
                                          _announceScope,
                                          user);
                              if (announce == true) {
                                _btnController.success();
                                Navigator.pop(context);
                              } else {
                                _btnController.reset();
                                Alert(message: "Erreur").show();
                              }
                            }
                          })
                        ],
                      )),
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                })));
  }
}
