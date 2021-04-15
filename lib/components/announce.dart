import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/components/announce_page.dart';
import 'package:myschool/pages/teacher/group.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dart_date/dart_date.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';
import 'package:vibration/vibration.dart';

class Announce extends StatelessWidget {
  final Announcement announcement;

  Announce({this.announcement});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    int diffInDaysNow = announcement.createdAt.differenceInDays(DateTime.now());
    final Card announcementCard = Card(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        onTap: () => showSlideDialog(
            context: context, child: AnnouncePage(announcement: announcement)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              CacheManagerMemory.cachedUsers[announcement.author] == null
                  ? FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(announcement.author)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          UserData author;
                          if (snapshot.data.exists) {
                            author = DatabaseService()
                                .userDataFromSnapshot(snapshot.data);
                          } else {
                            author = UserData(uid: "-1");
                          }
                          // cache the user by its id
                          CacheManagerMemory.cachedUsers[announcement.author] =
                              author;

                          return userLeadingHorizontal(author, 1);
                        } else {
                          return CircularProgressIndicator(
                            strokeWidth: 2,
                          );
                        }
                      })
                  : userLeadingHorizontal(
                      CacheManagerMemory.cachedUsers[announcement.author], 1),
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
                                    .format(announcement.createdAt) +
                                " à " +
                                DateFormat.Hm().format(announcement.createdAt),
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: MediaQuery.of(context).size.width / 30),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Text(announcement.title),
              Spacer(),
              Container(
                width: MediaQuery.of(context).size.width / 7,
                height: MediaQuery.of(context).size.height / 35,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                    borderRadius: BorderRadius.circular(10),
                    child: Tooltip(
                        message: announcement.scope == Scope.group
                            ? announcement.uid != -1
                                ? announcement.reference.id
                                : "Foyer"
                            : "École",
                        child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(10),
                            child: Center(
                                child: Text(
                              announcement.scope == Scope.group
                                  ? announcement.uid != -1
                                      ? announcement.reference.id
                                      : "Foyer"
                                  : "École",
                              style: TextStyle(fontSize: 10),
                            ))))),
              )
            ],
          ),
        ]),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(announcement.content.length < 150
              ? announcement.content
              : announcement.content.substring(0, 150).trim() + "..."),
          if (user.uid == announcement.author &&
              announcement.uid != -1 &&
              Platform.isAndroid)
            Row(children: [
              Spacer(),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey),
                onPressed: () => showOkCancelAlertDialog(
                        context: context,
                        okLabel: 'Supprimer',
                        cancelLabel: 'Annuler',
                        title: 'Suppression',
                        message:
                            'Voulez vous vraiment supprimer cette annonce?')
                    .then((value) async {
                  if (value == OkCancelResult.ok)
                    await DatabaseService().deleteAnnounce(
                        announcement.raw, announcement.reference);
                }),
              )
            ])
        ]),
      ),
      SizedBox(
        height: 5,
      ),
    ]));

    return Platform.isIOS && announcement.uid != -1
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
                  onPressed: () async {
                    FlutterClipboard.copy(announcement.content).then((_) {
                      Navigator.pop(context);
                    });
                    //if (await Vibration.hasVibrator()) {
                    //Vibration.vibrate();
                    //}
                  },
                ),
                if (user.uid == announcement.author)
                  CupertinoContextMenuAction(
                    trailingIcon: Icons.delete,
                    child: Text("Supprimer",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        )),
                    onPressed: () {
                      Navigator.pop(context);
                      showOkCancelAlertDialog(
                              context: context,
                              okLabel: 'Supprimer',
                              cancelLabel: 'Annuler',
                              title: 'Suppression',
                              message:
                                  'Voulez vous vraiment supprimer cette annonce?')
                          .then((value) async {
                        if (value == OkCancelResult.ok)
                          await DatabaseService().deleteAnnounce(
                              announcement.raw, announcement.reference);
                      });
                    },
                  ),
              ], child: announcementCard)
        : announcementCard;
  }
}
