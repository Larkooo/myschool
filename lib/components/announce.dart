import 'dart:io';
import 'dart:ui';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/components/announce_page.dart';
import 'package:myschool/pages/staff/teacher/group.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
import 'package:photo_view/photo_view.dart';
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
    final Card announcementCard = Card(
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            onTap: () => showSlideDialog(
                context: context,
                child: AnnouncePage(announcement: announcement)),
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                height: 10,
              ),
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
                                author = DatabaseService.userDataFromSnapshot(
                                    snapshot.data);
                                // cache the user by its id
                                CacheManagerMemory
                                    .cachedUsers[announcement.author] = author;
                              } else {
                                author = UserData(uid: "-1");
                              }

                              return userLeadingHorizontal(author, 1);
                            } else {
                              return CircularProgressIndicator(
                                strokeWidth: 2,
                              );
                            }
                          })
                      : userLeadingHorizontal(
                          CacheManagerMemory.cachedUsers[announcement.author],
                          1),
                  SizedBox(
                    width: 5,
                  ),
                  formattedDate(announcement.createdAt,
                      MediaQuery.of(context).size.width / 30)
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    child: Text(announcement.title),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width / 1.9),
                  ),
                  Spacer(),
                  Container(
                    width: MediaQuery.of(context).size.width / 7,
                    height: MediaQuery.of(context).size.height / 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                        borderRadius: BorderRadius.circular(10),
                        child: Tooltip(
                            message: announcement.scope == Scope.group
                                ? announcement.uid != '-1'
                                    ? announcement.reference.parent.parent.id
                                    : "Foyer"
                                : "École",
                            child: InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(10),
                                child: Center(
                                    child: Text(
                                  announcement.scope == Scope.group
                                      ? announcement.uid != '-1'
                                          ? announcement
                                              .reference.parent.parent.id
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
              SizedBox(
                height: 10,
              ),
              if (announcement.attachments.isNotEmpty)
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 5,
                      children: announcement.attachments.map((attachmentURL) {
                        Reference ref =
                            FirebaseStorage.instance.refFromURL(attachmentURL);
                        bool isMedia = ['jpg', 'png', 'jpeg']
                            .contains(ref.name.split('.')[1]);
                        CachedNetworkImage preview;
                        if (isMedia)
                          preview = CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: attachmentURL,
                          );

                        return Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10)),
                            width: MediaQuery.of(context).size.width / 5,
                            height: MediaQuery.of(context).size.height / 10,
                            child: preview != null
                                ? Stack(
                                    children: [
                                      Positioned.fill(child: preview),
                                      Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder:
                                                      (context) => Material(
                                                              child: Stack(
                                                                  children: [
                                                                PhotoView(
                                                                    imageProvider:
                                                                        CachedNetworkImageProvider(
                                                                            attachmentURL)),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Material(
                                                                        clipBehavior:
                                                                            Clip
                                                                                .antiAlias,
                                                                        type: MaterialType
                                                                            .transparency,
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                                45),
                                                                        child: IconButton(
                                                                            icon:
                                                                                Icon(Icons.arrow_back),
                                                                            onPressed: () => Navigator.pop(context))),
                                                                    Material(
                                                                        clipBehavior:
                                                                            Clip
                                                                                .antiAlias,
                                                                        type: MaterialType
                                                                            .transparency,
                                                                        borderRadius:
                                                                            BorderRadius.circular(45),
                                                                        child: IconButton(
                                                                            icon: Icon(Icons.file_download),
                                                                            onPressed: () {
                                                                              launchURL(attachmentURL);
                                                                              Navigator.pop(context);
                                                                            })),
                                                                  ],
                                                                )
                                                              ])))),
                                        ),
                                      )
                                    ],
                                  )
                                : Material(
                                    child: InkWell(
                                        onTap: () => showPlatformDialog(
                                            context: context,
                                            builder: (context) =>
                                                PlatformAlertDialog(
                                                  title: Text('Fichier'),
                                                  content: Text(
                                                      'Voulez-vous télécharger ce fichier?'),
                                                  actions: [
                                                    PlatformDialogAction(
                                                      child: Text('Annuler'),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                    ),
                                                    PlatformDialogAction(
                                                        child:
                                                            Text('Télécharger'),
                                                        onPressed: () {
                                                          launchURL(
                                                              attachmentURL);
                                                          Navigator.pop(
                                                              context);
                                                        })
                                                  ],
                                                )),
                                        child: Container(
                                          child: Center(
                                            child: Text(ref.name),
                                          ),
                                        ))));
                      }).toList(),
                    )),
              if ((user.uid == announcement.author) &&
                  announcement.uid != '-1' &&
                  Platform.isAndroid)
                Row(children: [
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => showOkCancelAlertDialog(
                            context: context,
                            okLabel: 'Supprimer',
                            cancelLabel: 'Annuler',
                            title: 'Suppression',
                            message:
                                'Voulez-vous vraiment supprimer cette annonce?')
                        .then((value) async {
                      if (value == OkCancelResult.ok)
                        await DatabaseService.deleteAnnounce(
                            announcement.reference);
                    }),
                  )
                ]),
              SizedBox(
                height: 5,
              )
            ]),
          ),
        ]));

    return Platform.isIOS && announcement.uid != '-1'
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
                    FlutterClipboard.copy(announcement.content).then((_) {
                      Navigator.pop(context);
                    });
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
                                  'Voulez-vous vraiment supprimer cette annonce?')
                          .then((value) async {
                        if (value == OkCancelResult.ok)
                          await DatabaseService.deleteAnnounce(
                              announcement.reference);
                      });
                    },
                  ),
              ], child: announcementCard)
        : announcementCard;
  }
}
