import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yefa/presentation/views/audio/audio_view.dart';
import 'package:yefa/presentation/views/history/history_view.dart';
import 'package:yefa/presentation/views/profile/profile_view.dart';

import '../../core/constants/app_routes.dart';
import '../../presentation/views/splash/splash_view.dart';
import '../../presentation/views/onboarding/onboarding_view.dart';
import '../../presentation/views/home/home_view.dart';

import '../../presentation/views/journal/journal_view.dart';
import '../../presentation/views/challenges/challenges_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
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
    GoRoute(
      path: AppRoutes.journal,
      builder: (context, state) => const JournalView(),
    ),
    GoRoute(
      path: AppRoutes.challenges,
      builder: (context, state) => const ChallengesView(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileView(),
    ),
    GoRoute(
      path: AppRoutes.audio,
      builder: (context, state) => const AudioView(),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => const HistoryView(),
    ),
  ],
);
