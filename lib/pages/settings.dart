import 'dart:io';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:alert/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_crop_new/image_crop_new.dart';
import 'package:image_picker/image_picker.dart';
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

  //String _mozaikAccountText = "Lier votre compte Mozaik";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //SharedPreferences.getInstance().then((prefs) {
    //  if (prefs.getString('access_token') != null) {
    //    setState(() {
    //      _mozaikAccountText = "Compte Mozaik lié";
    //    });
    //  }
    //});
  }

  TextEditingController _newEmail = TextEditingController();
  bool _newEmailValid = false;

  final imgCropKey = GlobalKey<CropState>();

  int count = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Scaffold(
        appBar: AppBar(),
        body: SettingsList(
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
                  subtitle: widget.user.firstName,
                ),
                SettingsTile(
                  leading: Icon(Icons.person),
                  title: 'Nom de famille',
                  subtitle: widget.user.lastName,
                ),
                SettingsTile(
                    leading: Icon(Icons.email),
                    title: 'Courriel',
                    subtitle: user.email,
                    onPressed: (context) {
                      showTextInputDialog(
                          context: context,
                          title: 'Modifier votre courriel',
                          okLabel: 'Confirmer',
                          cancelLabel: 'Annuler',
                          textFields: [
                            DialogTextField(
                              hintText: 'Mot de passe',
                              obscureText: true,
                              validator: (value) {
                                if (value.isEmpty)
                                  return 'Ce champs est obligatoire.';
                                return null;
                              },
                            ),
                            DialogTextField(
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'example@domain.com',
                              validator: (value) {
                                value = value.trim();
                                if (value.isEmpty)
                                  return 'Ce champs est obligatoire.';
                                bool v = EmailValidator.validate(value);
                                if (!v) {
                                  return "Adresse courriel invalide.";
                                }
                                return null;
                              },
                            )
                          ]).then((inputs) {
                        String currentPassword = inputs[0];
                        String email = inputs[1].trim();
                        FirebaseAuth.instance.currentUser
                            .reauthenticateWithCredential(
                                EmailAuthProvider.credential(
                                    email: user.email,
                                    password: currentPassword))
                            .then((_) {
                          user.updateEmail(email).catchError(
                              (err) => Alert(message: "Email invalide").show);
                        }, onError: (err) {
                          Alert(message: "Mot de passe invalide").show();
                        });
                      });
                    }),
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
                                  title: Text("Taille de l'image trop grosse"),
                                  content: Text(
                                      "La taille de votre image doit faire au maximum 2 mégaoctets"),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Ok"))
                                  ],
                                ));
                      }
                      adaptiveDialog(
                        context: context,
                        title: Text(
                            "Êtes vous sur de vouloir choisir cette photo de profil ?"),
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
                    stream: DatabaseService(uid: widget.user.school.uid).school,
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
                            widget.user.type == UserType.student
                                ?
                                // If student, display his group
                                SettingsTile(
                                    leading: Icon(Icons.group),
                                    title: widget.user.school.group.uid,
                                  )
                                :
                                // If teacher, display all the groups that the professor has
                                SettingsTile(
                                    leading: Icon(Icons.group),
                                    title: widget.user.groups.join(', '),
                                  ),
                          ],
                        );
                      } else {
                        return SettingsSection(
                          title: 'École',
                          tiles: [
                            SettingsTile(
                              leading: CircularProgressIndicator.adaptive(),
                              title: "Mhh quelque chose semble être cassé!",
                            ),
                          ],
                        );
                      }
                    })),
            CustomSection(
                child: SizedBox(
              height: 10,
            )),
            SettingsSection(title: "Sécurité", tiles: [
              SettingsTile(
                  leading: Icon(Icons.security),
                  title: 'Modifier votre mot de passe',
                  onPressed: (context) => showTextInputDialog(
                          context: context,
                          title: 'Modifier votre mot de passe',
                          okLabel: 'Confirmer',
                          cancelLabel: 'Annuler',
                          textFields: [
                            DialogTextField(
                              hintText: 'Mot de passe actuel',
                              obscureText: true,
                              validator: (value) {
                                if (value.isEmpty)
                                  return 'Ce champs est obligatoire.';
                                if (value.length < 6)
                                  return 'Mot de passe trop court.';
                                return null;
                              },
                            ),
                            DialogTextField(
                                hintText: 'Nouveau mot de passe',
                                obscureText: true,
                                validator: (value) {
                                  if (value.isEmpty)
                                    return 'Ce champs est obligatoire.';
                                  if (value.length < 6)
                                    return 'Mot de passe trop court.';
                                  return null;
                                })
                          ]).then((inputs) {
                        String currentPassword = inputs[0];
                        String newPassword = inputs[1];
                        if (currentPassword != newPassword) {
                          user
                              .reauthenticateWithCredential(
                                  EmailAuthProvider.credential(
                                      email: user.email,
                                      password: currentPassword))
                              .then((value) {
                            user.updatePassword(newPassword).then((_) {
                              Alert(message: "Mot de passe modifié").show();
                            }, onError: (err) {
                              if (err.code == 'weak-password')
                                Alert(message: "Mot de passe trop fragile")
                                    .show();
                            });
                          }, onError: (err) {
                            Alert(message: "Mot de passe invalide").show();
                          });
                        } else {
                          Alert(message: "Choisissez un autre mot de passe")
                              .show();
                        }
                      })
                  //subtitle: user.email,
                  )
            ]),
            CustomSection(
                child: SizedBox(
              height: 10,
            )),
            SettingsSection(
              title: "Compte",
              tiles: [
                //SettingsTile(
                //  leading: Icon(Icons.account_tree),
                //  title: _mozaikAccountText,
                //  onPressed:
                //      /*_mozaikAccountText.contains("Lier")
                //      ? */
                //      (context) => Navigator.push(
                //          context,
                //          MaterialPageRoute(
                //              builder: (context) => MozaikLogin()))
                //  /*: null*/,
                //),
                SettingsTile(
                  leading: Icon(Icons.delete_forever),
                  title: "Supprimer votre compte",
                  subtitle: "Cette action est irréversible!",
                  onPressed: (context) {
                    showTextInputDialog(
                        context: context,
                        title: 'Compte',
                        message: 'Voulez vous vraiment supprimer votre compte?',
                        okLabel: 'Supprimer',
                        cancelLabel: 'Annuler',
                        textFields: [
                          DialogTextField(
                              hintText: 'Mot de passe',
                              obscureText: true,
                              validator: (value) {
                                if (value.isEmpty)
                                  return 'Ce champs est obligatoire.';
                                if (value.length < 6)
                                  return 'Mot de passe trop court.';
                                return null;
                              })
                        ]).then((inputs) {
                      String currentPassword = inputs[0];
                      user
                          .reauthenticateWithCredential(
                              EmailAuthProvider.credential(
                                  email: user.email, password: currentPassword))
                          .then((_) => FirebaseAuthService.deleteUser(user)
                                  .then((value) {
                                value
                                    ? Alert(message: 'Compte supprimé').show()
                                    : Alert(message: 'Erreur');
                              }))
                          .onError((error, stackTrace) =>
                              Alert(message: 'Erreur').show());
                      FirebaseAuthService.deleteUser(user).then((value) {
                        value
                            ? Alert(message: 'Compte supprimé').show()
                            : Alert(message: 'Erreur');
                      });
                    });
                  },
                )
              ],
            )
          ],
        ));
  }
}
