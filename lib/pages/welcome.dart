import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/login.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/home_skeleton.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:provider/provider.dart';

class Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return user != null ? HomeSkeleton() : Login();
  }
}
