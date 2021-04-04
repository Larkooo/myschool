import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class MessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final String _apiUrl =
      'https://us-central1-cool-framing-281906.cloudfunctions.net/send_notification_topic';

  static Future<bool> sendMessageToTopic(
      String title, String body, String topic, String type,
      {String icon}) async {
    Map requestBody = {
      'notificationTitle': title,
      'notificationBody': body,
      'topic': topic,
      'type': type
    };
    if (icon != null) requestBody['notificationIcon'] = icon;

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
}
