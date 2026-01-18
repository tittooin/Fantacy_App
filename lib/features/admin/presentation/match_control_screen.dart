import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/data/cricket_api_service.dart';
import 'package:axevora11/features/cricket_api/data/scoring_service.dart';
import 'package:axevora11/features/cricket_api/data/result_service.dart';
import 'package:axevora11/features/admin/presentation/scoring_console_screen.dart'; // Added
import 'package:axevora11/features/admin/presentation/lineup_management_screen.dart'; // Added
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchControlScreen extends ConsumerStatefulWidget {
  const MatchControlScreen({super.key});

  @override
  ConsumerState<MatchControlScreen> createState() => _MatchControlScreenState();
}

class _MatchControlScreenState extends ConsumerState<MatchControlScreen> {
  bool _isLoading = false;

  Future<void> _updateMatchStatus(String matchId, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      // 1. Update Status in Firestore
      await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
        'status': newStatus
      });

      // 2. If Completed, Trigger Result Processing
      if (newStatus == 'Completed') {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing Results & Winnings...")));
         await ref.read(resultServiceProvider).processMatchResult(matchId);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Results Declared! Winnings Distributed.")));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Match updated to $newStatus")));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncScore(String matchId, String cricbuzzId) async {
    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing Score...")));
    
    try {
      // 1. Fetch Scorecard
      final scorecard = await ref.read(cricketApiServiceProvider).fetchScorecard(cricbuzzId);
      
      // 2. Calculate Fantasy Points & Update Match Stats
      await ref.read(scoringServiceProvider).processScorecard(matchId, scorecard);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Score Synced & Points Updated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Match Control Panel")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No matches found"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final match = CricketMatchModel.fromMap(data);
              
              // Determine Cricbuzz ID (using ID as proxy for now since we stored it)
              // In real scenario, we might have stored specific 'apiId'
              final apiId = match.id.toString(); 

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${match.team1ShortName} vs ${match.team2ShortName}", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: match.status == 'Live' ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(match.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Match ID: ${match.id} | Series: ${match.seriesName}"),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (match.status == 'Upcoming' || match.status == 'Live')
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => LineupManagementScreen(
                                  matchId: apiId,
                                  match: match,
                                )));
                              },
                              icon: const Icon(Icons.group),
                              label: const Text("Manage Lineups"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                            ),

                          if (match.status == 'Upcoming')
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _updateMatchStatus(apiId, 'Live'),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("Go Live"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            ),
                          
                          if (match.status == 'Live')
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ScoringConsoleScreen(
                                  matchId: apiId,
                                  initialMatchData: match,
                                )));
                              },
                              icon: const Icon(Icons.keyboard),
                              label: const Text("Manual Console"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                            ),
                          
                          if (match.status == 'Live')
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _syncScore(apiId, apiId),
                              icon: const Icon(Icons.sync),
                              label: const Text("Sync Score"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            ),
                            
                          if (match.status == 'Live')
                             ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _updateMatchStatus(apiId, 'Completed'),
                              icon: const Icon(Icons.stop),
                              label: const Text("Finish"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                            ),

                          if (match.status == 'Completed')
                             ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _updateMatchStatus(apiId, 'Live'),
                              icon: const Icon(Icons.replay),
                              label: const Text("Re-Open (Live)"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
