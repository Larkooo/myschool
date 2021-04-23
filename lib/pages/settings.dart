import 'dart:io';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:alert/alert.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:http/http.dart';
import 'package:image_crop_new/image_crop_new.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myschool/components/mozaik_login.dart';
import 'package:myschool/components/reset_password.dart';
import 'package:myschool/components/select_groups.dart';
import 'package:myschool/models/mozaik.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/services/firebase_storage.dart';
import 'package:myschool/services/messaging.dart';
import 'package:myschool/shared/constants.dart';
import 'package:myschool/shared/local_storage.dart';
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

  bool schoolNotifications = true;
  List<String> disabledGroupsNotifications = [];

  Future<void> getNotificationsPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      schoolNotifications = prefs.getBool('schoolNotifications') ?? true;
      disabledGroupsNotifications =
          prefs.getStringList('disabledGroupsNotifications') ?? [];
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getNotificationsPreferences();
  }

  final imgCropKey = GlobalKey<CropState>();

  int count = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Scaffold(
        appBar: AppBar(title: Text("Paramètres")),
        body: SettingsList(
          darkBackgroundColor: Colors.grey[850],
          lightBackgroundColor: Colors.white,
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
                                  return 'Ce champ est obligatoire.';
                                return null;
                              },
                            ),
                            DialogTextField(
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'example@domain.com',
                              validator: (value) {
                                value = value.trim();
                                if (value.isEmpty)
                                  return 'Ce champ est obligatoire.';
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
                          user.updateEmail(email).catchError((err) =>
                              Alert(message: "Adresse courriel invalide").show);
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
                                      "La taille de votre image doit faire au maximum 2 Mo"),
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
                                onPressed: (context) => showSlideDialog(
                                      context: context,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                20,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                7,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey[800],
                                            ),
                                            child: school.avatarUrl != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                50)),
                                                    child: CachedNetworkImage(
                                                        imageUrl:
                                                            school.avatarUrl))
                                                : Center(
                                                    child: Text(
                                                    school.name,
                                                    style:
                                                        TextStyle(fontSize: 10),
                                                  )),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                30,
                                          ),
                                          Text(
                                            school.name,
                                            style: TextStyle(fontSize: 35),
                                          )
                                        ],
                                      ),
                                    )),
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
                                    onPressed: (context) => showSlideDialog(
                                        context: context,
                                        child: Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                1.8,
                                            child: SelectGroups(
                                                user: widget.user)))),
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
                                  return 'Ce champ est obligatoire.';
                                if (value.length < 6)
                                  return 'Mot de passe trop court. (min. 6 caractères)';
                                return null;
                              },
                            ),
                            DialogTextField(
                                hintText: 'Nouveau mot de passe',
                                obscureText: true,
                                validator: (value) {
                                  if (value.isEmpty)
                                    return 'Ce champ est obligatoire.';
                                  if (value.length < 6)
                                    return 'Mot de passe trop court. (min. 6 caractères)';
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
                                Alert(message: "Mot de passe trop faible")
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
                          message:
                              'Voulez-vous vraiment supprimer votre compte?',
                          okLabel: 'Supprimer',
                          cancelLabel: 'Annuler',
                          textFields: [
                            DialogTextField(
                                hintText: 'Mot de passe',
                                obscureText: true,
                                validator: (value) {
                                  if (value.isEmpty)
                                    return 'Ce champ est obligatoire.';
                                  if (value.length < 6)
                                    return 'Mot de passe trop court.';
                                  return null;
                                })
                          ]).then((inputs) {
                        String currentPassword = inputs[0];
                        user
                            .reauthenticateWithCredential(
                                EmailAuthProvider.credential(
                                    email: user.email,
                                    password: currentPassword))
                            .then((_) {
                          Navigator.pop(context);
                          FirebaseAuthService.deleteUser(user, widget.user)
                              .then((value) async {
                            if (value) {
                              Alert(message: 'Compte supprimé').show();
                            } else {
                              Alert(message: 'Une erreur est survenue!');
                            }
                          });
                        }, onError: (err) {
                          Alert(message: 'Une erreur est survenue!').show();
                        });
                      });
                    })
              ],
            ),
            SettingsSection(title: "Application", tiles: [
              SettingsTile.switchTile(
                  leading: Icon(Icons.nightlight_round),
                  title: 'Mode sombre',
                  onToggle: (v) async {
                    themeNotifier.value == ThemeMode.dark
                        ? themeNotifier.value = ThemeMode.light
                        : themeNotifier.value = ThemeMode.dark;

                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setBool('darkMode', v);
                  },
                  switchValue: themeNotifier.value == ThemeMode.dark),
              SettingsTile.switchTile(
                  leading: Icon(Icons.notification_important),
                  title: "Notifications de l\'école",
                  onToggle: (v) async {
                    if (!v) {
                      bool unsubscribed =
                          !(await MessagingService.unsubscribeFromSchool(
                              widget.user.school.uid));
                      setState(() {
                        schoolNotifications = unsubscribed;
                      });
                    } else {
                      bool subscribed =
                          await MessagingService.subscribeToSchool(
                              widget.user.school.uid);
                      setState(() {
                        schoolNotifications = subscribed;
                      });
                    }
                  },
                  switchValue: schoolNotifications),
              if (widget.user.type == UserType.student)
                SettingsTile.switchTile(
                    leading: Icon(Icons.notifications),
                    title: "Notifications de groupe (" +
                        widget.user.school.group.uid +
                        ")",
                    onToggle: (v) async {
                      List<String> r = v
                          ? await MessagingService.subscribeToGroup(
                              widget.user.school.uid,
                              widget.user.school.group.uid)
                          : await MessagingService.unsubscribeFromGroup(
                              widget.user.school.uid,
                              widget.user.school.group.uid);
                      print(r);
                      setState(() {
                        disabledGroupsNotifications = r;
                      });
                    },
                    switchValue: !(disabledGroupsNotifications
                        .contains(widget.user.school.group.uid))),
              SettingsTile(
                leading: Icon(Icons.copyright),
                title: 'À propos',
                onPressed: (context) => showPlatformDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (context) => Container(
                        child: PlatformAlertDialog(
                            title: Text('MonÉcole'),
                            content: Container(
                              constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height / 3.8),
                              child: Column(
                                children: [
                                  Text(
                                    'Développement par Nasr AA Djeghmoum',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height /
                                        100,
                                  ),
                                  Text(
                                    'Illustrations par Samy Benachour & Maxime Vincent',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height / 30,
                                  ),
                                  Text('Besoin de support?'),
                                  RichText(
                                      text: TextSpan(
                                          style: TextStyle(fontSize: 10),
                                          children: [
                                        TextSpan(text: 'Contactez nous sur '),
                                        TextSpan(
                                            text: 'support@monecole.app',
                                            style: TextStyle(
                                                color: Colors.lightBlue),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => null),
                                      ])),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height / 30,
                                  ),
                                  RichText(
                                      text: TextSpan(children: [
                                    TextSpan(text: 'MonÉcole est '),
                                    TextSpan(
                                        text: 'open-source',
                                        style:
                                            TextStyle(color: Colors.lightBlue),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => launchURL(
                                              'https://github.com/Larkooo/myschool'))
                                  ])),
                                  PlatformButton(
                                      child: Text('Voir les licences'),
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => LicensePage(
                                                    applicationName: 'MonÉcole',
                                                    applicationIcon:
                                                        Image.asset(
                                                      'assets/logo.png',
                                                      scale: 5,
                                                    ),
                                                  ))))
                                ],
                              ),
                              /* actions: [
                            PlatformDialogAction(
                                child: Text('Voir les licenses')),
                            PlatformDialogAction(child: Text('Ok')),
                          ],*/
                            )))),
              )
            ]),
          ],
        ));
  }
}
