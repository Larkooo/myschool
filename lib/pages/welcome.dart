import 'package:flutter/material.dart';
import '../components/login.dart';

class Welcome extends StatefulWidget {
  Welcome({Key key}) : super(key: key);

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            // decoration: BoxDecoration(color: Colors.grey[900]),
            child: Login()));
  }
}
