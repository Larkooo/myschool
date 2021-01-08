import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/resetPassword.dart';
import 'package:myschool/components/resetPasswordNext.dart';

class ResetPasswordWrapper extends StatefulWidget {
  @override
  _ResetPasswordWrapperState createState() => _ResetPasswordWrapperState();
}

class _ResetPasswordWrapperState extends State<ResetPasswordWrapper> {
  bool emailSent = false;

  void toggleView() {
    setState(() {
      emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!emailSent) {
      return ResetPasswordComponent(toggleView: toggleView);
    } else {
      return ResetPasswordNextComponent();
    }
  }
}
