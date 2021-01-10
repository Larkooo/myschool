import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:myschool/pages/welcome.dart';
import 'package:myschool/services/firebase_auth_service.dart';
//import 'components/login.dart';
import 'package:provider/provider.dart';

void main() async {
  await initializeDateFormatting('fr', null);
  Intl.defaultLocale = 'fr';
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
        theme: ThemeData.dark().copyWith(
            primaryColor: Colors.indigo[400],
            accentColor: Colors.lightBlue[400]),
        home: Welcome(),
      ),
    );
  }
}
