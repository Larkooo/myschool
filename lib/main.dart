import 'dart:io';

import 'package:alert/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:myschool/pages/welcome.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/services/messaging.dart';
import 'package:myschool/shared/constants.dart';
import 'package:network_logger/network_logger.dart';
//import 'components/login.dart';
import 'package:provider/provider.dart';
import 'package:device_info/device_info.dart';

void main() async {
  await initializeDateFormatting('fr', null);
  Intl.defaultLocale = 'fr';
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  String hwid = await FirebaseMessaging().getToken();
  if (await DatabaseService(uid: hwid).HWIDBanned()) {
    Alert(
            message:
                'Your device has been HWID locked from MySchool. Closing the app...')
        .show();
    await Future.delayed(Duration(seconds: 2));
    exit(-1);
  }
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
