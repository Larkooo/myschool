import 'dart:io';
import 'dart:math';

import 'package:alert/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_crop_new/image_crop_new.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myschool/components/change_password.dart';
import 'package:myschool/components/mozaik_login.dart';
import 'package:myschool/components/reset_password.dart';
import 'package:myschool/models/mozaik.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/shared/constants.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_popup_dialog/slide_popup_dialog.dart';

class Settings extends StatefulWidget {
  final UserData user;
  Settings({this.user});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final picker = ImagePicker();

  String _mozaikAccountText = "Lier votre compte Mozaik";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.getString('access_token') != null) {
        setState(() {
          _mozaikAccountText = "Compte Mozaik lié";
        });
      }
    });
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
                          onPressed: (BuildContext context) {
                            adaptiveDialog(
                                context: context,
                                title: Text(
                                    "Voulez vous modifier votre adresse email"),
                                actions: [
                                  adaptiveDialogTextButton(context, "Non",
                                      () => Navigator.pop(context)),
                                  adaptiveDialogTextButton(context, "Oui", () {
                                    //user.updateEmail('ds');
                                    Alert(
                                            message:
                                                "Un courriel pour modifier votre adresse courriel vous a été envoyé")
                                        .show();
                                    Navigator.pop(context);
                                  }),
                                ]);
                          },
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
                            File image = await getImage(picker);
                            if (image != null) {
                              // two megabytes
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
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text("Ok"))
                                          ],
                                        ));
                              }
                              adaptiveDialog(
                                context: context,
                                title: Text(
                                    "Êtes vous sur de vouloir choisir cette photo de profil ?"),
                                content: Container(
                                    height: MediaQuery.of(context).size.height /
                                        2.4,
                                    width:
                                        MediaQuery.of(context).size.width / 1.5,
                                    child: Crop(
                                        aspectRatio: 1 / 1,
                                        key: imgCropKey,
                                        image: FileImage(image))),
                                actions: [
                                  adaptiveDialogTextButton(context, "Non",
                                      () => Navigator.pop(context)),
                                  adaptiveDialogTextButton(context, "Oui",
                                      () async {
                                    final crop = imgCropKey.currentState;
                                    final croppedImage =
                                        await ImageCrop.cropImage(
                                            file: image, area: crop.area);
                                    // Decoding image to get its dimensions
                                    final decodedImage =
                                        await decodeImageFromList(
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
                                                    () =>
                                                        Navigator.pop(context),
                                                  )
                                                ],
                                              ));
                                    }
                                    String avatarUrl = await StorageService(
                                            ref: 'users/${user.uid}/avatar.png')
                                        .uploadFile(croppedImage);
                                    await DatabaseService(uid: user.uid)
                                        .updateUserData(avatarUrl: avatarUrl);
                                    Navigator.pop(context);
                                  }),
                                ],
                              );
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
                                    ),
                                    userData.userType == UserType.student
                                        ?
                                        // If student, display his group
                                        SettingsTile(
                                            leading: Icon(Icons.group),
                                            title: userData.school.group.uid,
                                          )
                                        :
                                        // If teacher, display all the groups that the professor has
                                        SettingsTile(
                                            leading: Icon(Icons.group),
                                            title: userData.groups.join(', '),
                                          ),
                                  ],
                                );
                              } else {
                                return SettingsSection(
                                  title: 'École',
                                  tiles: [
                                    SettingsTile(
                                      leading:
                                          CircularProgressIndicator.adaptive(),
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
                          leading: Icon(Icons.account_tree),
                          title: _mozaikAccountText,
                          onPressed:
                              /*_mozaikAccountText.contains("Lier")
                              ? */
                              (context) => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MozaikLogin()))
                          /*: null*/,
                        ),
                        SettingsTile(
                          leading: Icon(Icons.delete_forever),
                          title: "Supprimer votre compte",
                          subtitle: "Cette action est irréversible!",
                          onPressed: (context) {
                            adaptiveDialog(
                                context: context,
                                content: Text(
                                    "Voulez vous vraiment supprimer votre compte?"),
                                actions: [
                                  adaptiveDialogTextButton(context, "Non",
                                      () => Navigator.pop(context)),
                                  adaptiveDialogTextButton(
                                    context,
                                    "Oui",
                                    () async {
                                      bool deleted =
                                          await FirebaseAuthService.deleteUser(
                                              user);
                                      Navigator.pop(context);
                                      if (!deleted) {
                                        adaptiveDialog(
                                          context: context,
                                          content: Text(
                                              "Cette action est sensible et requiert que vous vous ré-authentifier, Déconnectez et reconnectez vous pour procéder."),
                                          actions: [
                                            adaptiveDialogTextButton(
                                              context,
                                              "Ok",
                                              () => Navigator.pop(context),
                                            )
                                          ],
                                        );
                                      }
                                    },
                                  )
                                ]);
                          },
                        )
                      ],
                    )
                  ],
                );
              } else {
                return Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
            }));
  }
}
