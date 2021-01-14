import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:provider/provider.dart';

class Announcements extends StatefulWidget {
  //final UserData user;
  //Announcements({this.user});

  @override
  _AnnouncementsState createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: user.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData user = snapshot.data;
            return StreamBuilder(
              stream: DatabaseService(uid: user.school.uid).announcements,
              builder: (context, announcementsSnapshot) {
                if (announcementsSnapshot.hasData) {
                  QuerySnapshot announcements = announcementsSnapshot.data;
                  return ListView.builder(
                      itemCount: announcements.docs.length,
                      itemBuilder: (context, index) {
                        var announcementsData =
                            // Reversing it to get the latest added document
                            announcements.docs.toList();
                        announcementsData.sort((a, b) => b
                            .data()['createdAt']
                            .compareTo(a.data()['createdAt']));
                        var announcement = announcementsData[index];
                        return Card(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              ListTile(
                                  //leading: RichText(
                                  //    text: TextSpan(children: [
                                  //  WidgetSpan(child: Icon(Icons.person)),
                                  //  TextSpan(text: announcement['author'])
                                  //])),
                                  title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            FutureBuilder(
                                                future: (announcement['author']
                                                        as DocumentReference)
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    Map<String, dynamic> data =
                                                        snapshot.data.data();
                                                    return Row(
                                                      children: [
                                                        ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30),
                                                            child: data['avatarUrl'] !=
                                                                    null
                                                                ? CachedNetworkImage(
                                                                    imageUrl: data[
                                                                        'avatarUrl'],
                                                                    progressIndicatorBuilder: (context,
                                                                            url,
                                                                            downloadProgress) =>
                                                                        CircularProgressIndicator(
                                                                            value:
                                                                                downloadProgress.progress),
                                                                    errorWidget: (context,
                                                                            url,
                                                                            error) =>
                                                                        Icon(Icons
                                                                            .error),
                                                                    height: 20,
                                                                    width: 20,
                                                                  )
                                                                : Container(
                                                                    width: 20,
                                                                    height: 20,
                                                                    color: Colors
                                                                            .grey[
                                                                        900],
                                                                    child: Icon(
                                                                      Icons
                                                                          .person,
                                                                      size: 10,
                                                                    ))),
                                                        SizedBox(
                                                          width: 5,
                                                        ),
                                                        Text(data['firstName'])
                                                      ],
                                                    );
                                                  } else {
                                                    return CircularProgressIndicator();
                                                  }
                                                }),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              DateFormat.yMMMMEEEEd().format(
                                                  (announcement['createdAt']
                                                          as Timestamp)
                                                      .toDate()),
                                              style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(announcement['title']),
                                            Spacer(),
                                            Container(
                                              width: 50,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[700],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Material(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      onTap: () => {},
                                                      child: Center(
                                                          child: Text(
                                                        "École",
                                                        style: TextStyle(
                                                            fontSize: 10),
                                                      )))),
                                            )
                                          ],
                                        ),
                                      ]),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text((announcement['description']
                                                        as String)
                                                    .length <
                                                100
                                            ? announcement['description']
                                            : (announcement['description']
                                                        as String)
                                                    .substring(0, 100) +
                                                "..."),
                                      ])),
                              SizedBox(
                                height: 5,
                              ),
                            ]));
                      });
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
