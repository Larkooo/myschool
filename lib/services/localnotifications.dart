import 'dart:convert';

import 'package:myschool/pages/home_skeleton.dart';
import 'package:myschool/shared/navbarprovider.dart';

class LocalNotificationsService {
  static Future<dynamic> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    return true;
  }

  static Future<dynamic> onSelectNotification(String payload) async {
    try {
      Map decodedPayload = jsonDecode(payload);
      switch (decodedPayload['type']) {
        case 'announce':
          {
            //NavigationBarProvider.provider.currentIndex = 2;
            return;
          }
        case 'homework':
          {
            return;
          }
      }
      return true;
    } catch (err) {
      print(err);
      return false;
    }
  }
}
