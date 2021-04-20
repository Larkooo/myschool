import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<bool> subscribeToSchool(String uid) async {
    try {
      _messaging.subscribeToTopic(uid);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('schoolNotifications', true);
      return true;
    } catch (err) {
      return false;
    }
  }

  static Future<List<String>> subscribeToGroup(
      String schoolUid, String groupUid) async {
    try {
      _messaging.subscribeToTopic(schoolUid + '-' + groupUid);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> disabledGroupsNotifications =
          prefs.getStringList('disabledGroupsNotifications') ?? [];
      disabledGroupsNotifications.remove(groupUid);
      prefs.setStringList(
          'disabledGroupsNotifications', disabledGroupsNotifications);
      return disabledGroupsNotifications;
    } catch (err) {
      return null;
    }
  }

  static Future<List<String>> subscribeToGroups(
      String schoolUid, List<String> groups) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> disabledGroupsNotifications =
          prefs.getStringList('disabledGroupsNotifications') ?? [];
      groups.forEach((group) {
        _messaging.subscribeToTopic(schoolUid + '-' + group);
        disabledGroupsNotifications.remove(group);
      });
      prefs.setStringList(
          'disabledGroupsNotifications', disabledGroupsNotifications);
      return disabledGroupsNotifications;
    } catch (err) {
      return null;
    }
  }

  static Future<bool> unsubscribeFromSchool(String uid) async {
    try {
      _messaging.unsubscribeFromTopic(uid);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('schoolNotifications', false);
      return true;
    } catch (err) {
      return false;
    }
  }

  static Future<List<String>> unsubscribeFromGroup(
      String schoolUid, String groupUid) async {
    try {
      _messaging.unsubscribeFromTopic(schoolUid + '-' + groupUid);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> disabledGroupsNotifications =
          prefs.getStringList('disabledGroupsNotifications') ?? [];
      disabledGroupsNotifications.add(groupUid);
      prefs.setStringList(
          'disabledGroupsNotifications', disabledGroupsNotifications);
      return disabledGroupsNotifications;
    } catch (err) {
      return null;
    }
  }

  static Future<List<String>> unsubscribeFromGroups(
      String schoolUid, List<String> groups) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> disabledGroupsNotifications =
          prefs.getStringList('disabledGroupsNotifications') ?? [];
      groups.forEach((group) {
        _messaging.unsubscribeFromTopic(schoolUid + '-' + group);
        disabledGroupsNotifications.add(group);
      });
      prefs.setStringList(
          'disabledGroupsNotifications', disabledGroupsNotifications);
      return disabledGroupsNotifications;
    } catch (err) {
      return null;
    }
  }

  static void unsubscribeFromTopics(UserData user) {
    // unsubscribe from user topics
    _messaging.unsubscribeFromTopic(user.school.uid);
    if (user.type == UserType.student) {
      _messaging
          .unsubscribeFromTopic(user.school.uid + '-' + user.school.group.uid);
    } else {
      user.groups.forEach((group) {
        _messaging.unsubscribeFromTopic(user.school.uid + '-' + group);
      });
    }
  }
}
