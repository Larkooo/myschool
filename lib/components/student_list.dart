import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/constants.dart';

class StudentList extends StatelessWidget {
  final List students;
  StudentList({this.students});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Liste des élèves')),
      body: ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            return Card(
                child: ListTile(
                    leading: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: students[index].avatarUrl != null &&
                                students[index].uid != "-1"
                            ? CachedNetworkImage(
                                imageUrl: students[index].avatarUrl,
                                //progressIndicatorBuilder:
                                //    (context, url, downloadProgress) =>
                                //        CircularProgressIndicator.adaptive(
                                //            value: downloadProgress.progress),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                                placeholder: (context, url) => noAvatar(20),
                                height: 20 * 2.0,
                                width: 20 * 2.0,
                              )
                            : noAvatar(2)),
                    title: Text(students[index].firstName +
                        ' ' +
                        students[index].lastName)));
          }),
    );
  }
}
