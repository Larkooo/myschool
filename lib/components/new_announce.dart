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
              child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
              Text(
                "Prévisualisation",
                style: TextStyle(fontSize: 20, color: Colors.grey[600]),
              ),
              SizedBox(
                height: 10,
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
              SizedBox(
                height: 15,
              ),
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
              SizedBox(
                height: 15,
              ),
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
                              widget.user);
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
        )));
  }
}
