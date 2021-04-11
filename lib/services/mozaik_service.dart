import 'dart:convert';

import 'package:myschool/models/mozaik.dart';
import 'package:http/http.dart' as http;
import 'package:dart_date/dart_date.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MozaikService {
  static String _timetableUrl(String userId, String schoolId) =>
      'https://apiaffaires.mozaikportail.ca/api/organisationScolaire/donneesAnnuelles/$schoolId/$userId/activitescalendrier?dateDebut=${DateTime(DateTime.now().year - 1).format('yyyy-MM-dd')}&dateFin=${DateTime(DateTime.now().year + 1).format('yyyy-MM-dd')}';

  static Future getMozaikTimetable() async {
    try {
      final res = await http.get(
          Uri.parse(_timetableUrl(
              Mozaik.payload['ficheJeune'], Mozaik.payload['eleveJeune'])),
          headers: {
            'Authorization': 'Bearer ' + Mozaik.idToken,
            'Origin': 'https://mozaikportail.ca',
            'Referer': 'https://mozaikportail.ca/',
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36'
          });
      dynamic decodedBody = res.statusCode == 200 ? jsonDecode(res.body) : null;
      return decodedBody;
    } catch (_) {
      print(_);
      return null;
    }
  }
}
