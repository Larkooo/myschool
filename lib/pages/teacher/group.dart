import 'dart:io';

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/components/new_homework.dart';
import 'package:myschool/components/student_list.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_crop_new/image_crop_new.dart';
import 'package:image_picker/image_picker.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

class GroupPage extends StatefulWidget {
  final String groupUid;
  final String schoolUid;
  final String alias;
  final File image;
  final UserData user;
  GroupPage({this.groupUid, this.schoolUid, this.alias, this.image, this.user});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  String groupAlias;
  File groupImage;

  final picker = ImagePicker();
  final imgCropKey = GlobalKey<CropState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    groupAlias = widget.alias;
    groupImage = widget.image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
                groupAlias != null ? groupAlias : 'Groupe ' + widget.groupUid)),
        body: SingleChildScrollView(
          child:
              /*FutureBuilder(
        future: Firebase,
        builder: (context, snapshot) {},)*/
              Center(
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height / 50),
              GestureDetector(
                  onTap: () async {
                    File image = await getImage(picker);
                    if (image != null) {
                      adaptiveDialog(
                        context: context,
                        title: Text(
                            "Êtes vous sur de vouloir choisir cette image?"),
                        content: Container(
                            height: MediaQuery.of(context).size.height / 2.4,
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: Crop(
                                aspectRatio: 1 / 1,
                                key: imgCropKey,
                                image: FileImage(image))),
                        actions: [
                          adaptiveDialogTextButton(
                              context, "Non", () => Navigator.pop(context)),
                          adaptiveDialogTextButton(context, "Oui", () async {
                            final crop = imgCropKey.currentState;
                            final croppedImage = await ImageCrop.cropImage(
                                file: image, area: crop.area);
                            // Decoding image to get its dimensions
                            final decodedImage = await decodeImageFromList(
                                croppedImage.readAsBytesSync());
                            // If dimensions below 256/256, cancel everything
                            if (decodedImage.width < 256 ||
                                decodedImage.height < 256) {
                              Navigator.pop(context);
                              return showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: Text(
                                            "Résolution de l'image trop petite"),
                                        content: Text(
                                            "Votre image doit faire au minimum 256px par 256px"),
                                        actions: [
                                          adaptiveDialogTextButton(
                                            context,
                                            "Ok",
                                            () => Navigator.pop(context),
                                          )
                                        ],
                                      ));
                            }
                            bool imageSet = await LocalStorage.setGroupImage(
                                widget.groupUid, croppedImage);
                            if (imageSet)
                              setState(() {
                                groupImage = croppedImage;
                              });

                            Navigator.pop(context);
                          }),
                        ],
                      );
                    } else {
                      print('could not get image');
                    }
                  },
                  child: Badge(
                    badgeColor: Colors.grey[900],
                    badgeContent: Icon(
                      Icons.add_photo_alternate_outlined,
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.height / 7,
                      height: MediaQuery.of(context).size.height / 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                      ),
                      child: groupImage != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                              child: Image.file(groupImage))
                          : Center(
                              child: Text(
                              widget.groupUid,
                              style: TextStyle(fontSize: 20),
                            )),
                    ),
                  )),
              SizedBox(height: MediaQuery.of(context).size.height / 200),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    groupAlias != null
                        ? groupAlias
                        : 'Groupe ' + widget.groupUid,
                    style: TextStyle(fontSize: 20),
                  ),
                  IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        showTextInputDialog(
                            title: 'Alias',
                            context: context,
                            cancelLabel: 'Annuler',
                            textFields: [
                              DialogTextField(hintText: 'Mon groupe favoris!')
                            ]).then((inputs) async {
                          bool aliasSet = await LocalStorage.setGroupAlias(
                              widget.groupUid, inputs.first);
                          if (aliasSet)
                            setState(() {
                              groupAlias = inputs.first;
                            });
                        });
                      },
                      iconSize: 20),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 40),
              Container(
                  width: MediaQuery.of(context).size.width / 1.1,
                  child: Card(
                      color: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Actions',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white70),
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width / 1.2,
                              decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(10)),
                              margin: EdgeInsets.all(10),
                              child: Column(children: [
                                SizedBox(
                                  height: 5,
                                ),
                                Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.5,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => NewAnnounce(
                                                  group: widget.groupUid,
                                                  user: widget.user))),
                                      child: Text('Publier une annonce'),
                                      style: ButtonStyle(),
                                    )),
                                Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.5,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => NewHomework(
                                                  group: widget.groupUid,
                                                  user: widget.user))),
                                      child: Text('Envoyer un devoir'),
                                      style: ButtonStyle(),
                                    )),
                                SizedBox(
                                  height: 5,
                                )
                              ])),
                        ],
                      ))),
              SizedBox(height: MediaQuery.of(context).size.height / 40),
              Container(
                  width: MediaQuery.of(context).size.width / 1.1,
                  child: Card(
                      color: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Informations',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white70),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.2,
                            decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(10)),
                            margin: EdgeInsets.all(10),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.group),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                40,
                                      ),
                                      CacheManagerMemory.groupData[
                                                      widget.groupUid]
                                                  [GroupAttribute.Students] !=
                                              null
                                          ? Text(
                                              'Élèves : ' +
                                                  CacheManagerMemory
                                                      .groupData[widget.groupUid]
                                                          [GroupAttribute
                                                              .Students]
                                                      .length
                                                      .toString(),
                                              style: TextStyle(fontSize: 15))
                                          : FutureBuilder(
                                              future: FirebaseFirestore.instance
                                                  .collection('users')
                                                  .where('school',
                                                      isEqualTo: FirebaseFirestore
                                                          .instance
                                                          .collection('schools')
                                                          .doc(widget.schoolUid)
                                                          .collection('groups')
                                                          .doc(widget.groupUid))
                                                  .get(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  CacheManagerMemory.groupData[
                                                          widget.groupUid][
                                                      GroupAttribute
                                                          .Students] = (snapshot
                                                      .data.docs
                                                      .map((doc) => DatabaseService()
                                                          .userDataFromSnapshot(
                                                              doc))).toList();

                                                  return Text(
                                                    'Élèves : ' +
                                                        snapshot.data.size
                                                            .toString(),
                                                    style:
                                                        TextStyle(fontSize: 15),
                                                  );
                                                } else {
                                                  return CircularProgressIndicator
                                                      .adaptive();
                                                }
                                              })
                                    ]),
                                Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.5,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => StudentList(
                                                    students: CacheManagerMemory
                                                                .groupData[
                                                            widget.groupUid][
                                                        GroupAttribute
                                                            .Students],
                                                  ))),
                                      child: Text('Liste des élèves'),
                                      style: ButtonStyle(),
                                    )),
                                SizedBox(
                                  height: 5,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          )
                        ],
                      ))),
            ],
          )),
        ));
  }
}
