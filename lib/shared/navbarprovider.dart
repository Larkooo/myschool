import 'package:flutter/cupertino.dart';

class NavigationBarProvider with ChangeNotifier {
  static NavigationBarProvider provider;
  NavigationBarProvider() {
    provider = this;
  }

  int _currentIndex = 0;

  get currentIndex => _currentIndex;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
