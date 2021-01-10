import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_crop_new/image_crop_new.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myschool/components/reset_password.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';

class Settings extends StatefulWidget {
  final UserData user;
  Settings({this.user});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  final imgCropKey = GlobalKey<CropState>();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Scaffold(
        appBar: AppBar(),
        body: StreamBuilder(
            stream: DatabaseService(uid: user.uid).user,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                UserData userData = snapshot.data;

                return SettingsList(
                  darkBackgroundColor: Colors.grey[900],
                  sections: [
                    CustomSection(
                        child: SizedBox(
                      height: 10,
                    )),
                    SettingsSection(
                      title: 'Profil',
                      tiles: [
                        SettingsTile(
                          leading: Icon(Icons.person),
                          title: 'Prénom',
                          subtitle: userData.firstName,
                        ),
                        SettingsTile(
                          leading: Icon(Icons.person),
                          title: 'Nom de famille',
                          subtitle: userData.lastName,
                        ),
                        SettingsTile(
                          leading: Icon(Icons.email),
                          title: 'Courriel',
                          subtitle: user.email,
                        ),
                        SettingsTile(
                            leading: Icon(Icons.security),
                            title: 'Modifier votre mot de passe',
                            onPressed: (BuildContext context) =>
                                showSlideDialog(
                                    context: context,
                                    child: ResetPasswordComponent())
                            //subtitle: user.email,
                            ),
                        SettingsTile(
                          leading: Icon(Icons.image_search),
                          title: "Choisir une photo de profil",
                          onPressed: (context) async {
                            File image = await getImage();
                            if (image != null) {
                              const twoMb = 2 * (1e+6);
                              await image.length() < twoMb
                                  ? showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            title: Text(
                                                "Êtes vous sur de vouloir choisir cette photo de profil ?"),
                                            content: Crop(
                                                aspectRatio: 1 / 1,
                                                key: imgCropKey,
                                                image: FileImage(image)),
                                            actions: [
                                              FlatButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text("Non"),
                                              ),
                                              FlatButton(
                                                  onPressed: () async {
                                                    final crop =
                                                        imgCropKey.currentState;
                                                    final croppedImage =
                                                        await ImageCrop
                                                            .cropImage(
                                                                file: image,
                                                                area:
                                                                    crop.area);
                                                    await StorageService(
                                                            ref:
                                                                'users/${user.uid}/avatar.png')
                                                        .uploadFile(
                                                            croppedImage);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Oui")),
                                            ],
                                          ))
                                  : showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            title: Text(
                                                "Taille de l'image trop grosse"),
                                            content: Text(
                                                "Votre image doit faire maximum 2 mégabytes"),
                                            actions: [
                                              FlatButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text("Ok"))
                                            ],
                                          ));
                            } else {
                              print('could not get image');
                            }
                          },
                        ),
                      ],
                    ),
                    CustomSection(
                        child: SizedBox(
                      height: 10,
                    )),
                    CustomSection(
                        child: StreamBuilder(
                            stream: DatabaseService(uid: userData.school.uid)
                                .school,
                            builder: (context, schoolSnapshot) {
                              if (schoolSnapshot.hasData) {
                                School school = schoolSnapshot.data;
                                return SettingsSection(
                                  title: 'École',
                                  tiles: [
                                    SettingsTile(
                                      leading: Icon(Icons.school),
                                      title: school.name,
                                    ),
                                  ],
                                );
                              } else {
                                return SettingsSection(
                                  title: 'École',
                                  tiles: [
                                    SettingsTile(
                                      leading: CircularProgressIndicator(),
                                      title:
                                          "Mhh quelque chose semble être cassé!",
                                    ),
                                  ],
                                );
                              }
                            })),
                    CustomSection(
                        child: SizedBox(
                      height: 10,
                    )),
                    SettingsSection(
                      title: "Compte",
                      tiles: [
                        SettingsTile(
                          leading: Icon(Icons.close),
                          title: "Supprimer votre compte",
                          subtitle: "Cette action est irréversible!",
                          onPressed: (context) {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: Text(
                                        "Voulez vous vraiment supprimer votre compte?"),
                                    actions: [
                                      FlatButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text("Non")),
                                      FlatButton(
                                          onPressed: () async {
                                            bool deleted =
                                                await FirebaseAuthService
                                                    .deleteUser(user);
                                            Navigator.pop(context);
                                            if (!deleted) {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      content: Text(
                                                          "Cette action est sensible et requiert que vous vous ré-authentifier, Déconnectez et reconnectez vous pour procéder."),
                                                      actions: [
                                                        FlatButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: Text("Ok"))
                                                      ],
                                                    );
                                                  });
                                            }
                                          },
                                          child: Text("Oui")),
                                    ],
                                  );
                                });
                          },
                        )
                      ],
                    )
                  ],
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            }));
  }
}
