import 'dart:io';

import 'package:alert/alert.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/settings.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/constants.dart';
import 'home.dart';
import 'calendar.dart';
import 'announcements.dart';
import 'package:provider/provider.dart';

class HomeSkeleton extends StatefulWidget {
  final UserData user;
  HomeSkeleton({this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeSkeleton> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //showSlideDialog(context: context, child: Text("Testing welcome message"));
  }

  static UserData userData;

  int _selectedIndex = 0;
  static List<Widget> _widgetOptions = <Widget>[
    Home(),
    Announcements(),
    Calendar()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  double drawerExpandedHeight = 120;
  double drawerClosedHeight = 85;

  bool drawerStartedAnimation = false;
  bool drawerExpanded = false;

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: firebaseUser.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            userData = snapshot.data;
            return Scaffold(
              appBar: AppBar(),
              drawer: Drawer(
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
                                    drawerStartedAnimation =
                                        !drawerStartedAnimation;
                                  });
                                },
                                child: DrawerHeader(
                                    child: Column(
                                        //mainAxisAlignment:
                                        //    MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey[800],
                                                  child: userData.avatarUrl !=
                                                          null
                                                      // Caching the image so we dont have to request it everytime the app is reloaded
                                                      ? CachedNetworkImage(
                                                          imageUrl: userData
                                                              .avatarUrl,
                                                          progressIndicatorBuilder: (context,
                                                                  url,
                                                                  downloadProgress) =>
                                                              CircularProgressIndicator(
                                                                  value: downloadProgress
                                                                      .progress),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                          height: 50,
                                                          width: 50,
                                                        )
                                                      : Icon(
                                                          Icons.person,
                                                          size: 30,
                                                        ))),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                35,
                                          ),
                                          Text(
                                            'Bonjour, ${userData.firstName}',
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
                                          (drawerExpanded &&
                                              drawerStartedAnimation))
                                        Text("meow"),
                                    ]))))),
                    ListTile(
                      leading: Text('Paramètres'),
                      trailing: Icon(Icons.settings),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Settings()));
                      },
                    ),
                    ListTile(
                      leading: Text('Déconnexion'),
                      trailing: Icon(Icons.logout),
                      onTap: () {
                        FirebaseAuth.instance.signOut();
                        Alert(message: "Déconnecté").show();
                      },
                    ),
                  ],
                ),
              ),
              body: _widgetOptions.elementAt(_selectedIndex),
              bottomNavigationBar: adaptativeBottomNavBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                      icon: Icon(
                          Platform.isIOS ? CupertinoIcons.home : Icons.home),
                      label: "Accueil"),
                  BottomNavigationBarItem(
                      icon: Icon(Platform.isIOS
                          ? CupertinoIcons.speaker
                          : Icons.announcement),
                      label: "Annonces"),
                  BottomNavigationBarItem(
                      icon: Icon(Platform.isIOS
                          ? CupertinoIcons.calendar
                          : Icons.calendar_today),
                      label: "Calendrier")
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
