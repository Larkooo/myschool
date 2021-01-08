import 'package:alert/alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //showSlideDialog(context: context, child: Text("Testing welcome message"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FlatButton(
          child: Text("sign out"),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Alert(message: "Déconnecté").show();
          },
        ),
      ),
    );
  }
}
