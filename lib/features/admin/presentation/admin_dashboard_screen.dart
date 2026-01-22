import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/admin/presentation/admin_wallet_screen.dart';
import 'package:axevora11/features/admin/presentation/admin_logs_screen.dart';
import 'package:axevora11/features/admin/presentation/scoring_console_screen.dart';
import 'package:axevora11/features/cricket_api/presentation/contest_creator_screen.dart';
import 'package:axevora11/features/cricket_api/data/cricket_api_service.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _currentTime = "";
  Timer? _timer;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Initialize time without setState
    _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    // Start timer for subsequent updates
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Removed _startClock as it's redundant now

  void _updateTime() {
    if(!mounted) return;
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    });
  }

  Future<void> _syncSchedule() async {
    setState(() => _isSyncing = true);
    try {
      final matches = await ref.read(cricketApiServiceProvider).fetchUpcomingMatches();
      final batch = FirebaseFirestore.instance.batch();
      
      int added = 0;
      for (var match in matches) {
          final docRef = FirebaseFirestore.instance.collection('matches').doc(match.id.toString());
          // Use set with merge to avoid overwriting existing match status if it's already live/customized
          batch.set(docRef, match.toJson(), SetOptions(merge: true));
          added++;
      }
      
      await batch.commit();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Success: Synced $added Matches!")));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync Failed: $e")));
    } finally {
      if(mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // NO SCAFFOLD HERE. Just Content.
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Dashboard", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Text(_currentTime, style: const TextStyle(color: Colors.white54, fontSize: 18, fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 32),
          
          // Stats Cards
          Row(
            children: [
               _buildStatCard("Active Matches", "...", Colors.blueAccent),
               const SizedBox(width: 16),
               _buildStatCard("Total Users", "...", Colors.purpleAccent),
               const SizedBox(width: 16),
               _buildStatCard("System Health", "Good", Colors.greenAccent),
            ],
          ),
          
          const SizedBox(height: 48),

          // Actions Header
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text("Quick Actions", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _syncSchedule,
                  icon: _isSyncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                  label: Text(_isSyncing ? "SYNCING..." : "REFRESH DATA"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                )
             ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _buildMatchList(
               statusLink: ['Live', 'Upcoming'],
               emptyMsg: "No Active Matches found. Sync from API."
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList({required List<String> statusLink, required String emptyMsg, bool isUpcoming = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('matches')
          .where('status', whereIn: statusLink)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.white38))),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final match = CricketMatchModel.fromMap(data);
            return _buildMatchTile(match, isUpcoming);
          },
        );
      },
    );
  }

  Widget _buildMatchTile(CricketMatchModel match, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        gradient: LinearGradient(colors: [const Color(0xFF1E1E1E), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight)
      ),
      child: Row(
        children: [
          // Teams
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                       child: Text(match.matchFormat, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                     ),
                     const SizedBox(width: 8),
                     Text(DateFormat('MMM dd, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(match.startDate)), 
                       style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("${match.team1ShortName} vs ${match.team2ShortName}", 
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(match.seriesName, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),

          // Actions
          if (isUpcoming) 
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContestCreatorScreen(match: match))),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text("Create Contest"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            )
          else
             ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScoringConsoleScreen(matchId: match.id.toString(), initialMatchData: match))),
              icon: const Icon(Icons.settings_remote, size: 16),
              label: const Text("Console"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}
