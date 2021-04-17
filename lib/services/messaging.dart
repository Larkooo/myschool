import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/constants.dart';

class MessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final String _apiUrl =
      'https://us-central1-cool-framing-281906.cloudfunctions.net/send_notification_topic';

  static Future<bool> sendMessageToTopic(
      String title, String body, String topic, String type,
      {String icon, Map data}) async {
    Map requestBody = {
      'notificationTitle': title,
      'notificationBody': body,
      'topic': topic,
      'type': type,
    };
    if (icon != null) requestBody['notificationIcon'] = icon;
    if (data != null) requestBody['data'] = data;

    try {
      await http.post(Uri.tryParse(_apiUrl),
          headers: {'Authorization': await _auth.currentUser.getIdToken()},
          body: requestBody);
      return true;
    } catch (err) {
      print(err);
      return false;
    }
  }

  static void unsubscribeFromTopics(UserData user) {
    // unsubscribe from user topics
    FirebaseMessaging fcm = FirebaseMessaging.instance;
    fcm.unsubscribeFromTopic(user.school.uid);
    if (user.type == UserType.student) {
      fcm.unsubscribeFromTopic(user.school.uid + '-' + user.school.group.uid);
    } else {
      user.groups.forEach((group) {
        fcm.unsubscribeFromTopic(user.school.uid + '-' + group);
      });
    }
  }
}
