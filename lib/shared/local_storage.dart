import 'dart:io';

import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<String> getGroupAlias(String group) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('group${group}Alias');
  }

  static Future<bool> setGroupAlias(String group, String alias) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (await prefs.setString('group${group}Alias', alias)) {
      CacheManagerMemory.groupPreferences[group][GroupAttribute.Alias] = alias;
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
      CacheManagerMemory.groupPreferences[group][GroupAttribute.Image] = image;
      return true;
    } else {
      return false;
    }
  }
}
