import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myschool/models/mozaik.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

class MozaikLogin extends StatefulWidget {
  MozaikLogin({Key key}) : super(key: key);

  @override
  _MozaikLoginState createState() => _MozaikLoginState();
}

class _MozaikLoginState extends State<MozaikLogin> {
  final String _url = 'https://acces.mozaikportail.ca/connect/authorize' +
      '?client_id=' +
      "mozaikportail" +
      '&redirect_uri=' +
      "https%3A%2F%2Fmozaikportail.ca%2F" +
      '&response_type=' +
      "id_token%20token" +
      '&scope=openid' +
      '&state=' +
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextDouble().toString() +
      '&ui_locales=' +
      "fr" +
      '&nonce=' +
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextDouble().toString() +
      '&acrvalues=' +
      "idp%3Aactivedirectory";

  /* @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
  } */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [],
        ),
        body: InAppWebView(
          initialUrl: _url,
          androidShouldInterceptRequest: (controller, request) {
            if (request.headers.isNotEmpty) {
              request.headers.forEach((key, value) async {
                if (key == 'Authorization' && value.startsWith('Bearer')) {
                  Future.delayed(Duration(seconds: 3), () async {
                    Navigator.pop(context);
                    Map<String, dynamic> tokens = await controller
                        .webStorage.localStorage
                        .getItem(key: "jeton_mozaikportail_activedirectory");
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();

                    prefs.setString('access_token', tokens['access_token_ad']);
                    prefs.setInt(
                        'access_token_exp', tokens['access_token_ad_exp']);
                    prefs.setString('id_token', tokens['id_token']);

                    Mozaik.accessToken = tokens['access_token_ad'];
                    Mozaik.accessTokenExp = tokens['access_token_ad_exp'];
                    Mozaik.idToken = tokens['id_token'];

                    Mozaik.payload = Jwt.parseJwt(tokens['id_token']);
                  });
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
