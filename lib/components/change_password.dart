import 'package:alert/alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:provider/provider.dart';

class ChangePassword extends StatefulWidget {
  ChangePassword({Key key}) : super(key: key);

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  TextEditingController _actualPassword = TextEditingController();
  TextEditingController _newPassword = TextEditingController();

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            "Modifier votre mot de passe",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(
            height: 25,
          ),
          Container(
              width: MediaQuery.of(context).size.width / 1.3,
              child: TextFormField(
                controller: _newPassword,
                validator: (value) {
                  if (value.isEmpty) return 'Ce champs est obligatoire.';
                  if (value.length < 6) return 'Mot de passe incorrect.';
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mot de passe actuel',
                ),
              )),
          SizedBox(
            height: 12,
          ),
          Container(
              width: MediaQuery.of(context).size.width / 1.3,
              child: TextFormField(
                controller: _actualPassword,
                validator: (value) {
                  if (value.isEmpty) return 'Ce champs est obligatoire.';
                  if (value.length < 6) return 'Mot de passe trop court.';
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nouveau mot de passe',
                ),
              )),
          SizedBox(
            height: 16,
          ),
          mainBlueLoadingBtn(context, _btnController, "Confirmer", () async {
            if (_formKey.currentState.validate()) {
              _btnController.start();
              AuthCredential credential = EmailAuthProvider.credential(
                  email: user.email, password: _actualPassword.text);
              try {
                await FirebaseAuth.instance.currentUser
                    .reauthenticateWithCredential(credential);
                await user.updatePassword(_newPassword.text);
                _btnController.success();
                Alert(message: "Mot de passe modifié").show();
              } catch (e) {
                print(e);
                _btnController.stop();
                Alert(message: "Mot de passe incorrect").show();
              }
            }
          })
        ],
      ),
    );
  }
}