import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/announcement.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';

class Announce extends StatelessWidget {
  final Announcement announcement;

  Announce({this.announcement});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                                                value:
                                                    downloadProgress.progress),
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
          ])),
      SizedBox(
        height: 5,
      ),
    ]));
  }
}
