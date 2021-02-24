import 'package:flutter/material.dart';
import '../models/announcement.dart';

class AnnouncePage extends StatelessWidget {
  final Announcement announcement;
  AnnouncePage({this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(),body: Column(children: [
      Text(announcement.title, style: TextStyle(fontSize: 50),),
      SizedBox(height: 20,),
      Text(announcement.content, style: TextStyle(fontSize: 20, color: Colors.grey[700]))
    ],),);
  }
} 