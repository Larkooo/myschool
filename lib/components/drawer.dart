import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/components/new_homework.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/settings.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/shared/constants.dart';

class DrawerComp extends StatefulWidget {
  final UserData user;
  DrawerComp({this.user});

  @override
  _DrawerCompState createState() => _DrawerCompState();
}

class _DrawerCompState extends State<DrawerComp> {
  double drawerExpandedHeight = 120;
  double drawerClosedHeight = 85;

  bool drawerStartedAnimation = false;
  bool drawerExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              onEnd: () {
                setState(() {
                  drawerExpanded = !drawerExpanded;
                });
              },
              height: drawerStartedAnimation
                  ? drawerExpandedHeight
                  : drawerClosedHeight,
              child: Material(
                  child: InkWell(
                      onTap: () {
                        setState(() {
                          drawerStartedAnimation = !drawerStartedAnimation;
                        });
                      },
                      child: DrawerHeader(
                          child: Column(
                              //mainAxisAlignment:
                              //    MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[800],
                                        child: widget.user.avatarUrl != null
                                            // Caching the image so we dont have to request it everytime the app is reloaded
                                            ? CachedNetworkImage(
                                                imageUrl: widget.user.avatarUrl,
                                                progressIndicatorBuilder: (context,
                                                        url,
                                                        downloadProgress) =>
                                                    CircularProgressIndicator
                                                        .adaptive(
                                                            value:
                                                                downloadProgress
                                                                    .progress),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(Icons.error),
                                                height: 50,
                                                width: 50,
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 30,
                                              ))),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width / 35,
                                ),
                                Text(
                                  'Bonjour, ${widget.user.firstName}',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                  ),
                                ),
                                Spacer(),
                                Icon(drawerStartedAnimation
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down)
                              ],
                            ),
                            // Basically making sure the text is "removed" before the drawer is closed
                            if (drawerExpanded &&
                                (drawerExpanded && drawerStartedAnimation))
                              //Column(
                              //  children: [
                              Center(
                                  child: Column(children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height /
                                        200),
                                Text(widget.user.lastName +
                                    ' ' +
                                    widget.user.firstName),
                                Text(widget.user.type == UserType.student
                                    ? 'Élève'
                                    : 'Enseignant')
                              ]))
                            /*StreamBuilder(
                                stream: Connectivity().onConnectivityChanged,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    ConnectivityResult state = snapshot.data;
                                    if (state != ConnectivityResult.none)
                                      return Text.rich(TextSpan(children: [
                                        WidgetSpan(
                                            child: Icon(state ==
                                                    ConnectivityResult.mobile
                                                ? Icons.network_cell
                                                : Icons.wifi)),
                                        TextSpan(text: 'Connecté')
                                      ]));
                                    return Text.rich(TextSpan(children: [
                                      WidgetSpan(child: Icon(Icons.wifi_off)),
                                      TextSpan(text: 'Déconnecté')
                                    ]));
                                  } else {
                                    return Text.rich(TextSpan(children: [
                                      WidgetSpan(child: Icon(Icons.wifi_off)),
                                      TextSpan(text: 'bop')
                                    ]));
                                  }
                                },
                              )*/
                            //if (widget.user.type == UserType.student)
                            //  Text('Groupe : ' +
                            //      widget.user.school.group.uid),
                            //],
                            //),
                          ]))))),
          if (widget.user.type == UserType.teacher)
            ListTile(
              leading: Text('Publier une annonce'),
              trailing: Icon(Icons.announcement),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NewAnnounce(
                              user: widget.user,
                            )));
              },
            ),
          if (widget.user.type == UserType.teacher)
            ListTile(
              leading: Text('Envoyer un devoir'),
              trailing: Icon(Icons.calculate),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NewHomework()));
              },
            ),
          if (widget.user.type == UserType.teacher) Divider(),
          ListTile(
              leading: Text('Donner votre avis'),
              trailing: Icon(Icons.analytics),
              onTap: () => launchURL(surveyURL)),
          ListTile(
              leading: Text('Signaler un bug'),
              trailing: Icon(Icons.bug_report),
              onTap: () => launchURL(bugReportURL)),
          Divider(),
          ListTile(
            leading: Text('Paramètres'),
            trailing: Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Settings(user: widget.user)));
            },
          ),
          ListTile(
            leading: Text('Déconnexion'),
            trailing: Icon(Icons.logout),
            onTap: () async {
              showOkCancelAlertDialog(
                      context: context,
                      okLabel: 'Oui',
                      cancelLabel: 'Non',
                      title: 'Voulez-vous vraiment vous déconnecter?')
                  .then((value) async {
                if (value == OkCancelResult.ok)
                  await FirebaseAuthService.signOut(widget.user);
              });
            },
          ),
        ],
      ),
    );
  }
}
