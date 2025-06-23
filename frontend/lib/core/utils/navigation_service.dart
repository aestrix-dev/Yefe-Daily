import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';

class AppNavigationService {
  BuildContext? get _context => navigatorKey.currentContext;

  void navigateTo(String route) {
    if (_context != null) {
      _context!.go(route);
    }
  }

  void navigateToAndReplace(String route) {
    if (_context != null) {
      _context!.pushReplacement(route);
    }
  }

  void pop() {
    if (_context != null) {
      _context!.pop();
    }
  }
}
