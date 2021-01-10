import 'package:alert/alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myschool/models/user.dart';
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
    Home(user: userData),
    Announcements(user: userData),
    Calendar(user: userData)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
                    DrawerHeader(
                      child: Text(
                        'Bonjour, ${userData.firstName}',
                        style: TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Text('Parametres'),
                      trailing: Icon(Icons.settings),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Text('Deconnexion'),
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
