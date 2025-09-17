import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';

class BackButtonHandler extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const BackButtonHandler({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackButton(context);
        }
      },
      child: child,
    );
  }

  void _handleBackButton(BuildContext context) {
    // If already on home screen, let the system handle (close app)
    if (currentRoute == AppRoutes.home) {
      // Exit the app
      Navigator.of(context).pop();
      return;
    }

    // Navigate to home screen instead of closing app
    context.go(AppRoutes.home);
  }
}