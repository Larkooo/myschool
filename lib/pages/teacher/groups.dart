import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/database.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';


class Groups extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return Scaffold(body:StreamBuilder(
        stream: DatabaseService(uid: user.uid).user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData userData = snapshot.data;
            print(userData);
            List<dynamic> groups = userData.groups;
            List<int> levels = [];
            groups.forEach((element) {
              // getting first char
              int level = int.parse(element.toString()[0]);
              if(!(levels.contains(level)))
                levels.add(level); 
            });
            levels.sort();
            print(levels);

            return ListView.builder(itemCount: levels.length, itemBuilder: (context, index) {
              String level = levels[index].toString();
              print(level);
              List levelGroups = groups.where((element) => element.toString()[0] == level).toList();
              print(levelGroups);
              return Column(children: [
                Text('Niveau $level', style: TextStyle(fontSize: 20),),
                SizedBox(height: 10,),
                ListView.builder(itemBuilder: (ctx, indx) {
                    return Text(levelGroups[indx].toString(),);
                }, itemCount: levelGroups.length, scrollDirection: Axis.horizontal,),
                
              ],);
            },  
            ); 
            }
            else {
              return CircularProgressIndicator();
            }}));
  }
}