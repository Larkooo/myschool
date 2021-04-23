import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:alert/alert.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:myschool/models/user.dart';
import 'package:myschool/pages/announcements.dart';
import 'package:myschool/pages/homeworks.dart';
import 'package:myschool/services/database.dart';
import 'package:myschool/shared/cachemanager.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:dart_date/dart_date.dart';
import 'package:url_launcher/url_launcher.dart';

enum GroupAttribute { alias, image, students, code }
enum AnnounceCategory { essay, homework, important, message }
enum Scope { school, group, none }
enum UserType { student, teacher, direction, staff }
enum CodeType { student, staff, admin }
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

const String surveyURL = 'https://forms.gle/kc9eBHqVJLnDwFrS9';
const String bugReportURL = 'https://forms.gle/1gaeqdCgbr8wbrCn6';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void launchURL(String url) async => await canLaunch(url)
    ? await launch(url)
    : Alert(message: 'Could not launch URL').show();

final Map<String, Type> pageType = {
  "announce": Announcements,
  "homework": Homeworks
};

const Map<int, UserType> userTypeDefinitions = {
  0: UserType.student,
  1: UserType.teacher,
  2: UserType.direction,
  3: UserType.staff
};

const Map<UserType, int> userTypeId = {
  UserType.student: 0,
  UserType.teacher: 1,
  UserType.direction: 2,
  UserType.staff: 3
};

Widget filesListWidget(BuildContext context, List<PlatformFile> attachmentFiles,
        {double scale}) =>
    Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 5,
              children: attachmentFiles
                  .map((file) => Stack(children: [
                        Container(
                          constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height / 5,
                              minWidth: MediaQuery.of(context).size.width / 3),
                          child: Material(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.file_present),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  file.name.length > 10
                                      ? file.name.substring(0, 10) + '...'
                                      : file.name,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]))
                  .toList(),
            )));

Widget largeButton(
        BuildContext context, Widget child, void Function() onPressed) =>
    Container(
        width: MediaQuery.of(context).size.width / 1.2,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
        child: Column(children: [
          Container(
              width: MediaQuery.of(context).size.width / 1.5,
              child: ElevatedButton(
                onPressed: onPressed,
                child: child,
                style: ButtonStyle(),
              )),
          SizedBox(
            height: 5,
          )
        ]));

Widget themeIconButton(BuildContext context, Widget text, Widget icon,
        void Function() onPressed,
        {double size = 1}) =>
    Container(
        width: (MediaQuery.of(context).size.width / 2) * size,
        height: (MediaQuery.of(context).size.height / 20) * size,
        child: Material(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).cardColor,
            child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onPressed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [text, icon],
                ))));

const Map<UserType, String> userTypeLocale = {
  UserType.student: 'Étudiant',
  UserType.teacher: 'Professeur',
  UserType.direction: 'Direction',
  UserType.staff: 'Membre du personnel'
};

Future getImage(ImagePicker picker) async {
  final pickedFile = await picker.getImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    return File(pickedFile.path);
  } else {
    return null;
  }
}

Future<UserData> getUserWithCache(String uid) async {
  if (CacheManagerMemory.cachedUsers[uid] != null)
    return CacheManagerMemory.cachedUsers[uid];
  return DatabaseService.userDataFromSnapshot(
      await FirebaseFirestore.instance.collection('users').doc(uid).get());
}

Text formattedDate(DateTime date, fontSize) {
  int diffInDaysNow = DateTime.now().differenceInDays(date);
  return Text(
    (diffInDaysNow == 0
            ? "Aujourd'hui"
            : diffInDaysNow == -1
                ? "Hier"
                : diffInDaysNow == -2
                    ? "Avant-hier"
                    : DateFormat.yMMMMEEEEd().format(date)) +
        " à " +
        DateFormat.Hm().format(date),
    style: TextStyle(color: Colors.grey[500], fontSize: 12),
  );
}

Future<Widget> loadingBackdrop(BuildContext context) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()));

