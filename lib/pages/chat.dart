import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:clipboard/clipboard.dart';
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
// ignore: implementation_imports
import 'package:adaptive_dialog/src/modal_action_sheet/material_modal_action_sheet.dart';

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

  bool scrolled = false;

  String _actualGroup;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _actualGroup = widget.groupUid ?? widget.user.school.group.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: widget.groupUid != null
            ? AppBar(title: Text('Chat de groupe'))
            : null,
        body: Column(children: [
          Expanded(
              child: SingleChildScrollView(
                  controller: _scrollController,
                  child: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: StreamBuilder(
                          stream: DatabaseService(uid: widget.user.school.uid)
                              .groupMessages(_actualGroup),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              if (!scrolled) {
                                SchedulerBinding.instance
                                    .scheduleFrameCallback((_) {
                                  _scrollController.animateTo(
                                      _scrollController
                                          .position.maxScrollExtent,
                                      duration: Duration(seconds: 1),
                                      curve: Curves.fastLinearToSlowEaseIn);
                                });
                                scrolled = true;
                              }
                              List<Message> messages =
                                  (snapshot.data as QuerySnapshot)
                                      .docs
                                      .map(DatabaseService.messageFromSnapshot)
                                      .toList();
                              return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.only(top: 10),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    Message message = messages[index];
                                    int diffInDaysNow = message.createdAt
                                        .differenceInDays(DateTime.now());
                                    return Column(
                                        crossAxisAlignment:
                                            message.author.id == widget.user.uid
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                        children: [
                                          Platform.isIOS
                                              ? CupertinoContextMenu(
                                                  actions: [
                                                      CupertinoContextMenuAction(
                                                        trailingIcon:
                                                            Icons.copy,
                                                        child: Text("Copier",
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            )),
                                                        onPressed: () {
                                                          FlutterClipboard.copy(
                                                                  message
                                                                      .content)
                                                              .then((_) {
                                                            Navigator.pop(
                                                                context);
                                                          });
                                                        },
                                                      ),
                                                      if (message.author.id ==
                                                              widget.user.uid ||
                                                          widget.user.type ==
                                                              UserType.teacher)
                                                        CupertinoContextMenuAction(
                                                            trailingIcon:
                                                                Icons.delete,
                                                            child: Text(
                                                              'Supprimer',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .red),
                                                            ))
                                                    ],
                                                  child: Material(
                                                      color: Colors.transparent,
                                                      child: Container(
                                                          constraints:
                                                              BoxConstraints(
                                                            maxWidth: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                1.5,
                                                          ),
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          margin: EdgeInsets.fromLTRB(
                                                              5, 5, 5, 5),
                                                          decoration: BoxDecoration(
                                                              color: Colors
                                                                  .blue[700],
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      10)),
                                                          child: Text(
                                                            message.content,
                                                            style: TextStyle(
                                                                fontSize: 17),
                                                          ))))
                                              : GestureDetector(
                                                  onLongPress: () async => message
                                                                  .author.id ==
                                                              widget.user.uid ||
                                                          widget.user.type ==
                                                              UserType.teacher
                                                      ? showModalActionSheet<OkCancelResult>(
                                                          context: context,
                                                          title: 'Message',
                                                          message: 'Voulez-vous supprimer ce message?',
                                                          cancelLabel: 'Annuler',
                                                          actions: [SheetAction(key: OkCancelResult.ok, label: 'Supprimer')]).then((value) => value == OkCancelResult.ok ? DatabaseService.deleteMessage(message.reference) : null)
                                                      : null,
                                                  child: Container(
                                                      constraints: BoxConstraints(
                                                        maxWidth: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            1.5,
                                                      ),
                                                      padding: EdgeInsets.all(5),
                                                      margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
                                                      decoration: BoxDecoration(color: Colors.blue[700], borderRadius: BorderRadius.circular(10)),
                                                      child: Text(
                                                        message.content,
                                                        style: TextStyle(
                                                            fontSize: 17),
                                                      ))),
                                          Row(
                                              mainAxisAlignment:
                                                  message.author.id ==
                                                          widget.user.uid
                                                      ? MainAxisAlignment.end
                                                      : MainAxisAlignment.start,
                                              children: [
                                                if (index ==
                                                        messages.length - 1 ||
                                                    (messages[index + 1]
                                                            .author
                                                            .id !=
                                                        message.author.id))
                                                  SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              80),
                                                if (index == messages.length - 1 ||
                                                    (messages[index + 1]
                                                            .author
                                                            .id !=
                                                        message.author.id))
                                                  CacheManagerMemory.cachedUsers[
                                                              message
                                                                  .author.id] ==
                                                          null
                                                      ? FutureBuilder(
                                                          future: FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'users')
                                                              .doc(message
                                                                  .author.id
                                                                  .toString())
                                                              .get(),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (snapshot
                                                                .hasData) {
                                                              UserData author;
                                                              if (snapshot.data
                                                                  .exists) {
                                                                author = DatabaseService()
                                                                    .userDataFromSnapshot(
                                                                        snapshot
                                                                            .data);
                                                                // cache the user by its id
                                                                CacheManagerMemory
                                                                        .cachedUsers[
                                                                    message
                                                                        .author
                                                                        .id
                                                                        .toString()] = author;
                                                              } else {
                                                                author = UserData(
                                                                    uid: "-1");
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
                                                          CacheManagerMemory
                                                              .cachedUsers[message.author.id],
                                                          0.7),
                                                SizedBox(
                                                  width: 5,
                                                ),
                                                if (index != 0 &&
                                                    message.createdAt
                                                            .differenceInMinutes(
                                                                messages[index -
                                                                        1]
                                                                    .createdAt) >
                                                        5)
                                                  Text(
                                                    (diffInDaysNow == 0
                                                            ? "Aujourd'hui"
                                                            : diffInDaysNow ==
                                                                    -1
                                                                ? "Hier"
                                                                : diffInDaysNow ==
                                                                        -2
                                                                    ? "Avant-hier"
                                                                    : DateFormat
                                                                            .yMMMMEEEEd()
                                                                        .format(message
                                                                            .createdAt)) +
                                                        " à " +
                                                        DateFormat.Hm().format(
                                                            message.createdAt),
                                                    style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 12),
                                                  ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            80),
                                              ])
                                        ]);
                                  });
                            } else {
                              return CircularProgressIndicator.adaptive();
                            }
                          })))),
          Container(
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
                        material: (context, platform) => MaterialTextFieldData(
                            decoration: InputDecoration(hintText: 'Message')),
                        onSubmitted: (value) async {
                          if (value.length > 0) {
                            await DatabaseService(uid: widget.user.school.uid)
                                .sendMessage(value, widget.user, _actualGroup);
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
                                  _actualGroup);
                          _messageController.clear();
                        }
                        FocusScope.of(context).unfocus();
                      })
                ],
              ))
        ]));
  }
}
