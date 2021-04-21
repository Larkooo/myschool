import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool isWeb = kIsWeb;
  static bool isAndroid = isWeb ? false : Platform.isAndroid;
  static bool isIOS = isWeb ? false : Platform.isIOS;
}
