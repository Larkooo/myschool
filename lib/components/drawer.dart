import 'package:alert/alert.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/components/new_homework.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/settings.dart';
import 'package:myschool/shared/constants.dart';

class DrawerComp extends StatefulWidget {
  final UserData userData;
  DrawerComp({this.userData});

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
                                        child: widget.userData.avatarUrl != null
                                            // Caching the image so we dont have to request it everytime the app is reloaded
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    widget.userData.avatarUrl,
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
                                  'Bonjour, ${widget.userData.firstName}',
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
                              Text("meow"),
                          ]))))),
          if (widget.userData.type == UserType.teacher)
            ListTile(
              leading: Text('Publier une annonce'),
              trailing: Icon(Icons.announcement_outlined),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NewAnnounce()));
              },
            ),
          if (widget.userData.type == UserType.teacher)
            ListTile(
              leading: Text('Envoyer un devoir'),
              trailing: Icon(Icons.calculate_outlined),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NewHomework()));
              },
            ),
          if (widget.userData.type == UserType.teacher) Divider(),
          ListTile(
            leading: Text('Paramètres'),
            trailing: Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Settings()));
            },
          ),
          ListTile(
            leading: Text('Déconnexion'),
            trailing: Icon(Icons.logout),
            onTap: () {
              adaptiveDialog(
                  context: context,
                  title: Text('Voulez-vous vraiment vous déconnecter?'),
                  actions: [
                    adaptiveDialogTextButton(
                        context, 'Non', () => Navigator.pop(context)),
                    adaptiveDialogTextButton(context, 'Oui', () {
                      FirebaseAuth.instance.signOut().then((_) {
                        Navigator.pop(context);
                        Alert(message: "Déconnecté").show();
                      },
                          onError: (err) =>
                              Alert(message: 'Une erreur est survenue').show());
                    }),
                  ]);
            },
          ),
        ],
      ),
    );
  }
}
