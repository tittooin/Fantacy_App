import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/core/router/app_router.dart';
import 'package:axevora11/core/theme/app_theme.dart';
import 'package:axevora11/features/location/data/location_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
=======
  usePathUrlStrategy();
>>>>>>> dev-update
  debugPrint("🚀 [BOOT] AXEVORA v2.0 - STRICT RAPIDAPI MODE ACTIVE");
  debugPrint("🚫 [CLEANUP] ALL PROXY/CLOUDFLARE CODE REMOVED");
  
  try {
    // Initialize Firebase
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDVoZoy6_Qz36Xz3P7CbkGSB75Vq0CsJhU'),
          authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'axevora11.firebaseapp.com'),
          projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'axevora11'),
          storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'axevora11.firebasestorage.app'),
          messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '526953085440'),
          appId: const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:526953085440:web:e765e8884960196c36b6e5'),
          measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: 'G-Z2F4G77KWE'),
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    
    // Initialize Analytics & Performance
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    /* if (!kIsWeb) {
      FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    } */
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AxevoraApp(),
    ),
  );
}

class AxevoraApp extends ConsumerWidget {
  const AxevoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    
    return MaterialApp.router(
      title: 'Axevora11',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
