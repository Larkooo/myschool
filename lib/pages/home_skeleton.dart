import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:myschool/components/drawer.dart';
import 'package:myschool/models/homework.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/chat.dart';
import 'package:myschool/pages/homeworks.dart';
import 'package:myschool/pages/settings.dart';
import 'package:myschool/pages/teacher/home.dart';
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
  final Type initialPage;
  HomeSkeleton({this.user, this.initialPage});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeSkeleton> {
  int _selectedIndex = 0;

  static UserData userData;

  static Map<UserType, List<Widget>> _widgetOptions = {
    UserType.student: [
      Home(),
      Announcements(),
      Homeworks(),
      Calendar(),
      ChatPage()
    ],
    UserType.teacher: [HomeTeacher(), Announcements(), Homeworks(), Groups()]
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  double drawerExpandedHeight = 120;
  double drawerClosedHeight = 85;

  bool drawerStartedAnimation = false;
  bool drawerExpanded = false;

  FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool subscribed = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //showSlideDialog(context: context, child: Text("Testing welcome message"));
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User>();
    return StreamBuilder(
        stream: DatabaseService(uid: firebaseUser.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            userData = snapshot.data;

            _widgetOptions = {
              UserType.student: [
                Home(user: userData),
                Announcements(user: userData),
                Homeworks(user: userData),
                Calendar(user: userData),
                ChatPage(user: userData)
              ],
              UserType.teacher: [
                HomeTeacher(user: userData),
                Announcements(user: userData),
                Homeworks(user: userData),
                Groups(user: userData)
              ]
            };

            // subscribe to school topic
            if (!subscribed) _messaging.subscribeToTopic(userData.school.uid);

            if (userData.type == UserType.student) {
              // Student

              // subscribe to group topic
              if (!subscribed) {
                _messaging.subscribeToTopic(
                    userData.school.uid + '-' + userData.school.group.uid);
                subscribed = true;
              }

              return Scaffold(
                appBar: AppBar(),
                drawer: DrawerComp(
                  user: userData,
                ),
                body:
                    _widgetOptions[UserType.student].elementAt(_selectedIndex),
                bottomNavigationBar: adaptiveBottomNavBar(
                  items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                        icon: Icon(
                            Platform.isIOS ? CupertinoIcons.home : Icons.home),
                        label: "Accueil"),
                    BottomNavigationBarItem(
                        icon: Icon(Platform.isIOS
                            ? CupertinoIcons.news
                            : Icons.announcement),
                        label: "Annonces"),
                    BottomNavigationBarItem(
                        icon: Icon(Platform.isIOS
                            ? CupertinoIcons.plus_slash_minus
                            : Icons.calculate),
                        label: "Devoirs"),
                    BottomNavigationBarItem(
                        icon: Icon(Platform.isIOS
                            ? CupertinoIcons.calendar
                            : Icons.calendar_today),
                        label: "Calendrier"),
                    BottomNavigationBarItem(
                        icon: Icon(Platform.isIOS
                            ? CupertinoIcons.chat_bubble
                            : Icons.chat),
                        label: "Chat")
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              );
            } else {
              // Teacher

              // topic
              if (!subscribed) subscribed = true;

              return Scaffold(
                  appBar: AppBar(),
                  drawer: DrawerComp(
                    user: userData,
                  ),
                  body: _widgetOptions[UserType.teacher]
                      .elementAt(_selectedIndex),
                  bottomNavigationBar: adaptiveBottomNavBar(
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
                              ? CupertinoIcons.plus_slash_minus
                              : Icons.work),
                          label: "Devoirs"),
                      BottomNavigationBarItem(
                          icon: Icon(Platform.isIOS
                              ? CupertinoIcons.group
                              : Icons.group),
                          label: "Groupes"),
                    ],
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
                  ));
            }
          } else {
            return Center(child: CircularProgressIndicator.adaptive());
          }
        });
  }
}
