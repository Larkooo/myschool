import 'dart:io';

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/components/new_homework.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_crop_new/image_crop_new.dart';
import 'package:image_picker/image_picker.dart';

class GroupPage extends StatefulWidget {
  final String groupUid;
  final String schoolUid;
  final String alias;
  final File image;
  GroupPage({this.groupUid, this.schoolUid, this.alias, this.image});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  TextEditingController _groupAliasController = TextEditingController();

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
      body:
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
                    title:
                        Text("Êtes vous sur de vouloir choisir cette image?"),
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
                        LocalStorage.setGroupImage(
                            widget.groupUid, croppedImage);
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
                          borderRadius: BorderRadius.all(Radius.circular(50)),
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
                groupAlias != null ? groupAlias : 'Groupe ' + widget.groupUid,
                style: TextStyle(fontSize: 20),
              ),
              IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                            title: Text('Alias'),
                            actions: [
                              TextButton(
                                  onPressed: () async {
                                    _groupAliasController.clear();
                                    Navigator.pop(context);
                                  },
                                  child: Text('Annuler')),
                              TextButton(
                                  onPressed: () async {
                                    if (_groupAliasController.text.length < 1)
                                      return;
                                    await LocalStorage.setGroupAlias(
                                        widget.groupUid,
                                        _groupAliasController.text);
                                    setState(() {
                                      groupAlias = _groupAliasController.text;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text('Ok')),
                            ],
                            content: TextField(
                              decoration: InputDecoration(
                                  hintText: 'Mon groupe favoris!'),
                              controller: _groupAliasController,
                              maxLength: 50,
                              onSubmitted: (value) async {
                                await LocalStorage.setGroupAlias(
                                    widget.groupUid, value);
                              },
                            )));
                  },
                  iconSize: 20),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 40),
          Container(
              width: MediaQuery.of(context).size.width / 1.1,
              child: Card(
                  color: Colors.grey[800],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Actions',
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      Container(
                          width: MediaQuery.of(context).size.width / 1.2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        NewAnnounce(group: widget.groupUid))),
                            child: Text('Publier une annonce'),
                            style: ButtonStyle(),
                          )),
                      Container(
                          width: MediaQuery.of(context).size.width / 1.2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        NewHomework(group: widget.groupUid))),
                            child: Text('Envoyer un devoir'),
                            style: ButtonStyle(),
                          )),
                      SizedBox(
                        height: 5,
                      ),
                    ],
                  ))),
          SizedBox(height: MediaQuery.of(context).size.height / 40),
          Container(
              width: MediaQuery.of(context).size.width / 1.1,
              child: Card(
                  color: Colors.grey[800],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Informations',
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 40,
                            ),
                            CacheManagerMemory.groupData[widget.groupUid]
                                        [GroupAttribute.StudentsCount] !=
                                    null
                                ? Text(
                                    'Élèves : ' +
                                        CacheManagerMemory
                                                .groupData[widget.groupUid]
                                            [GroupAttribute.StudentsCount],
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
                                        CacheManagerMemory
                                                    .groupData[widget.groupUid]
                                                [GroupAttribute.StudentsCount] =
                                            snapshot.data.documents.length
                                                .toString();
                                        return Text(
                                          'Élèves : ' +
                                              snapshot.data.documents.length
                                                  .toString(),
                                          style: TextStyle(fontSize: 18),
                                        );
                                      } else {
                                        return CircularProgressIndicator
                                            .adaptive();
                                      }
                                    })
                          ]),
                      SizedBox(
                        height: 5,
                      ),
                    ],
                  ))),
        ],
      )),
    );
  }
}
