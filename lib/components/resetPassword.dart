import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:myschool/services/firebase.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class ResetPasswordComponent extends StatefulWidget {
  final Function toggleView;
  ResetPasswordComponent({this.toggleView});

  @override
  _ResetPasswordComponentState createState() => _ResetPasswordComponentState();
}

class _ResetPasswordComponentState extends State<ResetPasswordComponent> {
  TextEditingController _emailController = TextEditingController();

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  final _formKey = GlobalKey<FormState>();

  String confirmMessage = "";

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
                  mainBlueLoadingBtn(context, _btnController, Text("Envoyer"),
                      () async {
                    if (_formKey.currentState.validate()) {
                      _btnController.start();
                      bool emailSent = await FirebaseAuthService.resetPassword(
                          _emailController.text);
                      if (emailSent) {
                        _btnController.success();
                        setState(() {
                          confirmMessage =
                              "Un courriel pour réinitialiser votre mot de passe vous a été envoyé";
                        });
                        //widget.toggleView();
                      }
                    }
                  }),
                  Text(
                    confirmMessage,
                    style: TextStyle(color: Colors.green, fontSize: 13),
                  )
                ],
              ),
            )));
  }
}
