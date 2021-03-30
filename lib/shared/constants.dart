import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:dart_date/dart_date.dart';

enum GroupAttribute { Alias, Image }
enum AnnounceCategory { Essay, Homework, Important, Message }
enum Scope { school, group }
enum UserType { student, teacher }
enum CodeType { student, staff }
enum AuthCode {
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

Future getImage(ImagePicker picker) async {
  final pickedFile = await picker.getImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    return File(pickedFile.path);
  } else {
    return null;
  }
}

Row userLeadingHorizontal(UserData user, double size) => Row(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: user.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) =>
                            CircularProgressIndicator.adaptive(
                                value: downloadProgress.progress),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    height: 20 * size,
                    width: 20 * size,
                  )
                : Container(
                    width: 20 * size,
                    height: 20 * size,
                    color: Colors.grey[900],
                    child: Icon(
                      Icons.person,
                      size: 10 * size,
                    ))),
        SizedBox(
          width: 5,
        ),
        Text(user.firstName, style: TextStyle(fontSize: 18 * size)),
      ],
    );

Column userLeadingVertical(UserData user, double size) => Column(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: user.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) =>
                            CircularProgressIndicator.adaptive(
                                value: downloadProgress.progress),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    height: 20 * size,
                    width: 20 * size,
                  )
                : Container(
                    width: 20 * size,
                    height: 20 * size,
                    color: Colors.grey[900],
                    child: Icon(
                      Icons.person,
                      size: 10 * size,
                    ))),
        SizedBox(
          width: 5,
        ),
        Text(user.firstName, style: TextStyle(fontSize: 18 * size)),
      ],
    );

dynamic adaptiveDialog(
    {BuildContext context,
    Widget title,
    Widget content,
    List<Widget> actions}) {
  return showDialog(
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

Widget adaptiveCalendarPicker(
    DateTime initialDate, DateTime firstDate, DateTime lastDate,
    [Function(DateTime) onDateChanged]) {
  if (Platform.isIOS) {
    return CupertinoDatePicker(
        initialDateTime: initialDate,
        minimumDate: firstDate,
        maximumDate: lastDate,
        onDateTimeChanged: onDateChanged);
  } else {
    return CalendarDatePicker(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        onDateChanged: onDateChanged);
  }
}

TextButton adaptiveDialogTextButton(
    BuildContext context, String text, Function onPressed) {
  if (Platform.isIOS) {
    return textButton(context, text, onPressed);
  }
  return TextButton(child: Text(text), onPressed: onPressed);
}

Widget adaptiveAppBar({String title, Widget leading}) {
  if (Platform.isIOS) {
    return CupertinoNavigationBar(middle: Text(title), leading: leading);
  }
  return AppBar(title: Text(title), leading: leading);
}

Widget adaptiveBottomNavBar(
    {List<BottomNavigationBarItem> items, int currentIndex, Function onTap}) {
  if (Platform.isIOS) {
    return CupertinoTabBar(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }

  return BottomNavigationBar(
    selectedItemColor: Colors.grey[400],
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
