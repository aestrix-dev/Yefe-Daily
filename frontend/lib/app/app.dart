import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../app/app_setup.dart';
import '../core/constants/app_routes.dart';
import '../data/services/theme_service.dart';
import '../presentation/shared/themes/app_theme.dart';
import '../presentation/views/splash/splash_view.dart';
import '../presentation/views/onboarding/onboarding_view.dart';
import '../presentation/views/home/home_view.dart';

// Declare the navigator key here
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: locator<ThemeService>().themeModeNotifier,
          builder: (context, themeMode, child) {
            return MaterialApp.router(
              title: 'Yefa',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: _router,
            );
          },
        );
      },
    );
  }
}

final GoRouter _router = GoRouter(
  navigatorKey: navigatorKey, // This connects the key to GoRouter
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingView(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeView(),
    ),
  ],
);
