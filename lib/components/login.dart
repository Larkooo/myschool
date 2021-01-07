import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:myschool/components/register.dart';
import 'package:myschool/pages/home.dart';
import 'package:myschool/services/firebase.dart';
import 'package:password_validator/password_validator.dart';
import 'alert.dart';

import '../main.dart';

class Login extends StatelessWidget {
  Login({
    Key key,
  }) : super(key: key);

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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
              width: MediaQuery.of(context).size.width / 2.2,
              height: 50,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), color: Colors.blue),
              child: MaterialButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    AuthCodes loginStatus = await signIn(
                        _emailController.text, _passwordController.text);
                    if (loginStatus == AuthCodes.ok) {
                      Alert(message: "Connecté").show();
                      print(FirebaseAuth.instance.currentUser.email);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Home()));
                    } else if (loginStatus == AuthCodes.accountNotFound) {
                      Alert(message: "Compte non existant").show();
                    } else if (loginStatus == AuthCodes.badPassword) {
                      Alert(message: "Mot de passe invalide").show();
                    } else {
                      Alert(message: "Erreur").show();
                    }
                  }
                },
                child: Text(
                  "Se connecter",
                  style: TextStyle(color: Colors.white),
                ),
              )),
          TextButton(
              onPressed: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => Register())),
              style: ButtonStyle(
                overlayColor: MaterialStateColor.resolveWith(
                    (states) => Colors.transparent),
              ),
              child: Text("Créer un compte",
                  style: TextStyle(
                      color: isDark ? Colors.blue[200] : Colors.black,
                      fontSize: 13))),
        ],
      ),
    ));
  }
}