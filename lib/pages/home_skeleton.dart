import 'dart:io';

import 'package:alert/alert.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myschool/components/drawer.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/settings.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/services/firebase_auth_service.dart';
import 'package:myschool/shared/constants.dart';
import 'home.dart';
import 'calendar.dart';
import 'announcements.dart';
import 'package:provider/provider.dart';
import '../pages/teacher/groups.dart';

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


  // Student
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

  // Teacher
  int _selectedIndexT = 0;
  static List<Widget> _widgetOptionsT = <Widget>[
  ];

  void _onItemTappedT(int index) {
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
            // Student pages
            return userData.userType == UserType.student
                ? Scaffold(
                    appBar: AppBar(),
                    drawer: DrawerComp(
                      userData: userData,
                    ),
                    body: _widgetOptions.elementAt(_selectedIndex),
                    bottomNavigationBar: adaptativeBottomNavBar(
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                            icon: Icon(Platform.isIOS
                                ? CupertinoIcons.home
                                : Icons.home),
                            label: "Accueil"),
                        BottomNavigationBarItem(
                            icon: Icon(Platform.isIOS
                                ? CupertinoIcons.news
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
                  )
                : // Teacher
                Scaffold(
                    appBar: AppBar(),
                    drawer: DrawerComp(
                      userData: userData,
                    ),
                    body: Center(
                        child: TextButton(
                      child: Text("delete"),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Groups())),
                    )));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
