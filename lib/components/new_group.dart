import 'package:alert/alert.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class NewGroup extends StatefulWidget {
  final UserData user;

  NewGroup({this.user});
  @override
  _NewGroupState createState() => _NewGroupState();
}

class _NewGroupState extends State<NewGroup> {
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _groupIdController = TextEditingController();
  TextEditingController _groupCodeController = TextEditingController();

  RoundedLoadingButtonController _buttonController =
      RoundedLoadingButtonController();

  final _formKey = GlobalKey<FormState>();

  UserType _groupCodeType = UserType.student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Créer un groupe'),
        ),
        body: SingleChildScrollView(
          child: Center(
              child: SingleChildScrollView(
                  child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height / 10,
                ),
                Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    child: TextFormField(
                      maxLength: 25,
                      controller: _groupNameController,
                      validator: (value) {
                        if (value.isEmpty) return 'Ce champ est obligatoire.';
                        if (value.length < 3) return 'Nom trop court.';

                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nom',
                        hintText: "ex. Groupe de lecture",
                      ),
                    )),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 80,
                ),
                Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    child: TextFormField(
                      maxLength: 25,
                      controller: _groupIdController,
                      validator: (value) {
                        if (value.isEmpty) return 'Ce champ est obligatoire.';
                        if (value.length < 3) return 'ID trop court.';

                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'ID',
                        hintText:
                            "Identifiant unique pour le groupe, ex. lecture5",
                      ),
                    )),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 80,
                ),
                Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    child: TextFormField(
                      // dummy setstate to refresh the values
                      onChanged: (_) {
                        setState(() {});
                      },
                      maxLength: 25,
                      controller: _groupCodeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Code (optionnel)',
                        hintText: "Code lié au groupe",
                      ),
                    )),
                if (_groupCodeController.text.length > 0)
                  Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 80,
                      ),
                      Text('Permissions accordés avec le code'),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 80,
                      ),
                      Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: DropdownButtonFormField<UserType>(
                            items: [
                              DropdownMenuItem(
                                child: Text("Étudiant"),
                                value: UserType.student,
                              ),
                              DropdownMenuItem(
                                child: Text("Professeur"),
                                value: UserType.teacher,
                              ),
                              DropdownMenuItem(
                                child: Text("Membre du personnel"),
                                value: UserType.staff,
                              ),
                              DropdownMenuItem(
                                child: Text("Direction"),
                                value: UserType.direction,
                              ),
                            ],
                            value: _groupCodeType,
                            onChanged: (value) {
                              setState(() {
                                _groupCodeType = value;
                              });
                            },
                          )),
                    ],
                  ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 30,
                ),
                mainBlueLoadingBtn(context, _buttonController, "Créer",
                    () async {
                  if (_formKey.currentState.validate()) {
                    _buttonController.start();
                    bool groupCreated = await DatabaseService(
                            uid: widget.user.school.uid)
                        .createGroup(
                            _groupNameController.text, _groupIdController.text,
                            code: _groupCodeController.text.length > 0
                                ? _groupCodeController.text
                                : null,
                            codeType: _groupCodeController.text.length > 0
                                ? _groupCodeType
                                : null);
                    if (groupCreated) {
                      _buttonController.success();
                      Alert(
                              message:
                                  'Groupe crée. Pour l\'ajouter dans vos groupes, visitez les paramètres')
                          .show();
                      Navigator.pop(context);
                    } else {
                      _buttonController.error();
                    }
                  }
                })
              ],
            ),
          ))),
        ));
  }
}
