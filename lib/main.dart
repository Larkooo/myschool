import 'dart:io';

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
import 'package:network_logger/network_logger.dart';
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
        theme: ThemeData.dark(),
        home: Welcome(),
      ),
    );
  }
}

class MessageHandler extends StatefulWidget {
  MessageHandler({Key key}) : super(key: key);

  @override
  _MessageHandlerState createState() => _MessageHandlerState();
}

class _MessageHandlerState extends State<MessageHandler> {
  final FirebaseFirestore _database = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  _saveDeviceToken() async {
    DocumentReference tokenRef = _database
        .collection('users')
        .doc(_auth.currentUser.uid)
        .collection('tokens')
        .doc(await _messaging.getToken());
    await tokenRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem
    });
  }

  // TODO : Implement notifications
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Platform.isIOS) {
      _messaging.onIosSettingsRegistered.listen((event) {
        _saveDeviceToken();
      });
      _messaging.requestNotificationPermissions(IosNotificationSettings());
    } else {
      _saveDeviceToken();
    }
    _messaging.configure(
      onMessage: (message) {},
      onResume: (message) {},
      onLaunch: (message) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return null;
  }
}
