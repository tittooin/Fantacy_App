import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/cricket_api/data/scoring_service.dart';
import 'package:axevora11/features/cricket_api/data/result_service.dart';
import 'package:axevora11/features/admin/presentation/scoring_console_screen.dart';
import 'package:axevora11/features/admin/presentation/lineup_management_screen.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/admin/data/audit_service.dart'; // Import Audit Service
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchControlScreen extends ConsumerStatefulWidget {
  const MatchControlScreen({super.key});

  @override
  ConsumerState<MatchControlScreen> createState() => _MatchControlScreenState();
}

class _MatchControlScreenState extends ConsumerState<MatchControlScreen> {
  bool _isLoading = false;
  bool _isPollingPaused = false; // Safety: Pause Sync
  Timer? _pollingTimer;



  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startSmartPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!_isPollingPaused) {
        _pollMatches();
      }
    });
  }

  Future<void> _pollMatches() async {
    if (!mounted) return;
    
    // 1. Get all Active Matches (Live or Upcoming)
    final snapshot = await FirebaseFirestore.instance.collection('matches')
        .where('status', whereIn: ['Upcoming', 'Live'])
        .get();

    for (var doc in snapshot.docs) {
      final match = CricketMatchModel.fromMap(doc.data());
      
      // Smart Interval Logic
      // Live: Poll every cycle (30s)
      // Upcoming: Poll every 10th cycle (5 mins) - For now, we'll keep simple: Poll Live Only automatically
      
      if (match.status == 'Live') {
         await _syncScore(match.id.toString(), match.id.toString(), isBackground: true);
      }
    }
  }

  Future<void> _updateMatchStatus(String matchId, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      // Audit Log
      await auditProvider.logAction(
        action: 'UPDATE_STATUS', 
        matchId: matchId, 
        details: {'from': 'Unknown', 'to': newStatus}
      );

      // 1. Update Status
      await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
        'status': newStatus
      });

      // 2. Result Processing
      if (newStatus == 'Completed') {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing Results...")));
         await ref.read(resultServiceProvider).processMatchResult(matchId);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Results Declared!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Safe Archive (Soft Delete)
  Future<void> _archiveMatch(String matchId, String currentStatus) async {
    if (currentStatus == 'Live') {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot Archive Active/Live Matches!"), backgroundColor: Colors.red));
       return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Archive Match?", style: TextStyle(color: Colors.white)),
        content: const Text("This involves Soft Delete. It will be hidden from users but kept for audit.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Archive")),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    await auditProvider.logAction(action: 'ARCHIVE_MATCH', matchId: matchId);
    
    await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
      'status': 'ARCHIVED'
    });
    
    setState(() => _isLoading = false);
  }

  Future<void> _syncScore(String matchId, String cricbuzzId, {bool isBackground = false}) async {
    if (!isBackground) {
      setState(() => _isLoading = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing...")));
    }
    
    try {
      // 1. Fetch from API
      final scorecard = await ref.read(rapidApiServiceProvider).fetchScorecard(cricbuzzId);
      
      // 2. Save Snapshot (Audit)
      await auditProvider.saveApiSnapshot(matchId: matchId, rawData: scorecard);

      // 3. Update Firestore (Centralized Sync)
      // We update the 'score' field directly so users can listen to it.
      // WE ALSO process points
      await ref.read(scoringServiceProvider).processScorecard(matchId, scorecard);
      await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
        'score': scorecard, // Saving the raw/processed map for UI
      });

      if (!isBackground) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Synced!")));
        await auditProvider.logAction(action: 'MANUAL_SYNC', matchId: matchId);
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
      if (!isBackground) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (!isBackground && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importSquad(String matchId, CricketMatchModel match) async {
    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fetching Squad from API...")));
    
    try {
      // 1. Fetch Squad
      // We assume rapidApiServiceProvider has a method fetchAndSaveSquad. 
      // If not, we use fetchSquad and save manually here or via repository.
      // Checking existing service... looks like we need to call the repo/service.
      
      // Using RapidApiService to fetch and save directly
      await ref.read(rapidApiServiceProvider).fetchAndSaveSquad(matchId, matchId); // matchId, cricbuzzId

      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Squad Imported Successfully!"), backgroundColor: Colors.green));
         await auditProvider.logAction(action: 'IMPORT_SQUAD', matchId: matchId);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import Failed: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

<<<<<<< HEAD
=======

  late Stream<QuerySnapshot> _matchesStream;

  @override
  void initState() {
    super.initState();
    _startSmartPolling();
    _matchesStream = FirebaseFirestore.instance
        .collection('matches')
        .where('status', isNotEqualTo: 'ARCHIVED')
        .limit(50) // Reduced Quota Usage
        .snapshots();
  }

>>>>>>> dev-update
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Control (Auto-Poll Active)"),
        actions: [
           IconButton(
             icon: Icon(_isPollingPaused ? Icons.play_arrow : Icons.pause),
             color: _isPollingPaused ? Colors.green : Colors.orange,
             tooltip: _isPollingPaused ? "Resume Auto-Sync" : "Pause Auto-Sync",
             onPressed: () {
               setState(() => _isPollingPaused = !_isPollingPaused);
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text(_isPollingPaused ? "Auto-Sync PAUSED" : "Auto-Sync RESUMED")
               ));
             },
           ),
           IconButton(
             icon: const Icon(Icons.refresh), 
             onPressed: _pollMatches,
             tooltip: "Force Poll All Live",
           )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _matchesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No active matches"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final match = CricketMatchModel.fromMap(data);
              
              // FILTER GHOST MATCHES (Client-Side Fix for Bad Data)
              // Aggressive check for common bad data patterns
              final t1 = match.team1Name.trim();
              final t2 = match.team2Name.trim();
              
              if (t1.isEmpty || t2.isEmpty || 
                  t1 == 'Team 1' || t2 == 'Team 2' || 
                  t1 == '0' || t2 == '0' ||
                  t1.toLowerCase() == 'unknown' || t2.toLowerCase() == 'unknown') {
                 return const SizedBox.shrink();
              }

              final apiId = match.id.toString(); 

              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text("${match.team1ShortName} vs ${match.team2ShortName}", 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(match.status).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(match.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("ID: ${match.id} | ${match.seriesName}", style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      if (match.status == 'Live')
                         Padding(
                           padding: const EdgeInsets.only(top: 4),
                           child: Row(
                             children: [
                               const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent)),
                               const SizedBox(width: 8),
                               Text("Auto-Polling Active", style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontStyle: FontStyle.italic)),
                             ],
                           ),
                         ),
                      
                      const Divider(),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Manage Lineups (Always needed)
                          _buildActionButton(
                            "Import Squad", Icons.download, Colors.green, 
                            () => _importSquad(apiId, match)
                          ),

                          _buildActionButton(
                            "Lineups", Icons.group, Colors.purple, 
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => LineupManagementScreen(matchId: apiId, match: match)))
                          ),

                          // State Transitions
                          if (match.status == 'Upcoming')
                            _buildActionButton("Go Live", Icons.play_arrow, Colors.red, () => _updateMatchStatus(apiId, 'Live')),
                          
                          if (match.status == 'Live') ...[
                             _buildActionButton("Console", Icons.keyboard, Colors.orange, 
                               () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScoringConsoleScreen(matchId: apiId, initialMatchData: match)))
                             ),
                             _buildActionButton("Sync Now", Icons.sync, Colors.blue, () => _syncScore(apiId, apiId)),
                             _buildActionButton("Finish", Icons.stop, Colors.white, () => _updateMatchStatus(apiId, 'Completed'), isDark: true),
                          ],

                          if (match.status == 'Completed') ...[
                             _buildActionButton("Re-Open", Icons.replay, Colors.teal, () => _updateMatchStatus(apiId, 'Live')),
                             // Archive Button for Completed Matches
                             OutlinedButton.icon(
                               onPressed: _isLoading ? null : () => _archiveMatch(apiId, match.status),
                               icon: const Icon(Icons.archive, size: 16, color: Colors.orange),
                               label: const Text("Archive", style: TextStyle(color: Colors.orange, fontSize: 12)),
                               style: OutlinedButton.styleFrom(
                                 side: const BorderSide(color: Colors.orange),
                               ),
                             ),
                          ],

                          // Archive for Upcoming/Created (Delete essentially)
                          if (match.status == 'Upcoming' || match.status == 'Created')
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _archiveMatch(apiId, match.status),
                              icon: const Icon(Icons.archive, size: 16, color: Colors.grey),
                              label: const Text("Archive", style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, {bool isDark = false}) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.grey[800] : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 36),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Live': return Colors.red;
      case 'Completed': return Colors.green;
      case 'Upcoming': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
