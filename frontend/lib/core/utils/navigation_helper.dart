import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

class NavigationHelper {
  static void goHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  static void goToJournal(BuildContext context) {
    context.go(AppRoutes.journal);
  }

  static void goToChallenges(BuildContext context) {
    context.go(AppRoutes.challenges);
  }

  static void goToDevotionals(BuildContext context) {
    context.go(AppRoutes.audio);
  }

  static void pushToProfile(BuildContext context) {
    context.push(AppRoutes.profile);
  }
}
