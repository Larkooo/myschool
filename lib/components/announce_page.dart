import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import '../models/announcement.dart';
import 'package:dart_date/dart_date.dart';

class AnnouncePage extends StatelessWidget {
  final Announcement announcement;

  AnnouncePage({this.announcement});

  @override
  Widget build(BuildContext context) {
    int diffInDaysNow = announcement.createdAt.differenceInDays(DateTime.now());
    return Column(
      children: [
        SizedBox(
          height: 10,
        ),
        Text(
          'Auteur',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        SizedBox(
          height: 2,
        ),
        userLeadingVertical(
            CacheManagerMemory.cachedUsers[announcement.author], 1.3),
        SizedBox(
          height: 5,
        ),
        Text(
          'Titre',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Text(
          announcement.title,
          style: TextStyle(fontSize: 25),
        ),
        Text(
          'Contenu',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Container(
            height: MediaQuery.of(context).size.height / 3,
            child: Card(
                margin: EdgeInsets.fromLTRB(40, 10, 40, 0),
                color: Colors.grey[900],
                child: SingleChildScrollView(
                  child: Container(
                      margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      //width: MediaQuery.of(context).size.width / 10,
                      child: Text(announcement.content,
                          style: TextStyle(
                              fontSize: 15, color: Colors.grey[200]))),
                ))),
        SizedBox(
          height: 10,
        ),
        Text(
          diffInDaysNow == 0
              ? "Aujourd'hui"
              : diffInDaysNow == -1
                  ? "Hier"
                  : diffInDaysNow == -2
                      ? "Avant-hier"
                      : DateFormat.yMMMMEEEEd().format(announcement.createdAt) +
                          " à " +
                          DateFormat.Hm().format(announcement.createdAt),
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      ],
    );
  }
}
