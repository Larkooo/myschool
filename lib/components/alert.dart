import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import 'package:flutter/services.dart';

class Alert {
  static const MethodChannel _channel = const MethodChannel('alert');

  final String message;
  final bool shortDuration;

  Alert({
    @required this.message,
    this.shortDuration = true,
  }) : assert(message != null);

  Future<void> show() async {
    await _channel.invokeMethod(
      Platform.isAndroid ? 'showToast' : 'showAlert',
      {'message': message, 'short-duration': shortDuration},
    );
  }
}
