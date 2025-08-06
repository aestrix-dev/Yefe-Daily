import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:yefa/presentation/shared/widgets/toast_overlay.dart';

class ToastService {
  // Private constructor
  ToastService._();

  // Singleton instance
  static final ToastService _instance = ToastService._();
  static ToastService get instance => _instance;

  // Helper method to get current context
  BuildContext? get _context => StackedService.navigatorKey?.currentContext;

  // Show success toast
  void showSuccess({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = _context;
    if (context != null) {
      ToastOverlay.showSuccess(
        context: context,
        message: message,
        duration: duration,
      );
    } else {
      print('⚠️ ToastService: No context available to show toast');
    }
  }


  // Show error toast
  void showError({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = _context;
    if (context != null) {
      ToastOverlay.showError(
        context: context,
        message: message,
        duration: duration,
      );
    } else {
      print('⚠️ ToastService: No context available to show toast');
    }
  }

  // Show warning toast
  void showWarning({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = _context;
    if (context != null) {
      ToastOverlay.showWarning(
        context: context,
        message: message,
        duration: duration,
      );
    } else {
      print('⚠️ ToastService: No context available to show toast');
    }
  }

  // Show info toast
  void showInfo({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = _context;
    if (context != null) {
      ToastOverlay.showInfo(
        context: context,
        message: message,
        duration: duration,
      );
    } else {
      print('⚠️ ToastService: No context available to show toast');
    }
  }

  // Generic show method
  void show({
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = _context;
    if (context != null) {
      ToastOverlay.show(
        context: context,
        message: message,
        type: type,
        duration: duration,
      );
    } else {
      print('⚠️ ToastService: No context available to show toast');
    }
  }
  // Hide current toast
  void hide() {
    ToastOverlay.hide();
  }
}

// Global instance for easy access
final toastService = ToastService.instance;
