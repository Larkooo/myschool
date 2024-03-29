import 'package:alert/alert.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class ResetPasswordComponent extends StatefulWidget {
  @override
  _ResetPasswordComponentState createState() => _ResetPasswordComponentState();
}

class _ResetPasswordComponentState extends State<ResetPasswordComponent> {
  TextEditingController _emailController = TextEditingController();

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  final _formKey = GlobalKey<FormState>();

  String _confirmMessage = "";
  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 35),
              Text(
                'Vous avez oublié votre mot de passe?',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 35),
              Container(
                  width: MediaQuery.of(context).size.width / 1.3,
                  child: TextFormField(
                    controller: _emailController,
                    validator: (value) {
                      if (value.isEmpty) return 'Ce champ est obligatoire.';
                      bool v = EmailValidator.validate(value);
                      if (!v) {
                        return "Adresse courriel invalide.";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Courriel',
                      hintText: "exemple@domain.com",
                    ),
                  )),
              SizedBox(
                height: 35,
              ),
              mainBlueLoadingBtn(context, _btnController, "Envoyer", () async {
                if (_formKey.currentState.validate()) {
                  _btnController.start();
                  bool emailSent = await FirebaseAuthService.resetPassword(
                      _emailController.text);
                  if (emailSent) {
                    _btnController.success();
                    setState(() {
                      _confirmMessage =
                          "Un courriel pour réinitialiser votre mot de passe vous a été envoyé.";
                    });
                    //widget.toggleView();
                  } else {
                    _btnController.stop();
                    Alert(message: "Une erreur est survenue!").show();
                  }
                }
              }),
              Text(
                _confirmMessage,
                style: TextStyle(color: Colors.green, fontSize: 13),
              )
            ],
          ),
        ));
  }
}
