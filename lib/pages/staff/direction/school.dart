import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_crop_new/image_crop_new.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myschool/components/group_list.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
import 'package:rxdart/rxdart.dart';

class SchoolPage extends StatelessWidget {
  final UserData user;
  SchoolPage({this.user});

  final picker = ImagePicker();
  final imgCropKey = GlobalKey<CropState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: DatabaseService(uid: user.school.uid).school,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              School school = snapshot.data;
              return Center(
                  child: Column(
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
                                height:
                                    MediaQuery.of(context).size.height / 2.4,
                                width: MediaQuery.of(context).size.width / 1.5,
                                child: Crop(
                                    aspectRatio: 1 / 1,
                                    key: imgCropKey,
                                    image: FileImage(image))),
                            actions: [
                              adaptiveDialogTextButton(
                                  context, "Non", () => Navigator.pop(context)),
                              adaptiveDialogTextButton(context, "Oui",
                                  () async {
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
                                String url = await StorageService(
                                        ref:
                                            '/schools/${school.uid}/avatar.png')
                                    .uploadFile(croppedImage);
                                await FirebaseFirestore.instance
                                    .collection('schools')
                                    .doc(school.uid)
                                    .update({'avatarUrl': url});

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
                          child: school.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(90)),
                                  child: CachedNetworkImage(
                                      imageUrl: school.avatarUrl))
                              : Center(
                                  child: Text(
                                  school.name,
                                  style: TextStyle(fontSize: 10),
                                )),
                        ),
                      )),
                  SizedBox(height: MediaQuery.of(context).size.height / 200),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        school.name,
                        style: TextStyle(fontSize: 20),
                      ),
                      IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            showTextInputDialog(
                                    title: 'Alias',
                                    context: context,
                                    cancelLabel: 'Annuler',
                                    textFields: [DialogTextField()])
                                .then((inputs) async {
                              await FirebaseFirestore.instance
                                  .collection('schools')
                                  .doc(school.uid)
                                  .update({'name': inputs[0]});
                            });
                          },
                          iconSize: 20),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height / 40),
                  Container(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Actions',
                                style: TextStyle(fontSize: 20),
                              ),
                              Container(
                                  width:
                                      MediaQuery.of(context).size.width / 1.2,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10)),
                                  margin: EdgeInsets.all(10),
                                  child: Column(children: [
                                    Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                1.5,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      NewAnnounce())),
                                          child: Text('Publier une annonce'),
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
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Informations',
                                style: TextStyle(fontSize: 20),
                              ),
                              Container(
                                  width:
                                      MediaQuery.of(context).size.width / 1.2,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10)),
                                  margin: EdgeInsets.all(10),
                                  child: Column(children: [
                                    largeButton(
                                        context,
                                        Text('Voir tous les groupes'),
                                        () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => GroupList(
                                                    schoolUid: school.uid)))),
                                    SizedBox(
                                      height: 5,
                                    )
                                  ])),
                            ],
                          ))),
                ],
              ));
            } else {
              return CircularProgressIndicator.adaptive();
            }
          }),
    );
  }
}
