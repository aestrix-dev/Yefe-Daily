import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom page transition builder for professional fade-in and zoom effects
class PageTransitions {
  /// Creates a zoom-in transition
  static Page<T> zoomTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Scale animation for zoom effect (zoom from 95% to 100%)
        final scaleAnimation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return ScaleTransition(scale: scaleAnimation, child: child);
      },
    );
  }

  /// Creates a slide transition (for onboarding)
  static Page<T> slideTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return SlideTransition(position: slideAnimation, child: child);
      },
    );
  }

  /// Creates a smooth fade transition (lighter version)
  static Page<T> fadeTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return FadeTransition(opacity: fadeAnimation, child: child);
      },
    );
  }

  /// Determines which transition to use based on the route
  static Page<T> getTransitionForRoute<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    final path = state.uri.path;

    // Use slide transition for onboarding
    if (path == '/onboarding') {
      return slideTransition<T>(context, state, child);
    }

    // Use fade transition for splash (quick and simple)
    if (path == '/') {
      return fadeTransition<T>(context, state, child);
    }

    // Use zoom transition for all other pages
    return zoomTransition<T>(context, state, child);
  }
}
