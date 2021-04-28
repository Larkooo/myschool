import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/homework.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:photo_view/photo_view.dart';
import '../models/announcement.dart';
import 'package:dart_date/dart_date.dart';

class HomeworkPage extends StatelessWidget {
  final Homework homework;

  HomeworkPage({this.homework});

  @override
  Widget build(BuildContext context) {
    int diffInDaysNow = homework.createdAt.differenceInDays(DateTime.now());
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
            CacheManagerMemory.cachedUsers[homework.author], 1.3),
        SizedBox(
          height: 5,
        ),
        Text(
          'Titre',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Text(
          homework.title,
          style: TextStyle(fontSize: 25),
        ),
        Text(
          'Contenu',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Container(
            height: MediaQuery.of(context).size.height /
                (homework.attachments.isNotEmpty ? 4 : 3),
            width: MediaQuery.of(context).size.height / 1.8,
            child: Card(
                margin: EdgeInsets.fromLTRB(40, 10, 40, 0),
                child: SingleChildScrollView(
                  child: Container(
                      margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      //width: MediaQuery.of(context).size.width / 10,
                      child: Text(homework.description,
                          style: TextStyle(fontSize: 15))),
                ))),
        SizedBox(
          height: 10,
        ),
        if (homework.attachments.isNotEmpty)
          filesListWidget(context, homework.attachments),
        SizedBox(
          height: 10,
        ),
        formattedDate(homework.createdAt, 15)
      ],
    );
  }
}
