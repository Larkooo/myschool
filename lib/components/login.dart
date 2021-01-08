import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
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

  TextEditingController _resetPasswordEmailController = TextEditingController();

  final RoundedLoadingButtonController _resetPasswordBtnController =
      new RoundedLoadingButtonController();

  final _passwordFormKey = GlobalKey<FormState>();

  String confirmMessage = "";

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  final _formKey = GlobalKey<FormState>();

  bool resizeToAvoidBottom = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        if (visible && !resizeToAvoidBottom) {
          setState(() {
            resizeToAvoidBottom = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottom,
        body: Form(
            key: _passwordFormKey,
            child: Center(
                child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/logo.png",
                    width: 100,
                    height: 100,
                  ),
                  Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: TextFormField(
                        controller: _resetPasswordEmailController,
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
                  mainBlueLoadingBtn(context, _resetPasswordBtnController,
                      Text("Se connecter"), () async {
                    if (_formKey.currentState.validate()) {
                      _resetPasswordBtnController.start();
                      dynamic loginStatus = await FirebaseAuthService.signIn(
                          _resetPasswordEmailController.text,
                          _passwordController.text);
                      if (loginStatus is User) {
                        Alert(message: "Connecté").show();
                        _resetPasswordBtnController.success();
                      } else if (loginStatus == AuthCodes.accountNotFound) {
                        Alert(message: "Compte non existant").show();
                        _resetPasswordBtnController.stop();
                      } else if (loginStatus == AuthCodes.badPassword) {
                        Alert(message: "Mot de passe invalide").show();
                        _resetPasswordBtnController.stop();
                      } else {
                        Alert(message: "Erreur").show();
                        _resetPasswordBtnController.stop();
                      }
                    }
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Register())),
                          style: ButtonStyle(
                            overlayColor: MaterialStateColor.resolveWith(
                                (states) => Colors.transparent),
                          ),
                          child: Text("Créer un compte",
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.blue[200] : Colors.black,
                                  fontSize: 13))),
                      SizedBox(
                        width: 5,
                      ),
                      TextButton(
                          onPressed: () {
                            showSlideDialog(
                                context: context,
                                child: ResetPasswordComponent());
                            setState(() {
                              resizeToAvoidBottom = false;
                            });
                          },
                          style: ButtonStyle(
                            overlayColor: MaterialStateColor.resolveWith(
                                (states) => Colors.transparent),
                          ),
                          child: Text("Mot de passe oublié ?",
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.blue[200] : Colors.black,
                                  fontSize: 13)))
                    ],
                  )
                ],
              ),
            ))));
  }
}
