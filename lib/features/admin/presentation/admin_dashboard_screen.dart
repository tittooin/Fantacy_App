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

  int _userCount = 0;
  int _pendingWithdrawals = 0;

  @override
  void initState() {
    super.initState();
    _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());

    WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(pollingServiceProvider).startPolling();
       _fetchDashboardStats();
       _fetchMatches();
    });
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final userSnap = await FirebaseFirestore.instance.collection('users').count().get();
      final withdrawSnap = await FirebaseFirestore.instance.collection('withdrawals').where('status', isEqualTo: 'pending').count().get();
      
      if(mounted) {
        setState(() {
          _userCount = userSnap.count ?? 0;
          _pendingWithdrawals = withdrawSnap.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Stats Error: $e");
    }
  }

  void _updateTime() {
    if(mounted) {
      setState(() {
        _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
    }
  }

  Future<void> _syncSchedule() async {
    setState(() => _isSyncing = true);
    // Simulate Sync or call a service if available
    await Future.delayed(const Duration(seconds: 2));
    if(mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final liveMatches = _matches.where((m) => m.status.toLowerCase() == 'live').length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header & Metrics
          Row(
            children: [
               _MetricCard(label: "Total Users", value: "$_userCount", icon: Icons.people, color: Colors.blue),
               const SizedBox(width: 16),
               _MetricCard(label: "Pending Withdrawals", value: "$_pendingWithdrawals", icon: Icons.account_balance_wallet, color: Colors.orange, onTap: () => context.push('/admin/wallet')),
               const SizedBox(width: 16),
               _MetricCard(label: "Live Matches", value: "$liveMatches", icon: Icons.sports_cricket, color: Colors.red),
               const Spacer(),
               // Quick Actions
               _AdminActionButton(
                 label: "Refresh Data", 
                 icon: Icons.refresh, 
                 onTap: _isSyncing ? () {} : () { _syncSchedule(); _fetchDashboardStats(); },
                 isLoading: _isSyncing
               ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 2. Active Matches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Active Matches", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ElevatedButton.icon(
                onPressed: () {}, // Implementation for Create Match
                icon: const Icon(Icons.add),
                label: const Text("Create Match"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              )
            ],
          ),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                if (onTap != null) const Icon(Icons.arrow_forward, color: Colors.white24, size: 16)
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isLoading;

  const _AdminActionButton({required this.label, this.icon, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: isLoading 
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
      label: Text(isLoading ? "Syncing..." : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
      ),
    );
  }
}
