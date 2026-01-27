import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:flutter/foundation.dart';

// State Class
class MatchesState {
  final List<CricketMatchModel> upcoming;
  final List<CricketMatchModel> completed;
  final bool isLoading;
  final String? error;

  MatchesState({
    this.upcoming = const [],
    this.completed = const [],
    this.isLoading = false,
    this.error,
  });

  MatchesState copyWith({
    List<CricketMatchModel>? upcoming,
    List<CricketMatchModel>? completed,
    bool? isLoading,
    String? error,
  }) {
    return MatchesState(
      upcoming: upcoming ?? this.upcoming,
      completed: completed ?? this.completed,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear error if not provided
    );
  }
}

// Notifier
class MatchesNotifier extends StateNotifier<MatchesState> {
  MatchesNotifier() : super(MatchesState());

  bool _hasFetched = false;

  Future<void> fetchMatches({bool forceRefresh = false}) async {
    // Zero-Hit Logic: If already fetched and not forcing refresh, return cached.
    if (_hasFetched && !forceRefresh) {
      debugPrint("♻️ [Matches] Returning Cached Data (Zero Reads)");
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      debugPrint("🔥 [Matches] Fetching from Firestore (Cost: N Reads)");
      final qs = await FirebaseFirestore.instance.collection('matches')
          .orderBy('startDate', descending: true)
          .limit(50)
          .get();
      
      final all = qs.docs.map((d) => CricketMatchModel.fromMap(d.data())).toList();
      
      final upcoming = all.where((m) => m.status == 'Upcoming' || m.status == 'Live').toList();
      final completed = all.where((m) => m.status == 'Completed').toList();

      state = MatchesState(
        upcoming: upcoming,
        completed: completed,
        isLoading: false,
      );
      _hasFetched = true;
    } catch (e) {
      debugPrint("❌ [Matches] Error: $e");
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider with keepAlive to persist data across tab switches
final matchesProvider = StateNotifierProvider<MatchesNotifier, MatchesState>((ref) {
  return MatchesNotifier();
});
