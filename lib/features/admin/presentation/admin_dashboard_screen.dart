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
  // Metric Counts
  int _liveMatches = 0;
  int _upcomingMatches = 0;
  int _activeContests = 0;
  int _pendingPayouts = 0;
  int _kycPending = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
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

  Future<void> _syncSchedule() async {
    setState(() => _isSyncing = true);
    try {
      // Worker handles fetching & saving to Firestore
      await ref.read(rapidApiServiceProvider).fetchFixtures();
      
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
=======
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Matches Stats (Optimized with Count aggregations)
      final liveSnap = await FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'Live')
          .count()
          .get();
      _liveMatches = liveSnap.count ?? 0;

      final upcomingSnap = await FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'Upcoming')
          .count()
          .get();
      _upcomingMatches = upcomingSnap.count ?? 0;

      // 2. Contests Stats (Optimized)
      // Note: checking 'status' != 'Completed' is tricky with simple indices, 
      // but for now we can just count 'Open' or 'Live' to be safe and cheap.
      final activeContestsSnap = await FirebaseFirestore.instance
          .collection('contests')
          .where('status', whereIn: ['Open', 'Live', 'Upcoming']) 
          .count()
          .get();
      _activeContests = activeContestsSnap.count ?? 0;

      // 3. Payouts (Withdrawals)
      final payoutsSnap = await FirebaseFirestore.instance
          .collection('withdrawals')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      _pendingPayouts = payoutsSnap.count ?? 0;

      // 4. KYC Pending
      final kycSnap = await FirebaseFirestore.instance
          .collection('kyc_requests')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      _kycPending = kycSnap.count ?? 0;

      setState(() {});

    } catch (e) {
      debugPrint("Dashboard Refresh Error: $e");
>>>>>>> dev-update
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Padding(
=======
    return SingleChildScrollView(
>>>>>>> dev-update
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
<<<<<<< HEAD
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
=======
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dashboard Overview", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _isLoading ? null : _refreshData, icon: const Icon(Icons.refresh, color: Colors.blueAccent))
            ],
          ),
          const SizedBox(height: 24),

          // 5 Key Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _DashboardCard(
                title: "Live Matches", 
                value: "$_liveMatches", 
                icon: Icons.sports_cricket, 
                color: Colors.redAccent,
                onTap: () => context.go('/admin/matches'),
              ),
              _DashboardCard(
                title: "Upcoming Matches", 
                value: "$_upcomingMatches", 
                icon: Icons.calendar_today, 
                color: Colors.blueAccent,
                onTap: () => context.go('/admin/matches'),
              ),
              _DashboardCard(
                title: "Active Contests", 
                value: "$_activeContests", 
                icon: Icons.emoji_events, 
                color: Colors.amber,
                onTap: () => context.go('/admin/contests'),
              ),
              _DashboardCard(
                title: "Pending Payouts", 
                value: "$_pendingPayouts", 
                icon: Icons.account_balance_wallet, 
                color: Colors.orange,
                onTap: () => context.go('/admin/wallet'),
              ),
              _DashboardCard(
                title: "KYC Pending", 
                value: "$_kycPending", 
                icon: Icons.verified_user, 
                color: Colors.purpleAccent,
                onTap: () => context.go('/admin/kyc'),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Recent Activity Section (Placeholder logic for now as requested "Read only")
          Row(
            children: [
              const Icon(Icons.history, color: Colors.white54),
              const SizedBox(width: 8),
              const Text("System Status", style: TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2235), // Dark Navy
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)
            ),
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text("All Systems Operational", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Last Checked: ${DateFormat('hh:mm a').format(DateTime.now())}", style: const TextStyle(color: Colors.white54)),
                ],
              ),
>>>>>>> dev-update
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


class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A38), // Card Background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14)
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 4),
                 Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            )
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
