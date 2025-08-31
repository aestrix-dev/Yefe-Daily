import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yefa/presentation/views/audio/audio_view.dart';
import 'package:yefa/presentation/views/history/history_view.dart';
import 'package:yefa/presentation/views/profile/profile_view.dart';

import '../../core/constants/app_routes.dart';
import '../../core/utils/page_transitions.dart';
import '../../presentation/views/splash/splash_view.dart';
import '../../presentation/views/onboarding/onboarding_view.dart';
import '../../presentation/views/home/home_view.dart';

import '../../presentation/views/journal/journal_view.dart';
import '../../presentation/views/challenges/challenges_view.dart';

import 'package:stacked_services/stacked_services.dart';

final GlobalKey<NavigatorState> navigatorKey =
    StackedService.navigatorKey as GlobalKey<NavigatorState>;

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => PageTransitions.getTransitionForRoute(
        context,
        state,
        const SplashView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => PageTransitions.getTransitionForRoute(
        context,
        state,
        const OnboardingView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => PageTransitions.getTransitionForRoute(
        context,
        state,
        const HomeView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.journal,
      pageBuilder: (context, state) => PageTransitions.getTransitionForRoute(
        context,
        state,
        const JournalView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.challenges,
      pageBuilder: (context, state) => PageTransitions.getTransitionForRoute(
        context,
        state,
        const ChallengesView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.profile,
      pageBuilder: (context, state) => PageTransitions.getTransitionForRoute(
        context,
        state,
        const ProfileView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.audio,
      pageBuilder: (context, state) => PageTransitions.getTransitionForRoute(
        context,
        state,
        const AudioView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.history,
      pageBuilder: (context, state) => PageTransitions.getTransitionForRoute(
        context,
        state,
        const HistoryView(),
      ),
    ),
  ],
);
