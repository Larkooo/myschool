import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/resetPassword.dart';
import 'package:myschool/models/school.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase.dart';
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
