import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/pages/home.dart';
import 'package:provider/provider.dart';
import '../components/login.dart';

class Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return user != null ? Home() : Login();
  }
}
