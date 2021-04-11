import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:myschool/pages/login.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/home_skeleton.dart';
import 'package:myschool/services/firebase_auth_service.dart';
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
    super.initState();
    if (Platform.isIOS) {
      _messaging.requestPermission().then((value) async {
        if (value.authorizationStatus == AuthorizationStatus.authorized)
          _saveDeviceToken();
      });
    } else {
      _saveDeviceToken();
    }
    FirebaseMessaging.onMessage.listen((message) {
      print('yes');
      if (message.notification != null) {
        final snackbar = SnackBar(
            content: Text(message.notification.title),
            action: SnackBarAction(
              label: 'Fermer',
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ));
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSkeleton();
  }
}
