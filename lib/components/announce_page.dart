import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:photo_view/photo_view.dart';
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
            height: MediaQuery.of(context).size.height /
                (announcement.attachments.isNotEmpty ? 4 : 3),
            width: MediaQuery.of(context).size.height / 1.8,
            child: Card(
                margin: EdgeInsets.fromLTRB(40, 10, 40, 0),
                child: SingleChildScrollView(
                  child: Container(
                      margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      //width: MediaQuery.of(context).size.width / 10,
                      child: Text(announcement.content,
                          style: TextStyle(fontSize: 15))),
                ))),
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
                  bool isMedia =
                      ['jpg', 'png', 'jpeg'].contains(ref.name.split('.')[1]);
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
                                            builder: (context) => Material(
                                                    child: Stack(children: [
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
                                                              Clip.antiAlias,
                                                          type: MaterialType
                                                              .transparency,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(45),
                                                          child: IconButton(
                                                              icon: Icon(Icons
                                                                  .arrow_back),
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context))),
                                                      Material(
                                                          clipBehavior:
                                                              Clip.antiAlias,
                                                          type: MaterialType
                                                              .transparency,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(45),
                                                          child: IconButton(
                                                              icon: Icon(Icons
                                                                  .file_download),
                                                              onPressed: () {
                                                                launchURL(
                                                                    attachmentURL);
                                                                Navigator.pop(
                                                                    context);
                                                              })),
                                                    ],
                                                  )
                                                ])))),
                                  ),
                                )
                              ],
                            )
                          : Material(
                              color: Theme.of(context).focusColor,
                              child: InkWell(
                                  onTap: () => showPlatformDialog(
                                      context: context,
                                      builder: (context) => PlatformAlertDialog(
                                            title: Text('Fichier'),
                                            content: Text(
                                                'Voulez-vous télécharger ce fichier?'),
                                            actions: [
                                              PlatformDialogAction(
                                                child: Text('Annuler'),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                              PlatformDialogAction(
                                                  child: Text('Télécharger'),
                                                  onPressed: () {
                                                    launchURL(attachmentURL);
                                                    Navigator.pop(context);
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
        SizedBox(
          height: 10,
        ),
        formattedDate(announcement.createdAt, 15)
      ],
    );
  }
}
