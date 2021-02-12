import 'dart:io';

class CacheManagerMemory {
  static bool dayIsHome;
  static Map<String, dynamic> nextCourse;
  static Map<DateTime, dynamic> dayCourses = {};
  static Map<DateTime, dynamic> courses = {};
  static File schoolTimetableFile;
  static List remoteSchoolDays = [];
}
