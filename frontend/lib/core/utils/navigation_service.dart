import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// If navigatorKey is not defined in app.dart, define it here:
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppNavigationService {
  BuildContext? get _context => navigatorKey.currentContext;

  void navigateTo(String route) {

    if (_context != null) {

      _context!.go(route);
    } else {

    }
  }

  void navigateToAndReplace(String route) {

    if (_context != null) {

      _context!.pushReplacement(route);
    } else {

    }
  }

  void pop() {
    if (_context != null) {
      _context!.pop();
    }
  }
}
