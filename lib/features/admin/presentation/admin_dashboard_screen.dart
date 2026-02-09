import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/admin/presentation/admin_wallet_screen.dart';
import 'package:axevora11/features/admin/presentation/admin_logs_screen.dart';
import 'package:axevora11/features/admin/presentation/scoring_console_screen.dart';
import 'package:axevora11/features/cricket_api/presentation/contest_creator_screen.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:axevora11/scripts/fix_team_short_names.dart';
import 'package:axevora11/features/admin/data/admin_repository.dart';

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
  List<CricketMatchModel> _matches = [];

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _refreshData();
       _fetchMatches();
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Aggregated Stats from D1 (Zero Firestore Reads)
      final stats = await ref.read(rapidApiServiceProvider).fetchAdminStats();

      // 2. Assign Values (Defaults to 0 if API fails or returns null)
      _liveMatches = int.tryParse(stats['liveMatches']?.toString() ?? '0') ?? 0;
      _upcomingMatches = int.tryParse(stats['upcomingMatches']?.toString() ?? '0') ?? 0;
      _activeContests = int.tryParse(stats['activeContests']?.toString() ?? '0') ?? 0;
      
      // Note: User count from D1 might be 0 until we sync users. 
      // But this satisfies the "No Firestore Read" requirement.
      // _kycPending/_pendingPayouts are currently 0 from API. 
      // If we need real values for these financial items, we might need a separate light query,
      // but for now we stick to strict quota rules.
      _pendingPayouts = int.tryParse(stats['pendingPayouts']?.toString() ?? '0') ?? 0; 
      _kycPending = int.tryParse(stats['kycPending']?.toString() ?? '0') ?? 0;

    } catch (e) {
      debugPrint("Dashboard Stats Error: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMatches() async {
    setState(() { _isLoading = true; _matches = []; }); // clear old data to show loading/empty
    try {
      Query query = FirebaseFirestore.instance.collection('matches');
      final now = DateTime.now().millisecondsSinceEpoch;
      final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);

      if (_selectedTab == 0) {
         // Live: Matches status is Live or In Progress
         query = query.where('status', whereIn: ['Live', 'In Progress', 'Live ']); // Added 'Live ' just in case of whitespace
      } else if (_selectedTab == 1) {
         // Upcoming: status is Upcoming AND startDate >= now. 
         // ORDER BY startDate ASC (Nearest first)
         query = query.where('status', isEqualTo: 'Upcoming')
                      .where('startDate', isGreaterThan: now)
                      .orderBy('startDate', descending: false);
      } else if (_selectedTab == 2) {
         // Completed: status in [Completed, Finished] AND recent
         // ORDER BY startDate DESC (Most recent first)
         query = query.where('status', whereIn: ['Completed', 'Finished', 'Abandoned'])
                      .where('startDate', isGreaterThan: sevenDaysAgo)
                      .orderBy('startDate', descending: true);
      } else {
         // Archive: status is ARCHIVED Or very old
         // Just fetch 'ARCHIVED' explicitly for now to be safe
         query = query.where('status', isEqualTo: 'ARCHIVED')
                      .limit(20);
      }
      
      final qs = await query.limit(50).get();
      final list = qs.docs.map((d) => CricketMatchModel.fromMap(d.data() as Map<String, dynamic>)).toList();
      
      if(mounted) setState(() => _matches = list);
    } catch (e) {
      debugPrint("Error fetching matches: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // ... (Update methods to refresh list)

  void _onTabChanged(int index) {
      setState(() => _selectedTab = index);
      _fetchMatches();
  }

  // Helper for Status Update
  Future<void> _updateMatchStatus(CricketMatchModel match, String newStatus) async {
      await FirebaseFirestore.instance.collection('matches').doc(match.id.toString()).update({'status': newStatus});
      _fetchMatches(); // Refresh list to remove it from current tab if needed
  }

  Future<void> _deleteMatch(CricketMatchModel match) async {
       await FirebaseFirestore.instance.collection('matches').doc(match.id.toString()).delete();
       _fetchMatches();
  }

  Future<void> _confirmAndDistribute(BuildContext context, CricketMatchModel match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Payout"),
        content: Text("Are you sure you want to distribute prizes for ${match.team1ShortName} vs ${match.team2ShortName}?\n\nThis will credit wallets and cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("DISTRIBUTE")
          ),
        ],
      ),
    );

    if (confirm == true) {
       setState(() => _isLoading = true);
       try {
         final result = await ref.read(rapidApiServiceProvider).distributePrizes(match.id.toString());
         if (result['success'] == true) {
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Payout Process Initiated! Check Logs.")));
         } else {
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed: ${result['error']}")));
         }
       } catch (e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
       } finally {
          if(mounted) setState(() => _isLoading = false);
       }
    }
  }

   Future<void> _publishSquad(BuildContext context, CricketMatchModel match) async {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text("Publishing Squad to User App..."), duration: Duration(seconds: 2))
     );
     
     setState(() => _isLoading = true);
  try {
    // Use AdminRepository to publish manual squad
    await ref.read(adminRepositoryProvider).publishManualSquad(match.id.toString());
    
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Squad Published Successfully!"), backgroundColor: Colors.green)
      );
    }
  } catch (e) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("❌ Publish Failed: $e"), backgroundColor: Colors.red)
         );
       }
     } finally {
       if(mounted) setState(() => _isLoading = false);
     }
   }

  Future<void> _fixTeamShortNames() async {
    setState(() => _isLoading = true);
    try {
      await fixTeamShortNames();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Team short names fixed for all matches!"), backgroundColor: Colors.green)
        );
        _fetchMatches(); // Refresh matches
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _selectedTab = 1; // 0=Live, 1=Upcoming, 2=Completed, 3=Archive (Default to Upcoming usually, or Active logic)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.build),
            tooltip: "Fix Team Short Names",
            onPressed: _fixTeamShortNames,
          ),
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () { _refreshData(); _fetchMatches(); }
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Overview Cards ---
            const Text("Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DashboardCard(
                  title: "Live Matches", 
                  value: "$_liveMatches", 
                  icon: Icons.sports_cricket, 
                  color: Colors.redAccent, 
                  onTap: () => setState(() => _selectedTab = 0) // Switch to Live Tab
                ),
                _DashboardCard(
                  title: "Upcoming", 
                  value: "$_upcomingMatches", 
                  icon: Icons.calendar_today, 
                  color: Colors.blueAccent, 
                  onTap: () => setState(() => _selectedTab = 1) // Switch to Upcoming Tab
                ),
                _DashboardCard(title: "Contests", value: "$_activeContests", icon: Icons.emoji_events, color: Colors.amber, onTap: () => context.push('/admin/contests')),
                _DashboardCard(title: "Pending Payouts", value: "$_pendingPayouts", icon: Icons.account_balance_wallet, color: Colors.orange, onTap: () => context.push('/admin/wallet')),
                _DashboardCard(title: "KYC Requests", value: "$_kycPending", icon: Icons.verified_user, color: Colors.purpleAccent, onTap: () => context.push('/admin/kyc')),
                _DashboardCard(title: "Voucher Requests", value: "Manage", icon: Icons.card_giftcard, color: Colors.teal, onTap: () => context.push('/admin/vouchers')),
              ],
            ),

            const SizedBox(height: 32),
            
            // --- Section 2: Match Management ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Match Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => context.push('/admin/matches'), // Match Import Screen
                  icon: const Icon(Icons.add),
                  label: const Text("Import Match"),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Tabs / Filters
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     _buildTabBtn("Live", 0, color: Colors.red),
                     _buildTabBtn("Upcoming", 1, color: Colors.blue),
                     _buildTabBtn("Completed (7d)", 2, color: Colors.green),
                     _buildTabBtn("Archive", 3, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_matches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text("No matches loaded. Refresh.")),
              )
            else
              _buildFilteredList(),
              
             const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, int index, {Color? color}) {
     final bool isSelected = _selectedTab == index;
     return GestureDetector(
       onTap: () => setState(() => _selectedTab = index),
       child: Container(
         width: 120, // Fixed width for consistent look
         padding: const EdgeInsets.symmetric(vertical: 10),
         margin: const EdgeInsets.symmetric(horizontal: 2),
         decoration: BoxDecoration(
           color: isSelected ? Colors.white : Colors.transparent,
           borderRadius: BorderRadius.circular(6),
           border: isSelected && color != null ? Border.all(color: color.withOpacity(0.5), width: 1) : null,
           boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
         ),
         child: Text(
            label, 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
              color: isSelected ? (color ?? Colors.black) : Colors.grey[600]
            )
          ),
       ),
     );
  }

  Widget _buildFilteredList() {
      // Logic: Filter client-side based on the 'Strict Rules'
      final now = DateTime.now().millisecondsSinceEpoch;
      final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);

      final filtered = _matches.where((m) {
          final isLive = m.status == 'Live' || m.status == 'In Progress';
          final isFinished = m.status == 'Completed' || m.status == 'Finished' || m.status == 'Abandoned';
          final isFuture = m.startDate > now;

          // 0. Live
          if (_selectedTab == 0) {
             return !m.isArchived && isLive;
          }
          // 1. Upcoming
          if (_selectedTab == 1) {
             return !m.isArchived && m.status == 'Upcoming' && isFuture;
          }
          // 2. Completed (Recent)
          if (_selectedTab == 2) {
             final isRecent = m.startDate > sevenDaysAgo && m.startDate <= now;
             return !m.isArchived && isFinished && isRecent;
          }
          // 3. Archive
          if (_selectedTab == 3) {
             if (m.isArchived) return true;
             final isOld = m.startDate <= sevenDaysAgo;
             final isStaleUpcoming = m.status == 'Upcoming' && m.startDate <= now;
             return isOld || isStaleUpcoming;
          }
          return false;
      }).toList();

      if (filtered.isEmpty) {
         String msg = "No matches found";
         if (_selectedTab == 0) msg = "No Live Matches";
         if (_selectedTab == 1) msg = "No Upcoming Matches";
         if (_selectedTab == 2) msg = "No Recent Completed Matches";
         if (_selectedTab == 3) msg = "No Archived Matches";
         
         return Container(
           padding: const EdgeInsets.all(32),
           alignment: Alignment.center,
           child: Text(msg, style: const TextStyle(color: Colors.grey))
         );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final match = filtered[index];
          // Hide ghosts
          if (match.team1Name == '0' || match.team2Name == '0') return const SizedBox.shrink();

          return _buildMatchTile(context, match);
        },
      );
  }

  Widget _buildMatchTile(BuildContext context, CricketMatchModel match) {
    bool isLive = match.status.toLowerCase() == 'live';
    Color statusColor = isLive ? Colors.green : (match.status == 'Upcoming' ? Colors.blue : Colors.grey);
    
    // Auto-Archive Visual Indicator if in Archive Tab
    bool isArchiveTab = _selectedTab == 3;
    
    final formattedDate = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(match.startDate));
    final formattedTime = DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(match.startDate));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isArchiveTab ? Colors.grey : statusColor, borderRadius: BorderRadius.circular(4)),
                  child: Text(match.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${match.team1ShortName} vs ${match.team2ShortName}", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      const SizedBox(height: 4),
                       // Date & Time Display
                       Row(
                         children: [
                           Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                           const SizedBox(width: 4),
                           Text("$formattedDate  •  $formattedTime", style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                         ],
                       ),
                    ],
                  ),
                ),
                
                // Countdown for Upcoming
                if (match.status == 'Upcoming' && !isArchiveTab)
                   _MatchCountdown(startDate: match.startDate),
                
                // Live Indicator
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.red),
                        SizedBox(width: 4),
                        Text("LIVE NOW", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
                      ],
                    )
                  )

              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                 // Actions - Context Aware

                 // LIVE TAB
                 if (_selectedTab == 0) ...[
                      OutlinedButton(onPressed: () => _updateMatchStatus(match, "Completed"), child: const Text("Finish Match")),
                 ],

                 // UPCOMING TAB
                 if (_selectedTab == 1) ...[
                      OutlinedButton(onPressed: () => _updateMatchStatus(match, "Live"), child: const Text("START MATCH")),
                 ],

                 // COMPLETED TAB (Manual Payout)
                 if (_selectedTab == 2) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      icon: const Icon(Icons.monetization_on, size: 16),
                      onPressed: () => _confirmAndDistribute(context, match), 
                      label: const Text("Distribute Prizes"),
                    ),
                 ],

                 // COMMON (Except Archive)
                 if (_selectedTab != 3) ...[
                   ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(0, 36)),
                     icon: const Icon(Icons.edit, size: 16),
                     onPressed: () => context.push('/admin/matches/${match.id}/manage-squad', extra: match),
                     label: const Text("Manage Squad"),
                   ),
                   ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(0, 36)),
                     icon: const Icon(Icons.cloud_upload, size: 16),
                     onPressed: () => _publishSquad(context, match),
                     label: const Text("Publish"),
                   ),
                   OutlinedButton.icon(
                     icon: const Icon(Icons.group, size: 16),
                     onPressed: () => context.push('/admin/matches/${match.id}/players', extra: match),
                     label: const Text("View Active"),
                   ),
                   OutlinedButton.icon(
                     icon: const Icon(Icons.emoji_events, size: 16),
                     onPressed: () => context.push('/admin/matches/${match.id}/contests', extra: match),
                     label: const Text("Contests"),
                   ),
                 ],
                 
                 // DELETE (Always available)
                 IconButton(
                   icon: const Icon(Icons.delete, color: Colors.red),
                   onPressed: () => _deleteMatch(match),
                   tooltip: "Delete",
                 )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _MatchCountdown extends StatefulWidget {
  final int startDate;
  const _MatchCountdown({required this.startDate});

  @override
  State<_MatchCountdown> createState() => _MatchCountdownState();
}

class _MatchCountdownState extends State<_MatchCountdown> {
  late Timer _timer;
  String _timeLeft = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(widget.startDate);
    final diff = start.difference(now);

    if (diff.isNegative) {
      if (mounted) setState(() => _timeLeft = "Starting...");
    } else {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      
      String formatted;
      if (days > 0) {
        formatted = "${days}d ${hours}h ${minutes}m";
      } else {
        formatted = "${hours}h ${minutes}m ${seconds}s";
      }
      
      if (mounted) setState(() => _timeLeft = formatted);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3))
      ),
      child: Column(
        children: [
          const Text("Starts In", style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
          Text(_timeLeft, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13)),
        ],
      ),
    );
  }
} // Closed _MatchCountdownState

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
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