Column coursePage(
        BuildContext context,
        UserData user,
        String id,
        String description,
        DateTime time,
        List intervenants,
        String endHour,
        List rooms) =>
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(fontSize: 18),
        ),
        Text(
          DateFormat.Hm().format(time),
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        SizedBox(
          height: 25,
        ),
        if (user.type == UserType.student)
          Column(children: [
            Text(
              "Groupe",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              user.school.group.uid,
              style: TextStyle(color: Colors.grey[500]),
            )
          ]),
        SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: [
              Text(
                "Heure de début",
                style: TextStyle(fontSize: 15),
              ),
              Text(
                DateFormat.Hm().format(time),
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Intervenant",
                style: TextStyle(fontSize: 15),
              ),
              Text(
                intervenants[0]['nom'] + " " + intervenants[0]['prenom'],
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              )
            ]),
            Column(children: [
              Text(
                "Heure de fin",
                style: TextStyle(fontSize: 15),
              ),
              Text(
                endHour,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Local",
                style: TextStyle(fontSize: 15),
              ),
              Text(
                rooms[0],
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              )
            ]),
          ],
        ),
        SizedBox(
          height: 30,
        ),
        Text(
          "Prochain cours",
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
            width: MediaQuery.of(context).size.width / 1.3,
            child: Card(
              child: ListTile(
                  title: Text(description + " (${rooms[0]})"),
                  subtitle: Text(intervenants[0]['nom'] +
                      " " +
                      intervenants[0]['prenom'] +
                      " - " +
                      DateFormat.MEd().format(
                          getNextCourse(time, id, CacheManagerMemory.courses)
                              .key))),
            )),
        SizedBox(
          height: 10,
        ),
        Container(
            width: MediaQuery.of(context).size.width / 1.5,
            child: ElevatedButton(
              onPressed: () {
                List<int> endHourSplit =
                    endHour.split(':').map((e) => int.tryParse(e)).toList();
                DateTime endTime = DateTime(time.year, time.month, time.day,
                    endHourSplit[0], endHourSplit[1]);
                final Event event = Event(
                    title: description, startDate: time, endDate: endTime);
                Add2Calendar.addEvent2Cal(event);
              },
              child: Text('Ajouter un rappel'),
              style: ButtonStyle(),
            )),
      ],
    );

Widget loadButton(BuildContext context, void Function() onPressed) => Center(
    child: Container(
        width: MediaQuery.of(context).size.width / 1.8,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text('Charger plus de messages'),
          style: ButtonStyle(),
        )));

Container noAvatar(double size) => Container(
    width: 20 * size,
    height: 20 * size,
    color: themeNotifier.value == ThemeMode.dark
        ? Colors.grey[900]
        : Colors.grey[400],
    child: Icon(
      Icons.person,
      size: 10 * size,
    ));

Row userLeadingHorizontal(UserData user, double size) => Row(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: user.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl,
                    //progressIndicatorBuilder:
                    //    (context, url, downloadProgress) =>
                    //        CircularProgressIndicator.adaptive(
                    //            value: downloadProgress.progress),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    placeholder: (context, url) => noAvatar(20),
                    height: 20 * size,
                    width: 20 * size,
                  )
                : noAvatar(size)),
        SizedBox(
          width: 5,
        ),
        Text(user.uid != "-1" ? user.firstName : "Deleted User",
            style: TextStyle(fontSize: 18 * size)),
      ],
    );

Column userLeadingVertical(UserData user, double size) => Column(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: user.avatarUrl != null && user.uid != "-1"
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl,
                    placeholder: (context, url) => noAvatar(20),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    height: 20 * size,
                    width: 20 * size,
                  )
                : noAvatar(size)),
        SizedBox(
          width: 5,
        ),
        Text(user.uid != "-1" ? user.firstName : "Deleted User",
            style: TextStyle(fontSize: 15 * size)),
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
      backgroundColor: Colors.transparent,
      iconSize: 25,
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
