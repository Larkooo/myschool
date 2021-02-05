import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:provider/provider.dart';

class Announce extends StatelessWidget {
  final Announcement announcement;

  Announce({this.announcement});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    final Card announcementCard = Card(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              StreamBuilder(
                  stream: DatabaseService(uid: announcement.author).user,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      UserData announceUser = snapshot.data;
                      return Row(
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: announceUser.avatarUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: announceUser.avatarUrl,
                                      progressIndicatorBuilder: (context, url,
                                              downloadProgress) =>
                                          CircularProgressIndicator(
                                              value: downloadProgress.progress),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                      height: 20,
                                      width: 20,
                                    )
                                  : Container(
                                      width: 20,
                                      height: 20,
                                      color: Colors.grey[900],
                                      child: Icon(
                                        Icons.person,
                                        size: 10,
                                      ))),
                          SizedBox(
                            width: 5,
                          ),
                          Text(announceUser.firstName)
                        ],
                      );
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
                DateFormat.yMMMMEEEEd().format(announcement.createdAt),
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Text(announcement.title),
              Spacer(),
              Container(
                width: 50,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => {},
                        child: Center(
                            child: Text(
                          announcement.scope == Scope.school
                              ? "École"
                              : "Foyer",
                          style: TextStyle(fontSize: 10),
                        )))),
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
              TextButton(
                child: Text("Supprimer",
                    style: TextStyle(fontSize: 12, color: Colors.red)),
                onPressed: () => adaptiveDialog(
                    context: context,
                    content:
                        Text("Voulez vous vraiment supprimer cette annonce?"),
                    actions: [
                      adaptativeDialogTextButton(
                          context, "Non", () => Navigator.pop(context)),
                      adaptativeDialogTextButton(context, "Oui", () async {
                        await DatabaseService().deleteAnnounce(
                            announcement.raw, announcement.reference);
                        Navigator.pop(context);
                      })
                    ]),
              )
            ])
        ]),
      ),
      SizedBox(
        height: 5,
      ),
    ]));

    return Platform.isIOS &&
            user.uid == announcement.author &&
            announcement.uid != -1
        ? CupertinoContextMenu(actions: [
            CupertinoContextMenuAction(
              child: Text("Supprimer",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  )),
              onPressed: () {
                Navigator.pop(context);
                adaptiveDialog(
                    context: context,
                    content:
                        Text("Voulez vous vraiment supprimer cette annonce?"),
                    actions: [
                      adaptativeDialogTextButton(
                          context, "Non", () => Navigator.pop(context)),
                      adaptativeDialogTextButton(context, "Oui", () async {
                        await DatabaseService().deleteAnnounce(
                            announcement.raw, announcement.reference);
                        Navigator.pop(context);
                      })
                    ]);
              },
            )
          ], child: announcementCard)
        : announcementCard;
  }
}
