import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/homework.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/components/announce_page.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dart_date/dart_date.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';

class HomeworkComp extends StatelessWidget {
  final Homework homework;

  HomeworkComp({this.homework});

  UserData author;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    int diffInDaysNow = homework.createdAt.differenceInDays(DateTime.now());
    final Card announcementCard = Card(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        onTap: () {},
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(homework.author)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      author =
                          DatabaseService().userDataFromSnapshot(snapshot.data);
                      return userLeadingHorizontal(author, 1);
                    } else {
                      return CircularProgressIndicator(
                        strokeWidth: 2,
                      );
                    }
                  }),
              SizedBox(
                width: 5,
              ),
              Text(
                diffInDaysNow == 0
                    ? "Aujourd'hui"
                    : diffInDaysNow == -1
                        ? "Hier"
                        : diffInDaysNow == -2
                            ? "Avant-hier"
                            : DateFormat.yMMMMEEEEd()
                                    .format(homework.createdAt) +
                                " à " +
                                DateFormat.Hm().format(homework.createdAt),
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: MediaQuery.of(context).size.width / 30),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Text(homework.title),
              Spacer(),
              Container(
                  width: MediaQuery.of(context).size.width / 5,
                  height: MediaQuery.of(context).size.height / 35,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                              child: Text(
                            homework.subject,
                            style: TextStyle(fontSize: 10),
                          ))))),
              SizedBox(
                width: 5,
              ),
              if (homework.uid != -1)
                Container(
                    width: MediaQuery.of(context).size.width / 8,
                    height: MediaQuery.of(context).size.height / 35,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(10),
                            child: Center(
                                child: Text(
                              // group
                              homework.reference.id,
                              style: TextStyle(fontSize: 10),
                            ))))),
            ],
          ),
        ]),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(homework.description.length < 150
              ? homework.description
              : homework.description.substring(0, 150).trim() + "..."),
          if (user.uid == homework.author &&
              homework.uid != -1 &&
              Platform.isAndroid)
            Row(children: [
              Spacer(),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey),
                onPressed: () => adaptiveDialog(
                    context: context,
                    content: Text("Voulez vous vraiment annuler ce devoir?"),
                    actions: [
                      adaptiveDialogTextButton(
                          context, "Non", () => Navigator.pop(context)),
                      adaptiveDialogTextButton(context, "Oui", () async {
                        await DatabaseService()
                            .deleteHomework(homework.raw, homework.reference);
                        Navigator.pop(context);
                      })
                    ]),
              )
            ]),
          Text(
            'À remettre le ' + homework.due.format('d MMMM H:m', 'fr_FR'),
            style: TextStyle(
                fontSize: 13,
                color: homework.due.compareTo(DateTime.now()) < 0
                    ? Colors.red
                    : Colors.grey[500]),
          )
        ]),
      ),
      SizedBox(
        height: 5,
      ),
    ]));

    return Platform.isIOS && homework.uid != -1
        ? CupertinoContextMenu(
            /*previewBuilder: (BuildContext context, Animation<double> animation,
                Widget child) {
              return Container(
                  child: Announce(announcement: announcement),
                  width: 1000 / animation.value,
                  height: 200 / animation.value);
            },*/
            actions: [
                CupertinoContextMenuAction(
                  trailingIcon: Icons.copy,
                  child: Text("Copier",
                      style: TextStyle(
                        fontSize: 14,
                      )),
                  onPressed: () {
                    FlutterClipboard.copy(homework.description).then((_) {
                      Navigator.pop(context);
                      adaptiveDialog(
                          context: context,
                          content: Text("Contenu de l'annonce copié."),
                          actions: [
                            adaptiveDialogTextButton(
                                context, "Ok", () => Navigator.pop(context))
                          ]);
                    });
                  },
                ),
                if (user.uid == homework.author)
                  CupertinoContextMenuAction(
                    trailingIcon: Icons.delete,
                    child: Text("Supprimer",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        )),
                    onPressed: () {
                      Navigator.pop(context);
                      adaptiveDialog(
                          context: context,
                          content:
                              Text("Voulez vous vraiment annuler ce devoir?"),
                          actions: [
                            adaptiveDialogTextButton(
                                context, "Non", () => Navigator.pop(context)),
                            adaptiveDialogTextButton(context, "Oui", () async {
                              await DatabaseService().deleteHomework(
                                  homework.raw, homework.reference);
                              Navigator.pop(context);
                            })
                          ]);
                    },
                  ),
              ], child: announcementCard)
        : announcementCard;
  }
}
