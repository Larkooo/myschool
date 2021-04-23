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
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/constants.dart';

void main() async {
  await initializeDateFormatting('fr', null);
  Intl.defaultLocale = 'fr';
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  /* String hwid = await FirebaseMessaging.instance.getToken();
  if (await DatabaseService(uid: hwid).HWIDBanned()) {
    Alert(
            message:
                'Your device has been HWID locked from MySchool. Closing the app...')
        .show();
    await Future.delayed(Duration(seconds: 2));
    exit(-1);
  }*/
  if (prefs.getBool('darkMode') != null)
    themeNotifier.value =
        prefs.getBool('darkMode') ? ThemeMode.dark : ThemeMode.light;

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
    /*SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: themeNotifier.value == ThemeMode.dark
            ? Colors.grey[850]
            : Colors.white, // navigation bar color
        systemNavigationBarIconBrightness: Brightness.dark
        // statusBarColor: Colors.grey[850], // status bar color
        ));
    //
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);*/

    return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) => StreamProvider<User>.value(
              initialData: null,
              value: FirebaseAuthService.user,
              child: MaterialApp(
                title: 'MonEcole',
                /////////////////////////// LIGHT THEME ///////////////////////////
                theme: ThemeData.light().copyWith(
                  snackBarTheme: SnackBarThemeData(
                      backgroundColor: Colors.grey[900],
                      actionTextColor: Colors.white,
                      contentTextStyle: TextStyle(color: Colors.white)),
                  appBarTheme: AppBarTheme(
                      textTheme: TextTheme(
                          headline6:
                              TextStyle(color: Colors.grey[800], fontSize: 20)),
                      elevation: 5,
                      backgroundColor: Colors.grey[100],
                      iconTheme: IconThemeData(color: Colors.grey[900])),
                  bottomNavigationBarTheme: BottomNavigationBarThemeData(
                      showSelectedLabels: true,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      selectedIconTheme:
                          IconThemeData(color: Colors.grey[800], size: 30),
                      unselectedIconTheme:
                          IconThemeData(color: Colors.grey[500], size: 20)),
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
                /////////////////////////// DARK THEME ///////////////////////////
                darkTheme: ThemeData.dark().copyWith(
                    snackBarTheme: SnackBarThemeData(
                        backgroundColor: Colors.white,
                        actionTextColor: Colors.grey[900],
                        contentTextStyle: TextStyle(color: Colors.grey[900])),
                    primaryColor: Colors.grey[900],
                    backgroundColor: Colors.black,
                    cardColor: Colors.grey[900],
                    cupertinoOverrideTheme: const CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(), // This is required
                    ),
                    //splashColor: Colors.grey[800],
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
                themeMode: mode,
                home: Welcome(),
              ),
            ));
  }
}
