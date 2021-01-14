import 'dart:io';
import 'dart:math';

import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MozaikLogin extends StatefulWidget {
  MozaikLogin({Key key}) : super(key: key);

  @override
  _MozaikLoginState createState() => _MozaikLoginState();
}

class _MozaikLoginState extends State<MozaikLogin> {
  //final String url = 'https://acces.mozaikportail.ca/connect/authorize' +
  //    '?client_id=' +
  //    "mozaikportail" +
  //    '&redirect_uri=' +
  //    "https%3A%2F%2Fmozaikportail.ca%2F" +
  //    '&response_type=' +
  //    "id_token%2token" +
  //    '&scope=openid' +
  //    '&state=' +
  //    DateTime.now().millisecondsSinceEpoch.toString() +
  //    Random().nextDouble().toString() +
  //    '&ui_locales=' +
  //    "fr" +
  //    '&nonce=' +
  //    DateTime.now().millisecondsSinceEpoch.toString() +
  //    Random().nextDouble().toString();

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [],
        ),
        body: InAppWebView(
          initialUrl: "https://mozaikportail.ca",
          androidShouldInterceptRequest: (controller, request) {
            if (request.headers.isNotEmpty) {
              request.headers.forEach((key, value) async {
                if (key == 'Authorization' && value.startsWith('Bearer')) {
                  //print(value);
                  //print(value.replaceFirst("Bearer ", ""));
                  Navigator.pop(context);
                  Map<String, dynamic> tokens = await controller
                      .webStorage.localStorage
                      .getItem(key: "jeton_mozaikportail_activedirectory");

                  //(await controller.webStorage.localStorage.getItems())
                  //    .forEach((element) {
                  //  print(element);
                  //});
                  UserCredential mozaikUser = await FirebaseAuth.instance
                      .signInWithCredential(OAuthCredential(
                          providerId: "microsoft.com",
                          accessToken: tokens["access_token_ad"],
                          idToken: tokens["id_token"],
                          signInMethod: "password"));
                  print(mozaikUser.user);
                }
              });
            }
          },
          initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true, useShouldInterceptAjaxRequest: true),
              android: AndroidInAppWebViewOptions(
                useShouldInterceptRequest: true,
              )),
        ));
  }
}
