import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/services.dart';
import 'package:myschool/pages/login.dart';
import 'package:myschool/components/select_groups.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/home_skeleton.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/shared/constants.dart';
import 'package:password_validator/password_validator.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';

import '../main.dart';
import 'package:alert/alert.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _codeController = TextEditingController();
  // UserType _userType = UserType.student;

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  final _formKey = GlobalKey<FormState>();

  int _secretCount = 0;

  double _mySchoolLogoWidth = 100;
  double _mySchoolLogoHeight = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Form(
            key: _formKey,
            child: Center(
                child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // meow
                  GestureDetector(
                      onTap: () {
                        SystemSound.play(SystemSoundType.click);
                        setState(() {
                          _mySchoolLogoHeight -= 50;
                          _mySchoolLogoWidth -= 50;
                        });
                        Future.delayed(
                            Duration(milliseconds: 50),
                            () => setState(() {
                                  _mySchoolLogoHeight = 100;
                                  _mySchoolLogoWidth = 100;
                                }));
                        _secretCount++;
                        if (_secretCount > 6) {
                          Alert(
                                  message:
                                      "Fait avec meow par Nasr AA. Djeghmoum")
                              .show();
                          _secretCount = 0;
                        }
                      },
                      child: AnimatedContainer(
                        width: _mySchoolLogoWidth,
                        height: _mySchoolLogoHeight,
                        duration: Duration(milliseconds: 300),
                        child: Image.asset(
                          "assets/logo.png",
                        ),
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: MediaQuery.of(context).size.width / 2.621,
                          child: TextFormField(
                            controller: _firstNameController,
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value.isEmpty)
                                return 'Ce champ est obligatoire.';
                              return null;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Prénom',
                            ),
                          )),
                      SizedBox(
                        width: 5,
                      ),
                      Container(
                          width: MediaQuery.of(context).size.width / 2.621,
                          child: TextFormField(
                            controller: _lastNameController,
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value.isEmpty)
                                return 'Ce champ est obligatoire.';
                              return null;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Nom de famille',
                            ),
                          ))
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value.isEmpty) return 'Ce champ est obligatoire.';
                          bool v = EmailValidator.validate(value.trim());
                          if (!v) {
                            return "Adresse courriel invalide.";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Courriel',
                          hintText: "example@domain.com",
                        ),
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: TextFormField(
                        controller: _passwordController,
                        validator: (value) {
                          if (value.isEmpty) return 'Ce champ est obligatoire.';
                          bool v = PasswordValidator(min: 6, max: 30)
                              .validate(value.trim());
                          if (!v && value.trim().length <= 30) {
                            return "6 caractères minimum.";
                          } else if (!v) {
                            return "Mot de passe trop long.";
                          }
                          return null;
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Mot de passe',
                        ),
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: TextFormField(
                        controller: _codeController,
                        validator: (value) {
                          if (value.isEmpty) return 'Ce champ est obligatoire.';
                          if (value.length < 5) {
                            return "Code invalide.";
                          }
                          return null;
                        },
                        obscureText: false,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Code",
                        ),
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  /* May not be needed Container(
                      width: MediaQuery.of(context).size.width / 2.6,
                      height: 60,
                      child: DropdownButtonFormField(
                        icon: Icon(Icons.person),
                        decoration:
                            InputDecoration(border: OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(
                              child: Text("Élève"), value: UserType.student),
                          DropdownMenuItem(
                            child: Text("Enseignant"),
                            value: UserType.teacher,
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _userType = value;
                          });
                        },
                      )), */
                  SizedBox(
                    height: 10,
                  ),
                  mainBlueLoadingBtn(context, _btnController, "Créer un compte",
                      () async {
                    if (_formKey.currentState.validate()) {
                      _btnController.start();
                      dynamic registerStatus =
                          await FirebaseAuthService.register(
                              _firstNameController.text.trim(),
                              _lastNameController.text.trim(),
                              _emailController.text.trim(),
                              _passwordController.text,
                              _codeController.text.toLowerCase().trim());
                      if (registerStatus is UserData) {
                        _btnController.success();
                        //showSlideDialog(
                        //    context: context,
                        //    child: Column(
                        //      children: <Widget>[
                        //        Image.asset(
                        //          "assets/logo.png",
                        //          width: 80,
                        //          height: 80,
                        //        ),
                        //        SizedBox(
                        //          height: 10,
                        //        ),
                        //        Text(
                        //          "Bienvenue ${_firstNameController.text} sur MonÉcole !",
                        //          style: TextStyle(fontSize: 15),
                        //        )
                        //      ],
                        //    ));

                        // initially, for just some simplicity, the staff member is a teacher but he has to then choose his role
                        if (registerStatus.type == UserType.teacher) {
                          // he can choose to be a teacher or just a staff member
                          UserType choosenType = await showModalActionSheet<
                                  UserType>(
                              context: context,
                              title: registerStatus.firstName,
                              message:
                                  'Êtes-vous un professeur ou un autre membre du personnel?',
                              actions: [
                                SheetAction(
                                    label: 'Professeur', key: UserType.teacher),
                                SheetAction(
                                    label: 'Autre membre du personnel',
                                    key: UserType.staff)
                              ]);
                          await DatabaseService(uid: registerStatus.uid)
                              .updateUserData(userType: choosenType);
                          Navigator.pop(context);
                          // if the new role of the user is teacher, then we ask him to choose his groups
                          if (choosenType == UserType.teacher)
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SelectGroups(
                                          user: registerStatus,
                                        )));
                        }
                      } else if (registerStatus == AuthCode.emailAlreadyUsed) {
                        Alert(
                                message:
                                    "Un compte avec cette adresse courriel existe déjà")
                            .show();
                        _btnController.stop();
                      } else if (registerStatus == AuthCode.codeNotFound) {
                        Alert(message: "Code inexistant").show();
                        _btnController.stop();
                      } else {
                        Alert(message: "Erreur").show();
                        _btnController.stop();
                      }
                    }
                  }),
                  textButton(
                      context, "Se connecter", () => Navigator.pop(context))
                ],
              ),
            ))));
  }
}
