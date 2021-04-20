import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:alert/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:myschool/pages/welcome.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/services/messaging.dart';
import 'package:myschool/shared/constants.dart';
//import 'components/login.dart';
import 'package:provider/provider.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void main() async {
  await initializeDateFormatting('fr', null);
  Intl.defaultLocale = 'fr';
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // Required to display a heads up notification
    badge: true,
    sound: true,
  );
  String hwid = await FirebaseMessaging.instance.getToken();
  if (await DatabaseService(uid: hwid).HWIDBanned()) {
    Alert(
            message:
                'Your device has been HWID locked from MySchool. Closing the app...')
        .show();
    await Future.delayed(Duration(seconds: 2));
    exit(-1);
  }

  //RemoteConfig remoteConfig = RemoteConfig.instance;
  //PackageInfo packageInfo = await PackageInfo.fromPlatform();

  //remoteConfig.setDefaults({'latest_version': packageInfo.version});

  //await remoteConfig.fetch();

  //String latestVersion = remoteConfig.getString('latest_version');

  //if (packageInfo.version != latestVersion) {
  //  Alert(
  //          message:
  //              'Version invalide. Votre version ne correspond pas à la dernière version de MonÉcole. Veillez s\'il vous plait mettre à jour l\'application')
  //      .show();
  //  await Future.delayed(Duration(seconds: 3));
  //  exit(-1);
  //}

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.grey[850], // navigation bar color
      // statusBarColor: Colors.grey[850], // status bar color
    ));

    return StreamProvider<User>.value(
      initialData: null,
      value: FirebaseAuthService.user,
      child: MaterialApp(
        title: 'MonEcole',
        theme: ThemeData.light().copyWith(
          primaryColor: Colors.grey[850],
          colorScheme: ColorScheme(
              brightness: Brightness.light,
              primary: Colors.blue,
              primaryVariant: Colors.black,
              secondary: Colors.black,
              secondaryVariant: Colors.black,
              background: Colors.black,
              surface: Colors.grey[600], // bottom bar icons
              onBackground: Colors.black,
              onSurface: Colors.black,
              onError: Colors.black,
              onPrimary: Colors.black,
              onSecondary: Colors.black,
              error: Colors.red.shade400),
          cardColor: Colors.grey[300],
        ),
        darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.grey[900],
            backgroundColor: Colors.black,
            cardColor: Colors.grey[900],
            colorScheme: ColorScheme(
                brightness: Brightness.dark,
                primary: Colors.blue,
                primaryVariant: Colors.black,
                secondary: Colors.black,
                secondaryVariant: Colors.black,
                background: Colors.black,
                surface: Colors.grey[700],
                onBackground: Colors.black,
                onSurface: Colors.black,
                onError: Colors.white,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                error: Colors.red.shade400)),
        themeMode: ThemeMode.system,
        home: Welcome(),
      ),
    );
  }
}
