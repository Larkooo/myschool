import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:myschool/components/login.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/homeSkeleton.dart';
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
                        setState(() {
                          _mySchoolLogoHeight += 30;
                          _mySchoolLogoWidth -= 30;
                        });
                        Future.delayed(
                            Duration(milliseconds: 100),
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
                            validator: (value) {
                              if (value.isEmpty)
                                return 'Ce champs est obligatoire.';
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
                            validator: (value) {
                              if (value.isEmpty)
                                return 'Ce champs est obligatoire.';
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
                        validator: (value) {
                          if (value.isEmpty)
                            return 'Ce champs est obligatoire.';
                          bool v = EmailValidator.validate(value);
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
                          if (value.isEmpty)
                            return 'Ce champs est obligatoire.';
                          bool v = PasswordValidator(min: 6, max: 30)
                              .validate(value);
                          if (!v && value.length <= 30) {
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
                          if (value.isEmpty)
                            return 'Ce champs est obligatoire.';
                          if (value.length < 5) {
                            return "Code invalide.";
                          }
                          return null;
                        },
                        obscureText: false,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Code de groupe',
                        ),
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  mainBlueLoadingBtn(context, _btnController, "Créer un compte",
                      () async {
                    if (_formKey.currentState.validate()) {
                      _btnController.start();
                      dynamic registerStatus =
                          await FirebaseAuthService.register(
                              _firstNameController.text,
                              _lastNameController.text,
                              _emailController.text,
                              _passwordController.text,
                              _codeController.text);
                      print(registerStatus);
                      if (registerStatus is UserData) {
                        Alert(message: "Compte crée").show();
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
                        Navigator.pop(context);
                      } else if (registerStatus == AuthCodes.emailAlreadyUsed) {
                        Alert(
                                message:
                                    "Un compte avec cette adresse email existe déjà")
                            .show();
                        _btnController.stop();
                      } else if (registerStatus == AuthCodes.codeNotFound) {
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
