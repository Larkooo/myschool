import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/constants.dart';
import '../models/announcement.dart';
import 'package:dart_date/dart_date.dart';

class AnnouncePage extends StatelessWidget {
  final Announcement announcement;
  final UserData author;

  AnnouncePage({this.announcement, this.author});

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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 10,
            ),
            userLeading(author, 1.3),
          ],
        ),
        SizedBox(
          height: 5,
        ),
        Text(
          'Titre',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Text(
          announcement.title,
          style: TextStyle(fontSize: 30),
        ),
        Text(
          'Contenu',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Container(
            child: SingleChildScrollView(
                child: Card(
          margin: EdgeInsets.fromLTRB(40, 10, 40, 0),
          color: Colors.grey[800],
          child: Container(
              child: Text(announcement.content,
                  style: TextStyle(fontSize: 20, color: Colors.grey[200]))),
        ))),
        SizedBox(
          height: 5,
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
          style: TextStyle(
              color: Colors.grey[500],
              fontSize: MediaQuery.of(context).size.width / 30),
        ),
      ],
    );
  }
}
