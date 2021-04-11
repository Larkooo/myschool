import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/constants.dart';

class StudentList extends StatefulWidget {
  final List students;
  StudentList({this.students});

  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  bool _searchBarToggled = false;

  String _searchQuery = "";

  void toggleSearchBar() {
    setState(() {
      _searchBarToggled = !_searchBarToggled;
      if (!_searchBarToggled) _searchQuery = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(children: [
        _searchBarToggled
            ? Container(
                child: PlatformTextField(
                  keyboardType: TextInputType.name,
                  onChanged: (v) {
                    setState(() {
                      _searchQuery = v;
                    });
                  },
                ),
                width: MediaQuery.of(context).size.width / 1.5)
            : Text('Liste des élèves'),
        Spacer(),
        IconButton(
          icon: _searchBarToggled ? Icon(Icons.close) : Icon(Icons.search),
          onPressed: toggleSearchBar,
        )
      ])),
      body: ListView.builder(
          itemCount: widget.students.length,
          itemBuilder: (context, index) {
            // check if firstname or lastname contains/corresponds to the searchquery, if it doesnt, just return an empty container
            if (!(widget.students[index].firstName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                widget.students[index].lastName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))) return Container();
            return Card(
                child: ListTile(
                    leading: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: widget.students[index].avatarUrl != null &&
                                widget.students[index].uid != "-1"
                            ? CachedNetworkImage(
                                imageUrl: widget.students[index].avatarUrl,
                                //progressIndicatorBuilder:
                                //    (context, url, downloadProgress) =>
                                //        CircularProgressIndicator.adaptive(
                                //            value: downloadProgress.progress),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                                placeholder: (context, url) => noAvatar(2),
                                height: 20 * 2.0,
                                width: 20 * 2.0,
                              )
                            : noAvatar(2)),
                    title: Text(widget.students[index].firstName +
                        ' ' +
                        widget.students[index].lastName)));
          }),
    );
  }
}
