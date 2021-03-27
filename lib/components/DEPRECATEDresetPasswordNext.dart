import 'package:alert/alert.dart';
import 'package:flutter/material.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class ResetPasswordNextComponent extends StatefulWidget {
  @override
  _ResetPasswordNextComponentState createState() =>
      _ResetPasswordNextComponentState();
}

class _ResetPasswordNextComponentState
    extends State<ResetPasswordNextComponent> {
  TextEditingController _codeController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _repeatPasswordController = TextEditingController();

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Form(
            key: _formKey,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: TextFormField(
                        controller: _codeController,
                        validator: (value) {
                          if (value.isEmpty)
                            return 'Ce champs est obligatoire.';
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Code',
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
                          return null;
                        },
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
                          if (value != _passwordController.text) {
                            return 'Les mot de passes ne correspondent pas.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Répétez le mot de passe',
                        ),
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  mainBlueLoadingBtn(context, _btnController, "Envoyer",
                      () async {
                    if (_formKey.currentState.validate()) {
                      _btnController.start();
                      AuthCode valid =
                          await FirebaseAuthService.checkResetPasswordCode(
                              _codeController.text, _passwordController.text);
                      switch (valid) {
                        case AuthCode.ok:
                          _btnController.success();
                          Alert(message: "Mot de passe modifié").show();
                          await Future.delayed(const Duration(seconds: 2),
                              () => Navigator.pop(context));
                          break;
                        case AuthCode.passwordResetCodeExpired:
                          _btnController.error();
                          Alert(message: "Code expiré").show();
                          await Future.delayed(const Duration(seconds: 2),
                              () => Navigator.pop(context));
                          break;
                        case AuthCode.passwordResetCodeInvalid:
                          _btnController.error();
                          Alert(message: "Code invalide").show();
                          await Future.delayed(const Duration(seconds: 2),
                              () => Navigator.pop(context));
                          break;
                        case AuthCode.accountDisabled:
                          _btnController.error();
                          Alert(message: "Ce compte est désactivé").show();
                          await Future.delayed(const Duration(seconds: 2),
                              () => Navigator.pop(context));
                          break;
                        case AuthCode.accountNotFound:
                          _btnController.error();
                          Alert(message: "Compte introuvable").show();
                          await Future.delayed(const Duration(seconds: 2),
                              () => Navigator.pop(context));
                          break;
                        default:
                          _btnController.error();
                          Alert(message: "Erreur").show();
                          await Future.delayed(const Duration(seconds: 2),
                              () => Navigator.pop(context));
                          break;
                      }
                    }
                  }),
                ],
              ),
            )));
  }
}
