import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';

class AppNavigationService {
  BuildContext? get _context => navigatorKey.currentContext;

  void navigateTo(String route) {
    print('NavigationService: Attempting to navigate to $route');
    if (_context != null) {
      print('NavigationService: Context found, navigating...');
      _context!.go(route);
    } else {
      print('NavigationService: ERROR - Context is null!');
    }
  }

  void navigateToAndReplace(String route) {
    print('NavigationService: Attempting to replace with $route');
    if (_context != null) {
      print('NavigationService: Context found, replacing...');
      _context!.pushReplacement(route);
    } else {
      print('NavigationService: ERROR - Context is null!');
    }
  }

  void pop() {
    if (_context != null) {
      _context!.pop();
    }
  }
}
