import 'package:alert/alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/settings.dart';
import 'package:myschool/services/database.dart';
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
                        height: drawerStartedAnimation ? 120 : 65,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Bonjour, ${userData.firstName}',
                                            style: TextStyle(
                                              fontSize: 20.0,
                                            ),
                                          ),
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
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: "Accueil"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.announcement), label: "Annonces"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today), label: "Calendrier")
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
