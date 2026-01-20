import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/core/router/app_router.dart';
import 'package:axevora11/core/theme/app_theme.dart';
import 'package:axevora11/features/location/data/location_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDVoZoy6_Qz36Xz3P7CbkGSB75Vq0CsJhU",
          authDomain: "axevora11.firebaseapp.com",
          projectId: "axevora11",
          storageBucket: "axevora11.firebasestorage.app",
          messagingSenderId: "526953085440",
          appId: "1:526953085440:web:e765e8884960196c36b6e5",
          measurementId: "G-Z2F4G77KWE",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    
    // Initialize Analytics & Performance
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    if (!kIsWeb) {
      FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    }
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
