import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/components/new_group.dart';
import 'package:myschool/components/new_homework.dart';
import 'package:myschool/pages/staff/teacher/group.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
import '../../../models/user.dart';
import '../../../services/database.dart';
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
    Map<String, List<String>> levels = {};
    groups.forEach((group) {
      // getting first char
      int level = int.tryParse(group[0]);
      if (level == null) {
        if (levels['0 - Autres'] == null) levels['0 - Autres'] = [];
        levels['0 - Autres'].add(group);
      } else {
        if (levels[level.toString()] == null) levels[level.toString()] = [];
        levels[level.toString()].add(group);
      }
    });
    // sorting from highest number to lowest
    List<String> keys = levels.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    return Scaffold(
      body: ListView.builder(
          itemCount: keys.length,
          itemBuilder: (context, index) {
            String level = keys[index];
            return ListTile(
              title: Text(
                "Niveau $level",
                style: TextStyle(fontSize: 40),
              ),
              subtitle: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 5,
                    children: levels[keys[index]].map((group) {
                      Widget groupCard() {
                        String groupAlias = CacheManagerMemory.groupData[group]
                            [GroupAttribute.alias];
                        File groupImage = CacheManagerMemory.groupData[group]
                            [GroupAttribute.image];
                        return Material(
                          borderRadius: BorderRadius.circular(5),
                          color: Theme.of(context).cardColor,
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
                                color: Theme.of(context).cardColor,
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
                                          MediaQuery.of(context).size.height /
                                              10,
                                      width: MediaQuery.of(context).size.width /
                                          2.5,
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
                                                  style:
                                                      TextStyle(fontSize: 15),
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
          }),
      floatingActionButton: user.type == UserType.direction
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blue[400],
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NewGroup(user: user))),
              label: Text('Créer un groupe'),
            )
          : null,
    );
  }
}
