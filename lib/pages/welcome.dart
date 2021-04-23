import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myschool/pages/login.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/home_skeleton.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/services/localnotifications.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';

class Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    // MessageHandler -> handles messages -> homeskeleton
    return user != null ? MessageHandler() : Login();
  }
}

class MessageHandler extends StatefulWidget {
  MessageHandler({Key key}) : super(key: key);

  @override
  _MessageHandlerState createState() => _MessageHandlerState();
}

class _MessageHandlerState extends State<MessageHandler> {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  _saveDeviceToken() async {
    String token = await _messaging.getToken();
    bool exists = (await _database
            .collection('users')
            .doc(_auth.currentUser.uid)
            .collection('tokens')
            .doc(token)
            .get())
        .exists;
    if (token != null && !exists) {
      DocumentReference tokenRef = _database
          .collection('users')
          .doc(_auth.currentUser.uid)
          .collection('tokens')
          .doc(token);
      await tokenRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem
      });
    }
  }

  // TODO : Implement notifications
  @override
  void initState() {
    // TODO: implement initState
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    super.initState();
    _messaging.requestPermission().then((value) async {
      if (value.authorizationStatus == AuthorizationStatus.authorized ||
          value.authorizationStatus == AuthorizationStatus.provisional) {
        _saveDeviceToken();
      }
    });

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('logo');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) =>
          LocalNotificationsService.onDidReceiveLocalNotification(
              id, title, body, payload),
    );
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (payload) =>
          LocalNotificationsService.onSelectNotification(payload),
    );

    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        if (message.data['authorUid'] == _auth.currentUser.uid) return;
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
                'notification', 'notification', 'notification',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: false);
        flutterLocalNotificationsPlugin.show(
            1,
            message.notification.title,
            message.notification.body,
            NotificationDetails(android: androidPlatformChannelSpecifics),
            payload: jsonEncode(message.data));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSkeleton();
  }
}
