import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

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
      return await FirebaseStorage.instance.ref(ref).getDownloadURL();
    } catch (e) {
      print(e);
      return null;
    }
  }
}
