import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:dart_date/dart_date.dart';

enum Scope { school, group }
enum UserType { student, teacher }
enum CodeType { student, staff }
enum AuthCodes {
  ok,
  accountNotFound,
  badPassword,
  error,
  emailAlreadyUsed,
  codeNotFound,
  passwordResetCodeExpired,
  passwordResetCodeInvalid,
  accountDisabled
}

const Map<int, UserType> userTypeDefinitions = {
  0: UserType.student,
  1: UserType.teacher,
  2: UserType.student
};

Widget adaptiveDialog(
    {BuildContext context,
    Widget title,
    Widget content,
    List<Widget> actions}) {
  showDialog(
      context: context,
      builder: (context) {
        if (Platform.isIOS) {
          return CupertinoAlertDialog(
            title: title,
            content: content,
            actions: actions,
          );
        }
        return AlertDialog(
          title: title,
          content: content,
          actions: actions,
        );
      });
}

// Get the next apparition of a course
dynamic getNextCourse(
    DateTime last, String courseId, Map<DateTime, dynamic> events) {
  for (final element in events.entries) {
    if (element.key > last && element.value['codeActivite'] == courseId) {
      return element;
    }
  }
}

String timeCountdownFormat(DateTime start, DateTime end) {
  int diffMinutes = start.difference(end).inMinutes;
  if ((diffMinutes / 60) > 24) {
    return "Dans ${((diffMinutes / 60) / 24).round()} jour(s)";
  } else if (diffMinutes > 60) {
    return "Dans ${(diffMinutes / 60).round()} heure(s)";
  } else {
    return "Dans ${diffMinutes.round()} minute(s)";
  }
}

String dayIsHome() =>
    CacheManagerMemory.dayIsHome ? "À la maison" : "À l'école";

// Not used anymore (for now)
final BoxDecoration mainBlueBtnDec =
    BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.blue);

TextButton textButton(BuildContext context, String text, Function onPressed) {
  return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
          overlayColor:
              MaterialStateColor.resolveWith((states) => Colors.transparent)),
      child:
          Text(text, style: TextStyle(color: Colors.blue[400], fontSize: 13)));
}

TextButton adaptativeDialogTextButton(
    BuildContext context, String text, Function onPressed) {
  if (Platform.isIOS) {
    return textButton(context, text, onPressed);
  }
  return TextButton(child: Text(text), onPressed: onPressed);
}

Widget adaptativeAppBar({String title, Widget leading}) {
  if (Platform.isIOS) {
    return CupertinoNavigationBar(middle: Text(title), leading: leading);
  }
  return AppBar(title: Text(title), leading: leading);
}

Widget adaptativeBottomNavBar(
    {List<BottomNavigationBarItem> items, int currentIndex, Function onTap}) {
  if (Platform.isIOS) {
    return CupertinoTabBar(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }

  return BottomNavigationBar(
    items: items,
    currentIndex: currentIndex,
    onTap: onTap,
  );
}

RoundedLoadingButton mainBlueLoadingBtn(
    BuildContext context,
    RoundedLoadingButtonController controller,
    String text,
    Function onPressed) {
  return RoundedLoadingButton(
      width: MediaQuery.of(context).size.width / 2.2,
      height: 50,
      animateOnTap: false,
      controller: controller,
      borderRadius: 15,
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
      onPressed: onPressed);
}
