import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/cricket_api/data/services/firestore_cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PollingService {
  final RapidApiService _api;
  final FirestoreCacheService _cache;
  
  Timer? _timer;
  bool _isRunning = false;
  
  // Smart Polling State
<<<<<<< HEAD
  int _currentInterval = 120; // Default 120s (2 mins) to save Quota
=======
  int _currentInterval = 300; // Default 300s (5 mins) to save Quota
>>>>>>> dev-update
  bool _lastBallWasWicket = false;
  int _wicketBurstCount = 0;

  PollingService(this._api, this._cache);

  void startPolling() {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint("🚀 [Polling] Service Started (Admin Mode)");
    
    _runSync(); // Initial Run
    _scheduleNext();
  }

  void stopPolling() {
    _timer?.cancel();
    _isRunning = false;
    debugPrint("🛑 [Polling] Service Stopped");
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_isRunning) return;

    _timer = Timer(Duration(seconds: _currentInterval), () {
      _runSync();
    });
  }

  Future<void> _runSync() async {
    debugPrint("📡 [Polling] Triggering Worker Refresh (Interval: $_currentInterval s)");
    
    try {
      // 1. Trigger worker Update
      await _api.fetchFixtures();
      
      // 2. Fetch locally to check status
      final matches = await _api.fetchLiveMatches();
      
      // 3. Check if any match is ACTUALLY Live
      bool anyLive = matches.any((m) => m.status.toLowerCase() == 'live');
      
      if (anyLive) {
<<<<<<< HEAD
         debugPrint("🏏 Live Matches Found! Continuing Polling every 120s.");
         _currentInterval = 120; // Ensure 120s minimum
         _cache.saveMatches(matches, 'live');
      } else {
         debugPrint("zzz No Live Matches. Pausing Polling to save Quota.");
         // We stop polling. Admin can Manual Refresh to restart if needed.
         stopPolling();
         return; 
=======
         debugPrint("🏏 Live Matches Found! Polling every 120s.");
         _currentInterval = 120; // 2 mins for Live
         _cache.saveMatches(matches, 'live');
      } else {
         debugPrint("zzz No Live Matches. Polling slowed to 300s.");
         _currentInterval = 300; // 5 mins for Idle
>>>>>>> dev-update
      }

    } catch (e) {
      debugPrint("⚠️ Polling Sync Error: $e");
    }

    _scheduleNext();
  }

  bool get isRunning => _isRunning;
}

final pollingServiceProvider = Provider<PollingService>((ref) {
  return PollingService(
    ref.read(rapidApiServiceProvider),
    ref.read(firestoreCacheServiceProvider)
  );
});
