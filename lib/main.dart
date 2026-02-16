import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/core/router/app_router.dart';
import 'package:axevora11/core/theme/app_theme.dart';
import 'package:axevora11/core/guards/boot_guard.dart';
import 'package:axevora11/features/location/data/location_service.dart';
import 'package:axevora11/features/user/data/user_repository.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();

    // 1. Framework Error Handler
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint("🔥 [FLUTTER ERROR]: ${details.exception}");
      debugPrint("   Stack: ${details.stack}");
    };

    // 2. Platform/Async Error Handler
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint("🔥 [PLATFORM ERROR]: $error");
      debugPrint("   Stack: $stack");
      return true;
    };

    debugPrint("🚀 [BOOT] AXEVORA v2.1 - SAFE DEBUG MODE");

    SharedPreferences? prefs;

    try {
      debugPrint("⏳ [BOOT] Initializing SharedPreferences...");
      prefs = await SharedPreferences.getInstance();
      debugPrint("✅ [BOOT] SharedPreferences Ready.");
    } catch (e, stack) {
       debugPrint("🔥 [BOOT PREFS ERROR]: $e");
       debugPrint(stack.toString());
       // Critical dependency failed? We proceed but log heavily.
    }

    // Checking BootGuard
    try {
        if (prefs != null) {
           debugPrint("⏳ [BOOT] Checking BootGuard...");
           final isSafe = await BootGuard.checkSafety(prefs);
           debugPrint("✅ [BOOT] BootGuard Result: $isSafe");

           if (!isSafe) {
             debugPrint("🛑 [BOOT] BootGuard Blocked Access.");
             runApp(BootBlockedScreen(onReset: () async {
                if (prefs != null) await BootGuard.reset(prefs);
             }));
             return;
           }
        }
    } catch (e) {
       debugPrint("⚠️ [BOOT GUARD WARNING]: $e");
    }

    // Initializing Firebase
    try {
      debugPrint("⏳ [BOOT] Initializing Firebase...");
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDVoZoy6_Qz36Xz3P7CbkGSB75Vq0CsJhU'),
            authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'axevora11.firebaseapp.com'),
            projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'axevora11'),
            storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'axevora11.firebasestorage.app'),
            messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '526953085440'),
            appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:526953085440:web:e765e8884960196c36b6e5'),
            measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: 'G-Z2F4G77KWE'),
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      debugPrint("✅ [BOOT] Firebase Initialized.");
      
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      debugPrint("✅ [BOOT] Analytics Enabled.");

    } catch (e, stack) {
        debugPrint("🔥 [BOOT FATAL FIREBASE ERROR]: $e");
        debugPrint(stack.toString());
        // We continue, as app might work offline/cached or show error UI later
    }

    debugPrint("🚀 [BOOT] Calling runApp()...");
    
    // Safely create overrides
    final overrides = <Override>[];
    if (prefs != null) {
       overrides.add(sharedPreferencesProvider.overrideWithValue(prefs));
    }

    runApp(
      ProviderScope(
        overrides: overrides,
        child: const AxevoraApp(),
      ),
    );
    debugPrint("✅ [BOOT] runApp() called successfully.");

  }, (error, stack) {
    debugPrint("🔥 [ZONED OUTSIDE ERROR]: $error");
    debugPrint("   Stack: $stack");
  });
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
