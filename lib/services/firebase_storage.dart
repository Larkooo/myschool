import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final String ref;

  StorageService({this.ref});

  Future<String> uploadFile(File file) async {
    try {
      return await FirebaseStorage.instance
          .ref(ref)
          .putFile(file)
          .snapshot
          .ref
          .getDownloadURL();
    } on FirebaseException catch (e) {
      print(e);
      return null;
    }
  }

  Future<String> getDownloadURL() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getString(ref) != null) {
        return prefs.getString(ref);
      } else {
        String downloadUrl =
            await FirebaseStorage.instance.ref(ref).getDownloadURL();
        prefs.setString(ref, downloadUrl);
        return downloadUrl;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}
