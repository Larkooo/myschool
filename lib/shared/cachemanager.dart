import 'dart:io';
import 'dart:typed_data';

import 'package:myschool/models/user.dart';

import 'constants.dart';

class CacheManagerMemory {
  static bool dayIsHome;
  static Map<String, dynamic> nextCourse;
  static Map<DateTime, dynamic> dayCourses = {};
  static Map<DateTime, dynamic> courses = {};
  static File schoolTimetableFile;
  static List remoteSchoolDays = [];
  static Map<String, Map<GroupAttribute, dynamic>> groupData = {};
  static Map<String, UserData> cachedUsers = {};
  //static Map<String, Uint8List> images = {};
}
