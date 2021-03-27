import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<String> getGroupAlias(String group) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('group${group}Alias');
  }

  static Future<bool> setGroupAlias(String group, String alias) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString('group${group}Alias', alias);
  }
}
