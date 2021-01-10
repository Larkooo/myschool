import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:myschool/components/register.dart';
import 'package:myschool/components/resetPassword.dart';
import 'package:myschool/services/firebase.dart';
import 'package:myschool/shared/constants.dart';
import 'package:password_validator/password_validator.dart';
import 'package:alert/alert.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';

import '../main.dart';

class Login extends StatefulWidget {
  final Stream<int> stream;

  Login({this.stream});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  final _formKey = GlobalKey<FormState>();

  int secretCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Form(
            key: _formKey,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      secretCount++;
                      if (secretCount > 6) {
                        Alert(message: "Fait avec meow par Nasr AA. Djeghmoum")
                            .show();
                        secretCount = 0;
                      }
                    },
                    child: Image.asset(
                      "assets/logo.png",
                      width: 100,
                      height: 100,
                    ),
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
                  mainBlueLoadingBtn(context, _btnController, "Se connecter",
                      () async {
                    if (_formKey.currentState.validate()) {
                      _btnController.start();
                      dynamic loginStatus = await FirebaseAuthService.signIn(
                          _emailController.text, _passwordController.text);
                      if (loginStatus is User) {
                        Alert(message: "Connecté").show();
                        _btnController.success();
                      } else if (loginStatus == AuthCodes.accountNotFound) {
                        Alert(message: "Compte non existant").show();
                        _btnController.stop();
                      } else if (loginStatus == AuthCodes.badPassword) {
                        Alert(message: "Mot de passe invalide").show();
                        _btnController.stop();
                      } else {
                        Alert(message: "Erreur").show();
                        _btnController.stop();
                      }
                    }
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      textButton(
                          context,
                          "Créer un compte",
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Register()))),
                      SizedBox(
                        width: 5,
                      ),
                      textButton(context, "Mot de passe oublié ? ", () {
                        showSlideDialog(
                            context: context, child: ResetPasswordComponent());
                      })
                    ],
                  )
                ],
              ),
            )));
  }
}
