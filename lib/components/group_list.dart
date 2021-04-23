import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/group.dart';
import 'package:myschool/services/database.dart';

class GroupList extends StatelessWidget {
  final String schoolUid;
  GroupList({this.schoolUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Liste des groupes')),
        body: StreamBuilder(
          stream: DatabaseService(uid: schoolUid).groups,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Group> groups = (snapshot.data as QuerySnapshot)
                  .docs
                  .map(DatabaseService.groupFromSnapshot)
                  .toList();
              return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return Card(
                        child: ListTile(
                      title: Text(groups[index].uid),
                    ));
                  });
            } else {
              return Center(child: CircularProgressIndicator.adaptive());
            }
          },
        ));
  }
}
