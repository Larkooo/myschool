import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final String ref;

  StorageService({this.ref});

  Future<bool> uploadFile(File file) async {
    try {
      await FirebaseStorage.instance.ref(ref).putFile(file);
      return true;
    } on FirebaseException catch (e) {
      print(e);
      return false;
    }
  }
}
