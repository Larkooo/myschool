import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myschool/pages/welcome.dart';
import 'package:myschool/services/firebase.dart';
//import 'components/login.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

bool isDark = true;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<User>.value(
      value: FirebaseAuthService.user,
      child: MaterialApp(
        title: 'MonEcole',
        theme: ThemeData.dark(),
        home: Welcome(),
      ),
    );
  }
}
