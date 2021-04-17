import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/components/new_homework.dart';
import 'package:myschool/pages/teacher/group.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
import '../../models/user.dart';
import '../../services/database.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Groups extends StatelessWidget {
  final UserData user;
  Groups({this.user});

  @override
  Widget build(BuildContext context) {
    List<String> groups = user.groups;
    // important to make the distinction between groups and levels here.
    // levels = grade 1, 2..
    // groups = group 504, 203...
    List<int> levels = [];
    groups.forEach((group) {
      // getting first char
      int level = int.parse(group[0]);
      if (!(levels.contains(level))) levels.add(level);
    });
    // sorting from highest number to lowest
    levels.sort((a, b) => b.compareTo(a));
    return ListView.builder(
        itemCount: levels.length,
        itemBuilder: (context, index) {
          String level = levels[index].toString();
          return ListTile(
            title: Text(
              "Niveau $level",
              style: TextStyle(fontSize: 40),
            ),
            subtitle: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 5,
                  children:
                      groups.where((group) => group[0] == level).map((group) {
                    Widget groupCard() {
                      String groupAlias = CacheManagerMemory.groupData[group]
                          [GroupAttribute.alias];
                      File groupImage = CacheManagerMemory.groupData[group]
                          [GroupAttribute.image];
                      return Material(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.grey[800],
                        child: InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GroupPage(
                                        groupUid: group,
                                        alias: groupAlias,
                                        image: groupImage,
                                        schoolUid: user.school.uid,
                                        user: user))),
                            child: Ink(
                              height: MediaQuery.of(context).size.height / 10,
                              width: MediaQuery.of(context).size.width / 2.5,
                              decoration: groupImage != null
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      shape: BoxShape.rectangle,
                                      image: DecorationImage(
                                          fit: BoxFit.fill,
                                          image: FileImage(groupImage)))
                                  : null,
                              child: groupAlias != null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          groupAlias,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                        Text(
                                          group,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[900]),
                                        )
                                      ],
                                    )
                                  : Center(
                                      child: Text(
                                      group,
                                      style: TextStyle(fontSize: 15),
                                    )),
                            )),
                      );
                    }

                    Widget groupCardFuture = FutureBuilder(
                        future: Future.wait([
                          LocalStorage.getGroupAlias(group),
                          LocalStorage.getGroupImage(group)
                        ]),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            String groupAlias = snapshot.data[0];
                            File groupImage = snapshot.data[1];
                            CacheManagerMemory.groupData[group] = {
                              GroupAttribute.alias: groupAlias,
                              GroupAttribute.image: groupImage
                            };
                            return Material(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.grey[800],
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(5),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => GroupPage(
                                              groupUid: group,
                                              alias: groupAlias,
                                              image: groupImage,
                                              schoolUid: user.school.uid,
                                              user: user))),
                                  child: Ink(
                                    height:
                                        MediaQuery.of(context).size.height / 10,
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    decoration: groupImage != null
                                        ? BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            shape: BoxShape.rectangle,
                                            image: DecorationImage(
                                                fit: BoxFit.fill,
                                                image: FileImage(groupImage)))
                                        : null,
                                    child: groupAlias != null
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                groupAlias,
                                                style: TextStyle(fontSize: 15),
                                              ),
                                              Text(
                                                group,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[900]),
                                              )
                                            ],
                                          )
                                        : Center(
                                            child: Text(
                                            group,
                                            style: TextStyle(fontSize: 15),
                                          )),
                                  )),
                            );
                          } else {
                            return Center(
                                child: CircularProgressIndicator.adaptive());
                          }
                        });
                    Widget card = CacheManagerMemory.groupData[group] != null
                        ? groupCard()
                        : groupCardFuture;
                    return Platform.isIOS
                        ? CupertinoContextMenu(actions: [
                            CupertinoContextMenuAction(
                              child: Text(
                                'Publier une annonce',
                                style: TextStyle(fontSize: 15),
                              ),
                              trailingIcon: CupertinoIcons.news,
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NewAnnounce(
                                            group: group, user: user)));
                              },
                            ),
                            CupertinoContextMenuAction(
                              child: Text(
                                'Envoyer un devoir',
                                style: TextStyle(fontSize: 15),
                              ),
                              trailingIcon: CupertinoIcons.plus_slash_minus,
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NewHomework(
                                            group: group, user: user)));
                              },
                            )
                          ], child: card)
                        : card;
                  }).toList(),
                )),
          );
        });
  }
}
