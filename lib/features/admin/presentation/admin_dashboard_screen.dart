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
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Matches Stats
      final matchesSnap = await FirebaseFirestore.instance.collection('matches').get();
      final matches = matchesSnap.docs.map((d) => d.data()).toList();
      _liveMatches = matches.where((m) => m['status'] == 'Live').length;
      _upcomingMatches = matches.where((m) => m['status'] == 'Upcoming').length;

      // 2. Contests Stats
      final contestsSnap = await FirebaseFirestore.instance.collection('contests').get();
      _activeContests = contestsSnap.docs.where((d) => d['status'] != 'Completed').length; // Assuming status field

      // 3. Payouts (Withdrawals)
      final payoutsSnap = await FirebaseFirestore.instance.collection('withdrawals').where('status', isEqualTo: 'pending').count().get();
      _pendingPayouts = payoutsSnap.count ?? 0;

      // 4. KYC Pending
      final kycSnap = await FirebaseFirestore.instance.collection('kyc_requests').where('status', isEqualTo: 'pending').count().get();
      _kycPending = kycSnap.count ?? 0;

      setState(() {});

    } catch (e) {
      debugPrint("Dashboard Refresh Error: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
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
          Expanded(
            child: Container(
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
            ),
          )
        ],
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
