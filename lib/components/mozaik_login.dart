import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myschool/models/mozaik.dart';
import 'package:myschool/services/mozaik_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

class MozaikLogin extends StatefulWidget {
  MozaikLogin({Key key}) : super(key: key);

  @override
  _MozaikLoginState createState() => _MozaikLoginState();
}

class _MozaikLoginState extends State<MozaikLogin> {
  final String _loginUrl =
      "https://acces.mozaikportail.ca/connect/authorize?client_id=mozaikportail&redirect_uri=https%3A%2F%2Fmozaikportail.ca%2F&response_type=id_token%20token&scope=openid&state=${DateTime.now().millisecondsSinceEpoch.toString()}&ui_locales=fr&nonce=${DateTime.now().millisecondsSinceEpoch.toString()}&acr_values=idp%3Aactivedirectory";

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Connexion à Mozaik'),
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: Uri.parse(_loginUrl)),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
          ),
          onWebViewCreated: Platform.isIOS
              // ios workaround
              ? (controller) async {
                  Future.doWhile(() async {
                    await Future.delayed(Duration(seconds: 1));
                    print('bop');
                    try {
                      Map<String, dynamic> tokens = await controller
                          .webStorage.localStorage
                          .getItem(key: 'jeton_mozaikportail_activedirectory');

                      Mozaik.idToken = tokens['id_token'];
                      Mozaik.payload = Jwt.parseJwt(Mozaik.idToken);

                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.setString(
                          'mozaikUserData', jsonEncode(Mozaik.payload));
                      // user logged in at least one time
                      prefs.setBool('mozaikLoyal', true);
                      if (Mozaik.idToken.isNotEmpty) Navigator.pop(context);

                      return Mozaik.idToken.isEmpty;
                    } catch (err) {
                      if (err is MissingPluginException) return false;
                      return true;
                    }
                  });
                }
              : null,
          onLoadStart: (controller, url) async {
            String urlString = url.toString();
            if (urlString.contains('#id_token') && Platform.isAndroid) {
              url = Uri.parse(urlString.replaceFirst('#', '?'));

              if (url.queryParameters['id_token'].length < 2) {
                Mozaik.idToken = null;
                return null;
              }

              Mozaik.idToken = url.queryParameters['id_token'];
              Mozaik.payload = Jwt.parseJwt(Mozaik.idToken);

              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('mozaikUserData', jsonEncode(Mozaik.payload));
              // user logged in at least one time
              prefs.setBool('mozaikLoyal', true);

              Navigator.pop(context);
            }
          },
        ));
  }
}
