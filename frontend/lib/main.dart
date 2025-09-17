import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:yefa/firebase_options.dart';
import 'package:yefa/core/utils/firebase_background_handler.dart';

import 'app/app.dart';
import 'app/app_setup.dart';
import 'data/services/audio_player_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  print('🚀 Starting app initialization...');

  // Setup services first
  await AppSetup.setupServices();
  print('✅ App services initialized');

  // Initialize audio service for background playback
  await _initializeAudioService();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Stripe.publishableKey =
      'pk_test_51Rjcn1Cc0zU2ZKe3wErao4byE0zLWN1cPJhqHHF2690YBk2eiblSNPJmpUa3YT9SwHc7umx1SqLdRdotUyITnYag00rapeOvO7';

  print('🎵 Running app...');
  runApp(const MyApp());
}

Future<void> _initializeAudioService() async {
  try {
    print('🎵 Initializing audio service...');

    await AudioService.init(
      builder: () => locator<AudioPlayerService>(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.yefa.audio',
        androidNotificationChannelName: 'Yefa Audio',
        androidNotificationChannelDescription: 'Audio playback controls',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
      ),
    );

    print('✅ Audio service initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize audio service: $e');
    // Don't throw error, let app continue without audio service
  }
}
