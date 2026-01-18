import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MatchSchedulerService {
  Timer? _timer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isRunning = false;

  // Singleton pattern to ensure only one scheduler runs
  static final MatchSchedulerService _instance = MatchSchedulerService._internal();
  factory MatchSchedulerService() => _instance;
  MatchSchedulerService._internal();

  void startService() {
    if (_isRunning) return;
    
    debugPrint("🕒 Match Scheduler Service Started");
    _isRunning = true;
    
    // Initial check immediately
    _checkAndPromoteMatches();

    // Schedule periodic check every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkAndPromoteMatches();
    });
  }

  void stopService() {
    _timer?.cancel();
    _isRunning = false;
    debugPrint("🛑 Match Scheduler Service Stopped");
  }

  Future<void> _checkAndPromoteMatches() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final twentyFourHoursLater = now + (24 * 60 * 60 * 1000);

      // 1. Fetch Active Leagues
      Set<String> activeLeagues = {};
      try {
        final leaguesSnapshot = await _firestore.collection('leagues').where('active', isEqualTo: true).get();
        for (var doc in leaguesSnapshot.docs) {
          activeLeagues.add(doc.id);
        }
      } catch (e) {
        debugPrint("Scheduler Warning: Could not fetch leagues. Proceeding with caution.");
      }

      // 2. Query matches that are 'Created' (Hidden)
      final snapshot = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'Created')
          .get();

      if (snapshot.docs.isEmpty) return;

      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final startTime = data['startDate'] as int? ?? 0;
        final leagueId = data['leagueId'] as String?;

        // 3. League Validation Logic
        // IF match has a leagueId, verify it is in activeLeagues.
        // If leagueId is missing, we assume it's a legacy or general match and allow it (or you can decide to block).
        // Here, we BLOCK if leagueId is present but inactive.
        if (leagueId != null && leagueId.isNotEmpty && !activeLeagues.contains(leagueId)) {
          // League is inactive, SKIP
          continue; 
        }

        // 4. Time Validation Logic
        if (startTime > 0 && startTime <= twentyFourHoursLater) {
          await doc.reference.update({
            'status': 'Upcoming',
          });
          
          updatedCount++;
          debugPrint("✅ Auto-Promoted Match ${doc.id} to UPCOMING (League: $leagueId)");
        }
      }

      if (updatedCount > 0) {
        debugPrint("Scheduler: Promoted $updatedCount matches to Upcoming.");
      }

    } catch (e) {
      debugPrint("❌ Match Scheduler Error: $e");
    }
  }
}
