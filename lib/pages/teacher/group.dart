import 'package:flutter/material.dart';
import 'package:myschool/components/new_announce.dart';
import 'package:myschool/shared/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupPage extends StatefulWidget {
  final String group;
  GroupPage({this.group});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  TextEditingController _groupAliasController = TextEditingController();
  //String groupAlias;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    LocalStorage.getGroupAlias(widget.group).then((value) {
      print(value);
      setState(() {
        _groupAliasController.text = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body:
          /*FutureBuilder(
        future: Firebase,
        builder: (context, snapshot) {},)*/
          Center(
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 50),
          Container(
            width: MediaQuery.of(context).size.height / 7,
            height: MediaQuery.of(context).size.height / 7,
            child: Center(
                child: Text(
              widget.group,
              style: TextStyle(fontSize: 20),
            )),
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Colors.grey[800]),
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _groupAliasController.text != null
                    ? _groupAliasController.text
                    : 'Groupe ' + widget.group,
                style: TextStyle(fontSize: 20),
              ),
              IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                            title: Text('Alias'),
                            actions: [
                              TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Annuler')),
                              TextButton(
                                  onPressed: () async {
                                    if (_groupAliasController.text.length < 1)
                                      return;
                                    await LocalStorage.setGroupAlias(
                                        widget.group,
                                        _groupAliasController.text);
                                    setState(() {
                                      _groupAliasController.text;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text('Ok')),
                            ],
                            content: TextField(
                              controller: _groupAliasController,
                              maxLength: 50,
                              onSubmitted: (value) async {
                                await LocalStorage.setGroupAlias(
                                    widget.group, value);
                              },
                            )));
                  },
                  iconSize: 20),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 40),
          Container(
              width: MediaQuery.of(context).size.width / 1.1,
              child: Card(
                  color: Colors.grey[800],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Actions',
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      Container(
                          width: MediaQuery.of(context).size.width / 1.2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        NewAnnounce(group: widget.group))),
                            child: Text('Publier une annonce'),
                            style: ButtonStyle(),
                          )),
                      SizedBox(
                        height: 5,
                      ),
                    ],
                  ))),
          SizedBox(height: MediaQuery.of(context).size.height / 40),
          Container(
              width: MediaQuery.of(context).size.width / 1.1,
              child: Card(
                  color: Colors.grey[800],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Informations',
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                    ],
                  ))),
        ],
      )),
    );
  }
}
