import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:myschool/components/login.dart';
import 'package:myschool/pages/home.dart';
import 'package:myschool/services/firebase.dart';
import 'package:password_validator/password_validator.dart';

import '../main.dart';
import 'alert.dart';

class Register extends StatelessWidget {
  Register({
    Key key,
  }) : super(key: key);

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _codeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/logo.png",
            width: 100,
            height: 100,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: MediaQuery.of(context).size.width / 2.65,
                  child: TextFormField(
                    controller: _firstNameController,
                    validator: (value) {
                      if (value.isEmpty) return 'Ce champs est obligatoire.';
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
                  width: MediaQuery.of(context).size.width / 2.65,
                  child: TextFormField(
                    controller: _lastNameController,
                    validator: (value) {
                      if (value.isEmpty) return 'Ce champs est obligatoire.';
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
                  if (value.isEmpty) return 'Ce champs est obligatoire.';
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
                  if (value.isEmpty) return 'Ce champs est obligatoire.';
                  bool v = PasswordValidator(min: 6, max: 30).validate(value);
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
                  if (value.isEmpty) return 'Ce champs est obligatoire.';
                  if (value.length < 6) {
                    return "Code invalide.";
                  }
                  return null;
                },
                obscureText: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Code d\'école',
                ),
              )),
          SizedBox(
            height: 10,
          ),
          Container(
              width: MediaQuery.of(context).size.width / 2.2,
              height: 50,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), color: Colors.blue),
              child: MaterialButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    AuthCodes registerStatus = await register(
                        _firstNameController.text,
                        _lastNameController.text,
                        _emailController.text,
                        _passwordController.text,
                        _codeController.text);
                    if (registerStatus == AuthCodes.ok) {
                      Alert(message: "Compte crée").show();
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Home()));
                    } else if (registerStatus == AuthCodes.emailAlreadyUsed) {
                      Alert(
                              message:
                                  "Un compte avec cette adresse email existe déjà")
                          .show();
                    } else if (registerStatus == AuthCodes.codeNotFound) {
                      Alert(message: "Code inexistant").show();
                    } else {
                      Alert(message: "Erreur").show();
                    }
                  }
                },
                child: Text(
                  "Créer un compte",
                  style: TextStyle(color: Colors.white),
                ),
              )),
          TextButton(
              onPressed: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => Login())),
              style: ButtonStyle(
                overlayColor: MaterialStateColor.resolveWith(
                    (states) => Colors.transparent),
              ),
              child: Text("Se connecter",
                  style: TextStyle(
                      color: isDark ? Colors.blue[200] : Colors.black,
                      fontSize: 13))),
        ],
      ),
    ));
  }
}
