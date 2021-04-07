import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';

class StudentList extends StatelessWidget {
  final List students;
  StudentList({this.students});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            return Card(
                child: ListTile(
                    title: Text(students[index].firstName +
                        ' ' +
                        students[index].lastName)));
          }),
    );
  }
}
