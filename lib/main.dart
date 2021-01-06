import 'package:flutter/material.dart';
import 'package:myschool/pages/welcome.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

bool isDark = true;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonEcole',
      theme: ThemeData.dark(),
      home: Welcome(),
    );
  }
}
