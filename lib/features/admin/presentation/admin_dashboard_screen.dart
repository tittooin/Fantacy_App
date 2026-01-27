import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/admin/presentation/admin_wallet_screen.dart';
import 'package:axevora11/features/admin/presentation/admin_logs_screen.dart';
import 'package:axevora11/features/admin/presentation/scoring_console_screen.dart';
import 'package:axevora11/features/cricket_api/presentation/contest_creator_screen.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/cricket_api/data/services/polling_service.dart';
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

    // START POLLING SERVICE
    // This ensures only the Admin Panel triggers API calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(pollingServiceProvider).startPolling();
    });
  }

  @override
  void dispose() {
    // STOP POLLING SERVICE
    // Stops API calls when Admin closes this screen
    ref.read(pollingServiceProvider).stopPolling();
    
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

  DateTime? _lastSyncTime;

  Future<void> _syncSchedule() async {
    // 1. Debounce (60s cooldown) to save Quota
    if (_lastSyncTime != null) {
      final diff = DateTime.now().difference(_lastSyncTime!);
      if (diff.inSeconds < 60) {
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text("Wait ${60 - diff.inSeconds}s before refreshing again."),
             backgroundColor: Colors.orange,
           ));
        }
        return;
      }
    }

    setState(() => _isSyncing = true);
    try {
      // Worker handles fetching & saving to Firestore
      await ref.read(rapidApiServiceProvider).fetchFixtures();
      
      _lastSyncTime = DateTime.now(); // Update timestamp
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Success: Sync Triggered! matches will appear shortly."),
            backgroundColor: Colors.green,
          )
        );
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync Failed: $e"),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if(mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.grey, size: 28),
                    SizedBox(width: 12),
                    Text("ADMIN", style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    _TabButton(label: "Refresh", onTap: _isSyncing ? null : _syncSchedule, isActive: false),
                    const SizedBox(width: 8),
                    _TabButton(label: "Live", onTap: () {}, isActive: true), // Placeholder Logic
                    _TabButton(label: "Upcoming", onTap: () {}, isActive: false),
                    _TabButton(label: "Completed", onTap: () {}, isActive: false),
                    const SizedBox(width: 8),
                    _TabButton(label: "Users", onTap: () => context.push('/admin/users'), isActive: false),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {}, 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black),
                      child: const Text("Create Match"),
                    )
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text("Match List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 16),
          
          Expanded(
            child: _buildMatchList(
               statusLink: ['Live', 'Upcoming', 'Completed'], // Show all for now
               emptyMsg: "No Matches. Click Refresh."
            ),
          ),
        ],
      ),
    );
  }

  // State for Manual Fetch
  List<CricketMatchModel> _matches = [];
  bool _isLoading = false;



  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    try {
      // Fetch top 50 matches (Active/Upcoming)
      final qs = await FirebaseFirestore.instance.collection('matches')
          .orderBy('startDate', descending: true)
          .limit(50)
          .get();
          
      final list = qs.docs.map((d) => CricketMatchModel.fromMap(d.data())).toList();
      if(mounted) setState(() => _matches = list);
    } catch (e) {
      debugPrint("Error fetching matches: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMatchList({required List<String> statusLink, required String emptyMsg}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_matches.isEmpty) {
      return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
          
        // GHOST FILTER
        final t1 = match.team1Name.trim();
        final t2 = match.team2Name.trim();
        if (t1.isEmpty || t2.isEmpty || t1 == '0' || t2 == '0') return const SizedBox.shrink();

        return _buildMatchTile(context, match);
      },
    );
  }

  Widget _buildMatchTile(BuildContext context, CricketMatchModel match) {
    bool isLive = match.status.toLowerCase() == 'live';
    Color statusColor = isLive ? Colors.green : (match.status == 'Upcoming' ? Colors.grey : Colors.orange);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                child: Text(match.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 16),
              Text("${match.team1ShortName} vs ${match.team2ShortName}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               _AdminActionButton(label: "Go Live", onTap: () => _updateMatchStatus(match, "Live")),
               const SizedBox(width: 12),
               _AdminActionButton(label: "Players", onTap: () => context.push('/admin/matches/${match.id}/players', extra: match)),
               const SizedBox(width: 12),
               _AdminActionButton(label: "Contests", icon: Icons.emoji_events, onTap: () => context.push('/admin/matches/${match.id}/contests', extra: match)),
               const SizedBox(width: 12),
               _AdminActionButton(label: "Finish", onTap: () => _updateMatchStatus(match, "Completed")),
               const SizedBox(width: 12),
               _AdminActionButton(label: "Delete", icon: Icons.delete_outline, onTap: () => _deleteMatch(match)),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _updateMatchStatus(CricketMatchModel match, String newStatus) async {
      await FirebaseFirestore.instance.collection('matches').doc(match.id.toString()).update({'status': newStatus});
  }
  
  Future<void> _deleteMatch(CricketMatchModel match) async {
       // Confirmation Dialog could be added here
       await FirebaseFirestore.instance.collection('matches').doc(match.id.toString()).delete();
  }

  Future<void> _importSquad(String matchId, CricketMatchModel match) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fetching Squad from API...")));
    try {
      await ref.read(rapidApiServiceProvider).fetchAndSaveSquad(matchId, matchId);
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Squad Imported Successfully! Check Team Creation in User App."), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import Failed: $e"), backgroundColor: Colors.red));
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  const _TabButton({required this.label, required this.onTap, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey.shade200 : Colors.transparent,
          border: Border(bottom: BorderSide(color: isActive ? Colors.black : Colors.transparent, width: 2))
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _AdminActionButton({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade400))
      ),
    );
  }
}
