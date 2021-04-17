import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class SelectGroups extends StatefulWidget {
  final String schoolUid;
  final String userUid;
  SelectGroups({this.userUid, this.schoolUid});

  @override
  _SelectGroupsState createState() => _SelectGroupsState();
}

class _SelectGroupsState extends State<SelectGroups> {
  List<String> _selectedGroups = [];

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder(
            stream: DatabaseService(uid: widget.schoolUid).groups,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                QuerySnapshot groupsSnapshot = snapshot.data;
                return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sélectionnez vos groupes",
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Container(
                          height: MediaQuery.of(context).size.width / 1.5,
                          child: ListView.builder(
                              itemCount: groupsSnapshot.size,
                              itemBuilder: (context, index) {
                                String groupUid = groupsSnapshot.docs[index].id;
                                return Card(
                                  child: Container(
                                    child: CheckboxListTile(
                                      value: _selectedGroups.contains(groupUid),
                                      title:
                                          Text(groupsSnapshot.docs[index].id),
                                      onChanged: (value) {
                                        value
                                            ? setState(() {
                                                _selectedGroups.add(groupUid);
                                              })
                                            : setState(() {
                                                _selectedGroups
                                                    .remove(groupUid);
                                              });
                                      },
                                    ),
                                  ),
                                );
                              })),
                      SizedBox(
                        height: 25,
                      ),
                      mainBlueLoadingBtn(
                          context,
                          _btnController,
                          "Continuer",
                          _selectedGroups.length < 1
                              ? null
                              : () {
                                  _btnController.start();
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.userUid)
                                      .update({
                                    "groups":
                                        FieldValue.arrayUnion(_selectedGroups)
                                  });
                                  _btnController.success();
                                  Navigator.pop(context);
                                })
                    ]);
              } else {
                return CircularProgressIndicator.adaptive();
              }
            }));
  }
}
