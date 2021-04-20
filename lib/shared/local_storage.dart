import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<bool> clearSensitiveInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // delete keys that contain user info in shared prefs
      await prefs.remove('mozaikTimetable');
      await prefs.remove('mozaikUserData');
      await prefs.remove('mozaikLoyal');
      return true;
    } catch (err) {
      return false;
    }
  }

  static Future<String> getGroupAlias(String group) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('group${group}Alias');
  }

  static Future<bool> setGroupAlias(String group, String alias) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (await prefs.setString('group${group}Alias', alias)) {
      CacheManagerMemory.groupData[group][GroupAttribute.alias] = alias;
      return true;
    } else {
      return false;
    }
  }

  static Future<File> getGroupImage(String group) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String path = prefs.getString('group${group}Image');
    // security
    return path != null ? File(path) : null;
  }

  static Future<bool> setGroupImage(String group, File image) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (await prefs.setString('group${group}Image', image.path)) {
      CacheManagerMemory.groupData[group][GroupAttribute.image] = image;
      return true;
    } else {
      return false;
    }
  }
}
