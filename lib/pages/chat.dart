import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/group.dart';
import 'package:myschool/models/message.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:myschool/shared/constants.dart';
import 'package:dart_date/dart_date.dart';

class ChatPage extends StatefulWidget {
  final UserData user;
  final String groupUid;
  ChatPage({this.user, this.groupUid});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        body: Column(children: [
          Expanded(
              child: StreamBuilder(
                  stream: DatabaseService(uid: widget.user.school.uid)
                      .group(widget.groupUid ?? widget.user.school.group.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      SchedulerBinding.instance.scheduleFrameCallback((_) {
                        _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: Duration(seconds: 1),
                            curve: Curves.fastLinearToSlowEaseIn);
                      });
                      Group group = snapshot.data;
                      return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(top: 10),
                          itemCount: group.messages.length,
                          itemBuilder: (context, index) {
                            Message message = group.messages[index];
                            int diffInDaysNow = message.createdAt
                                .differenceInDays(DateTime.now());
                            return Column(
                                crossAxisAlignment:
                                    message.author.id == widget.user.uid
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width /
                                                1.5,
                                      ),
                                      padding: EdgeInsets.all(5),
                                      margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
                                      decoration: BoxDecoration(
                                          color: Colors.blue[700],
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Text(
                                        message.content,
                                        style: TextStyle(fontSize: 17),
                                      )),
                                  Row(
                                      mainAxisAlignment:
                                          message.author.id == widget.user.uid
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                80),
                                        CacheManagerMemory.cachedUsers[
                                                    message.author] ==
                                                null
                                            ? FutureBuilder(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('users')
                                                    .doc(message.author.id
                                                        .toString())
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    UserData author;
                                                    if (snapshot.data.exists) {
                                                      author = DatabaseService()
                                                          .userDataFromSnapshot(
                                                              snapshot.data);
                                                      // cache the user by its id
                                                      CacheManagerMemory
                                                                  .cachedUsers[
                                                              message.author.id
                                                                  .toString()] =
                                                          author;
                                                    } else {
                                                      author =
                                                          UserData(uid: "-1");
                                                    }

                                                    return userLeadingHorizontal(
                                                        author, 0.7);
                                                  } else {
                                                    return CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    );
                                                  }
                                                })
                                            : userLeadingHorizontal(
                                                CacheManagerMemory.cachedUsers[
                                                    message.author],
                                                0.7),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          (diffInDaysNow == 0
                                                  ? "Aujourd'hui"
                                                  : diffInDaysNow == -1
                                                      ? "Hier"
                                                      : diffInDaysNow == -2
                                                          ? "Avant-hier"
                                                          : DateFormat
                                                                  .yMMMMEEEEd()
                                                              .format(message
                                                                  .createdAt)) +
                                              " à " +
                                              DateFormat.Hm()
                                                  .format(message.createdAt),
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12),
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                80),
                                      ])
                                ]);
                          });
                    } else {
                      return CircularProgressIndicator.adaptive();
                    }
                  })),
          Container(
              //color: Colors.grey[800],
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: PlatformTextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        cupertino: (context, platform) =>
                            CupertinoTextFieldData(placeholder: 'Message'),
                        onSubmitted: (value) async {
                          if (value.length > 0) {
                            await DatabaseService(uid: widget.user.school.uid)
                                .sendMessage(value, widget.user,
                                    widget.user.school.group.uid);
                            _messageController.clear();
                          }
                        },
                      )),
                  IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () async {
                        if (_messageController.text != null &&
                            _messageController.text.length > 0) {
                          await DatabaseService(uid: widget.user.school.uid)
                              .sendMessage(_messageController.text, widget.user,
                                  widget.user.school.group.uid);
                          _messageController.clear();
                        }
                      })
                ],
              ))
        ]));
  }
}
