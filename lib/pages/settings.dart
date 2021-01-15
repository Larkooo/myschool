import 'dart:io';

import 'package:alert/alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_crop_new/image_crop_new.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myschool/components/change_password.dart';
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

  int count = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Scaffold(
        appBar: AppBar(
          title: Text("Paramètres"),
        ),
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
                                    context: context, child: ChangePassword())
                            //subtitle: user.email,
                            ),
                        SettingsTile(
                          leading: Icon(Icons.image_search),
                          title: "Choisir une photo de profil",
                          onPressed: (context) async {
                            File image = await getImage();
                            if (image != null) {
                              const twoMb = 2 * (1e+6);
                              if (await image.length() > twoMb) {
                                return showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          title: Text(
                                              "Taille de l'image trop grosse"),
                                          content: Text(
                                              "La taille de votre image doit faire au maximum 2 mégaoctets"),
                                          actions: [
                                            FlatButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text("Ok"))
                                          ],
                                        ));
                              }
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: Text(
                                            "Êtes vous sur de vouloir choisir cette photo de profil ?"),
                                        content: Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                2.4,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.5,
                                            child: Crop(
                                                aspectRatio: 1 / 1,
                                                key: imgCropKey,
                                                image: FileImage(image))),
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
                                                    await ImageCrop.cropImage(
                                                        file: image,
                                                        area: crop.area);
                                                // Decoding image to get its dimensions
                                                final decodedImage =
                                                    await decodeImageFromList(
                                                        croppedImage
                                                            .readAsBytesSync());
                                                // If dimensions below 256/256, cancel everything
                                                if (decodedImage.width < 256 ||
                                                    decodedImage.height < 256) {
                                                  Navigator.pop(context);
                                                  return showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                            title: Text(
                                                                "Résolution de l'image trop petite"),
                                                            content: Text(
                                                                "Votre image doit faire au minimum 256px par 256px"),
                                                            actions: [
                                                              FlatButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child: Text(
                                                                      "Ok"))
                                                            ],
                                                          ));
                                                }
                                                String avatarUrl =
                                                    await StorageService(
                                                            ref:
                                                                'users/${user.uid}/avatar.png')
                                                        .uploadFile(
                                                            croppedImage);
                                                await DatabaseService(
                                                        uid: user.uid)
                                                    .updateUserData(
                                                        avatarUrl: avatarUrl);
                                                Navigator.pop(context);
                                              },
                                              child: Text("Oui")),
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
                                      // Easter Egg start
                                      onPressed: (context) {
                                        count++;
                                        if (count > 5) {
                                          Alert(
                                                  message:
                                                      "Fécicitations, ${userData.firstName} vous m'avez trouvé!")
                                              .show();
                                        }
                                        if (count > 10) {
                                          Alert(
                                                  message:
                                                      "Si tu continues il y aura peut-être une surprise...")
                                              .show();
                                        }
                                        if (count > 50) {
                                          Alert(message: "${count}").show();
                                        }
                                        if (count > 100) {
                                          Alert(message: "tu es rendu à 100!")
                                              .show();
                                        }
                                        if (count > 250) {
                                          Alert(
                                                  message:
                                                      "relax un peu ce n'est pas facile de compter aussi vite. Prochain: 1000? Mais attention, ne redémarrez pas l'app, vous perdrez votre progression!")
                                              .show();
                                        }
                                        if (count > 1000) {
                                          Alert(
                                                  message:
                                                      "1000! ${userData.firstName}, jusqu'ou irez vous?")
                                              .show();
                                        }
                                        if (count > 1005) {
                                          Alert(message: "${count}").show();
                                        }
                                      }, // Easter Egg end
                                    ),
                                    SettingsTile(
                                      leading: Icon(Icons.group),
                                      title: userData.school.group.uid,
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
                          leading: Icon(Icons.delete_forever),
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
