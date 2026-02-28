import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_contest_model.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart'; // Added Lottie

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/team/presentation/providers/team_provider.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
import 'package:axevora11/features/contest/presentation/providers/user_contest_provider.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/user/domain/user_entity.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:axevora11/features/cricket_api/data/providers/scorecard_provider.dart';
import 'package:axevora11/features/cricket_api/data/providers/leaderboard_provider.dart';
import 'package:axevora11/features/contest/presentation/widgets/team_pitch_view_sheet.dart';



class ContestDetailScreen extends ConsumerStatefulWidget {
  final String contestId;
  final CricketRoomModel? contest; // Made optional
  final CricketMatchModel? match; 
  final String? matchId; // Added for fetching if match/contest is missing

  const ContestDetailScreen({
    super.key,
    required this.contestId,
    this.contest,
    this.match,
    this.matchId,
  });

  @override
  ConsumerState<ContestDetailScreen> createState() => _ContestDetailScreenState();
}

class _ContestDetailScreenState extends ConsumerState<ContestDetailScreen> {
  CricketRoomModel? _contest;
  bool _isLoading = false;
  String? _error;
  late final String? _resolvedMatchId;

  @override
  void initState() {
    super.initState();
    // Resolve matchID from either direct ID or Match Object
    _resolvedMatchId = widget.matchId ?? widget.match?.id.toString();
    
    _contest = widget.contest;
    // Always fetch once to ensure we have late-breaking D1 data (Breakdown, Prize Pool etc)
    _fetchContest();
  }

  Future<void> _fetchContest() async {
    setState(() => _isLoading = true);
    try {
      debugPrint("📡 [D1 Only Sync] Fetching contest: ${widget.contestId}");
      final apiService = ref.read(rapidApiServiceProvider);
      final contestData = await apiService.fetchContestById(widget.contestId);

      if (contestData != null) {
         setState(() {
           _contest = contestData;
           _isLoading = false;
         });
         debugPrint("✅ D1 → Pure Sync success for contest ${widget.contestId}");
      } else {
         debugPrint("❌ D1 Fetch Failed for contest: ${widget.contestId}");
         setState(() {
           _error = "Contest details not available on Server. Please try again.";
           _isLoading = false;
         });
      }
    } catch (e) {
      debugPrint("❌ Fatal Fetch Error: $e");
      setState(() {
        _error = "Sync Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text("Error: $_error")));
    if (_contest == null) return const Scaffold(body: Center(child: Text("Contest Data Missing")));

    final contest = _contest!; // Local variable for cleaner access

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 500;
        final initialIndex = (widget.match?.status == 'Live' || widget.match?.status == 'Completed') ? 1 : 0;
        
        final mobileContent = DefaultTabController(
          length: 2,
          initialIndex: initialIndex, // Show Leaderboard/Points by default if Live
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.indigo,
              title: const Text("Room Details", style: TextStyle(fontSize: 16)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _handleRefresh(),
                  tooltip: "Refresh Leaderboard",
                )
              ],
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: "Benefits"),
                  Tab(text: "Leaderboard"),
                ],
              ),
            ),
            body: Column(
              children: [
                _buildHeader(contest),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBenefitsTab(contest),
                      _buildLeaderboardTab(contest),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(context, contest),
          ),
        );

        if (isLargeScreen) {
          return Scaffold(
            backgroundColor: Colors.grey[900],
            body: Center(
              child: Container(
                width: 450,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800),
                  boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black54)],
                ),
                child: mobileContent,
              ),
            ),
          );
        }

        return mobileContent;
      },
    );
  }

  Widget _buildHeader(CricketRoomModel contest) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Interaction Benefits", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Row(
                    children: [
                       Text(contest.category, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 8),
                       if (widget.match?.status == 'Live')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                            child: const Row(children: [
                              Icon(Icons.circle, size: 8, color: Colors.white),
                              SizedBox(width: 4),
                              Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                            ]),
                          )
                    ],
                  ),
                ],
              ),
               if (false) const SizedBox.shrink()
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: contest.totalParticipants > 0 ? contest.filledParticipants / contest.totalParticipants : 0,
            backgroundColor: Colors.grey.shade200,
            color: Colors.orange,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final matchId = _resolvedMatchId ?? contest.id;
              if (matchId.isEmpty) return const SizedBox.shrink();
              final scoreAsync = ref.watch(scorecardProvider(matchId));
              
              return scoreAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) {
                  if (data == null) return const SizedBox.shrink();
                  
                  final t1 = data['team_a_score'] ?? "";
                  final t2 = data['team_b_score'] ?? "";
                  
                  if (t1.isEmpty && t2.isEmpty) return const SizedBox.shrink();
                  
                  return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(t1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                            const Text("vs", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text(t2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                        ],
                      ),
                  );
                }
              );
            }
          ),
          // const SizedBox(height: 8), // Removed as margin included above
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${contest.totalParticipants - contest.filledParticipants} spots left", 
                style: const TextStyle(color: Colors.orange, fontSize: 12)
              ),
              Text("${contest.totalParticipants} spots", 
                style: const TextStyle(color: Colors.grey, fontSize: 12)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsTab(CricketRoomModel contest) {
    return Consumer(
      builder: (context, ref, _) {
        final allJoined = ref.watch(userContestProvider);
        final myJoinedTeams = allJoined.where((uc) => uc.contestId == contest.id).toList();
        final leaderboardAsync = ref.watch(leaderboardProvider(contest.id));

        return ListView(
          children: [
            // 🏆 MY TEAMS SECTION
            if (myJoinedTeams.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.indigo, size: 20),
                    SizedBox(width: 8),
                    Text("MY INTERACTIONS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1.1, fontSize: 13)),
                  ],
                ),
              ),
              leaderboardAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("Rankings error: $err", style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
                data: (entries) {
                  return Column(
                    children: myJoinedTeams.map((myTeam) {
                      // Match local team with Leaderboard data from D1
                      final leaderEntry = entries.firstWhere(
                        (e) => e['teamId'] == myTeam.teamId,
                        orElse: () => <String, dynamic>{},
                      );

                      final rank = leaderEntry['rank'] ?? '-';
                      final points = (leaderEntry['points'] ?? 0.0).toDouble();

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          onTap: () => _showTeamPitchView(context, ref, leaderEntry.isNotEmpty ? leaderEntry : {
                            'teamId': myTeam.teamId,
                            'teamName': myTeam.teamName,
                            'userId': myTeam.userId,
                            'points': 0.0,
                          }),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
                            alignment: Alignment.center,
                            child: Text(
                              rank.toString() == '-' ? '-' : "#$rank",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          title: Text(myTeam.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text("Access: ${myTeam.entryFee.toStringAsFixed(0)} Axe"),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("${points.toStringAsFixed(1)} stats", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                              const Text("View Team", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const Divider(height: 32),
            ],

            // 💰 BENEFIT BREAKDOWN SECTION
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text("INTERACTION BENEFITS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1, fontSize: 13)),
                ],
              ),
            ),
            
            if (contest.benefitTiers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text("Benefit breakdown will be updated soon.", style: TextStyle(color: Colors.grey))),
              )
            else
              ...contest.benefitTiers.map((tier) {
                final start = tier['rankStart'];
                final end = tier['rankEnd'];
                final amount = tier['amount'];
                final rankText = start == end ? "#$start" : "#$start - #$end";
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rankText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                );
              }).toList(),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "Note: Interaction benefits are managed independently by the Room Host.\nRanks & stats are updated every 5 mins for informational purposes.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[400], height: 1.5),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildBenefitRow(int rank, double amount) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("#$rank", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("${amount.toStringAsFixed(0)} Coins"),
        ],
      ),
    );
  }

  // Added refresh handler
  Future<void> _handleRefresh() async {
    await _fetchContest();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated"), duration: Duration(milliseconds: 800)));
    }
  }

  Widget _buildLeaderboardTab(CricketRoomModel contest) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.amber.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: const Text(
            "Stats & Ranks are updated every 5 minutes and are for informational purposes only.",
            style: TextStyle(color: Colors.amber, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Consumer(
             builder: (context, ref, _) {
                final leaderboardAsync = ref.watch(leaderboardProvider(widget.contestId));

                return leaderboardAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text("Error: $err")),
                  data: (entries) {
                     if (entries.isEmpty) {
                        return const Center(child: Text("No participants or data pending calculation."));
                     }

                     return RefreshIndicator(
                       onRefresh: () async {
                          // Invalidate provider to force refresh
                          return ref.refresh(leaderboardProvider(contest.id));
                       },
                       child: ListView.builder(
                         physics: const AlwaysScrollableScrollPhysics(),
                         itemCount: entries.length,
                         itemBuilder: (context, index) {
                           final data = entries[index];
                           final rank = data['rank'] ?? (index + 1);
                           final name = data['displayName'] ?? 'User'; // D1 might store userId lookup or name
                           // Note: Worker stores 'userId', 'teamName'.
                           // If display name is missing in D1 leaderboard JSON, we might show teamName
                           final isCurrentUser = data['userId'] == FirebaseAuth.instance.currentUser?.uid;
                           
                           // Correction: Use local User Provider for current user to show latest name
                           String display = name;
                           if (isCurrentUser) {
                              final currentUser = ref.read(userEntityProvider).value;
                              if (currentUser != null && currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
                                 display = currentUser.displayName!;
                              }
                           } else if (name.startsWith("Player ")) {
                              // Optional: Ensure we don't show "Player User" if possible
                           }
                           
                           final points = data['points'] ?? 0;
                            final teamIdFromData = data['teamId'] ?? '';
                            

                            return InkWell(
                              onTap: teamIdFromData.isNotEmpty 
                                ? () => _showTeamPitchView(context, ref, data)
                                : null,
                              child: Container(
                             color: isCurrentUser ? Colors.indigo.withOpacity(0.05) : Colors.white,
                             child: ListTile(
                               leading: CircleAvatar(
                                 backgroundColor: isCurrentUser ? Colors.indigo : Colors.grey[300],
                                 child: Text("$rank", style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black)),
                               ),
                               title: Text(display, style: TextStyle(fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal)),
                               subtitle: Text("${data['teamName'] ?? 'Team'} • ${points.toStringAsFixed(0)} stats"), // Format stats
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isCurrentUser) const Icon(Icons.star, color: Colors.orange, size: 16),
                                      if (teamIdFromData.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                                      ],
                                    ],
                                  ),
                             ),
                           ),
                            );
                         }
                       ),
                     );
                  }
                );
             }
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CricketRoomModel contest) {
    if (widget.match?.status == 'Live' || widget.match?.status == 'Completed') {
       return const SizedBox.shrink(); // Hide join option for live/completed matches
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleJoin(context, contest),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Unlock Participation for ${contest.accessUsage.toStringAsFixed(0)} Axe", 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleJoin(BuildContext context, CricketRoomModel contest) {
     final userAsync = ref.read(userEntityProvider);
     final currentBalance = userAsync.value?.accessCredits ?? 0.0;
     
     if (currentBalance < contest.accessUsage) {
       _showLowBalanceDialog(context, contest.accessUsage - currentBalance);
       return;
     }

     final allTeams = ref.watch(teamProvider);
     
     // Fallback matchId
     final matchId = (widget.match?.id ?? widget.matchId ?? contest.matchId).toString();
     if (matchId == 'null' || matchId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Match context missing.")));
        return;
     }

     final myTeams = allTeams.where((t) => t.matchId == matchId).toList();

     // Check which teams already joined THIS contest
     final allJoined = ref.read(userContestProvider);
     final joinedTeamIds = allJoined
         .where((uc) => uc.contestId == contest.id)
         .map((uc) => uc.teamId)
         .toSet();

     showModalBottomSheet(
       context: context,
       builder: (ctx) => Container(
         padding: const EdgeInsets.all(16),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text("Select Team to Join", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 TextButton.icon(
                   onPressed: () {
                     Navigator.pop(ctx);
                     if (widget.match != null) {
                        context.push('/match/${widget.match!.id}/create-team', extra: widget.match);
                     } else {
                        // Fallback navigation if widget.match is missing, though create-team needs match object
                        // We might need to fetch match or error. For now, assuming context exists.
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot create team: Match data missing")));
                     }
                   },
                   icon: const Icon(Icons.add, size: 18),
                   label: const Text("Create New Team"),
                 )
               ],
             ),
             const SizedBox(height: 16),
             if (myTeams.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No teams created yet."),
                )
             else
               Expanded(
                 child: ListView.builder(
                   itemCount: myTeams.length,
                   itemBuilder: (ctx, index) {
                     final team = myTeams[index];
                     final isJoined = joinedTeamIds.contains(team.id);

                     return ListTile(
                       title: Text(team.teamName),
                       subtitle: Text("C: ${team.captainId} | VC: ${team.viceCaptainId}"),
                       trailing: ElevatedButton(
                         onPressed: isJoined ? null : () { 
                           Navigator.pop(ctx);
                           _confirmJoin(context, team, contest);
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: isJoined ? Colors.grey : Colors.green,
                           foregroundColor: Colors.white,
                         ),
                         child: Text(isJoined ? "Participating" : "Select"),
                       ),
                     );
                   },
                 ),
               ),
           ],
         ),
       )
     );
  }

  void _showLowBalanceDialog(BuildContext context, double deficit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Low Balance"),
        content: Text("You need ${deficit.toStringAsFixed(0)} Axe more to unlock this participation."), // Keep currency consistent
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet'); // Navigate to Add Cash
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("ADD AXE"), // Consistent with Wallet
          )
        ],
      )
    );
  }

  bool _isTeamPreviewOutOfSync(TeamEntity previewTeam, TeamEntity persistedTeam) {
    if (previewTeam.id != persistedTeam.id) return true;
    if (previewTeam.teamName != persistedTeam.teamName) return true;
    if (previewTeam.captainId != persistedTeam.captainId) return true;
    if (previewTeam.viceCaptainId != persistedTeam.viceCaptainId) return true;

    final previewIds = previewTeam.players
        .map((p) => p.id)
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();
    final persistedIds = persistedTeam.players
        .map((p) => p.id)
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();

    if (previewIds.length != persistedIds.length) return true;
    for (var i = 0; i < previewIds.length; i++) {
      if (previewIds[i] != persistedIds[i]) return true;
    }
    return false;
  }

  void _confirmJoin(BuildContext context, TeamEntity team, CricketRoomModel contest) {
    final persistedTeamPreviewFuture = ref
        .read(teamProvider.notifier)
        .getTeamById(team.id, matchId: team.matchId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unlock Participation Confirmation"),
        content: FutureBuilder<TeamEntity>(
          future: persistedTeamPreviewFuture,
          builder: (context, snapshot) {
            final previewTeam = snapshot.data ?? team;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Unlock Interaction for '${contest.category}' using Team '${previewTeam.teamName}'?",
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      _disclaimerRow("Platform charge is for interaction access only."),
                      _disclaimerRow("Platform does not distribute benefits/payouts."),
                      _disclaimerRow("Hosts independently provide vouchers/coupons."),
                    ],
                  ),
                ),
                const Divider(height: 20),
                Text("Access Usage: ${contest.accessUsage} Credits", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              // Show Loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(child: CircularProgressIndicator());
                },
              );

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                   Navigator.pop(context); 
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to join")));
                   return;
                }

                final persistedTeam = await ref
                    .read(teamProvider.notifier)
                    .getTeamById(team.id, matchId: team.matchId);

                debugPrint("[JOIN_ATTEMPT] hasSavedTeam=${persistedTeam.isPersisted}");
                if (!persistedTeam.isPersisted) {
                  throw Exception("TEAM_NOT_SAVED");
                }

                if (_isTeamPreviewOutOfSync(team, persistedTeam)) {
                  ref.invalidate(teamProvider);
                }

                final persistedPlayerIds = persistedTeam.players
                    .map((p) => p.id)
                    .where((id) => id.isNotEmpty)
                    .toSet()
                    .toList();
                if (persistedPlayerIds.isEmpty) {
                  throw Exception("TEAM_DATA_CORRUPT");
                }

                final joinedContest = UserContestEntity(
                  id: const Uuid().v4(),
                  userId: user.uid,
                  contestId: contest.id,
                  matchId: persistedTeam.matchId,
                  teamId: persistedTeam.id,
                  teamName: persistedTeam.teamName,
                  entryFee: contest.accessUsage,
                  joinedAt: DateTime.now(),
                  contestName: contest.category,
                );
                
                debugPrint("[UNLOCK_ACTION] Unlocking participation for ${contest.category}");

                await ref.read(userContestProvider.notifier).joinContest(
                  joinedContest,
                  playerIds: persistedPlayerIds,
                );

                if (!context.mounted) return;
                Navigator.pop(context); // Close loading
                
                // Show Success Dialog with Animation
                if (context.mounted) {
                   _showSuccessDialog(context, contest.category);
                }

              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Failed to join: $e"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("UNLOCK PARTICIPATION")
          )
        ],
      )
    );
  }

  void _showTeamPitchView(BuildContext context, WidgetRef ref, Map<String, dynamic> leaderboardEntry) {
    final teamId = leaderboardEntry['teamId'] ?? '';
    final teamName = leaderboardEntry['teamName'] ?? 'Team';
    final totalPoints = (leaderboardEntry['points'] ?? 0).toDouble();
    final matchId = _resolvedMatchId ?? widget.contest?.matchId ?? widget.matchId ?? '';
    
    if (teamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team data not available')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TeamPitchViewSheet(
        teamId: teamId,
        teamName: teamName,
        totalPoints: totalPoints,
        matchId: matchId,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String contestName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie Animation (Success Check)
              SizedBox(
                width: 150,
                height: 150,
                child: Lottie.network(
                  'https://assets2.lottiefiles.com/packages/lf20_u4yrau.json',
                  repeat: false,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.check_circle, color: Colors.green, size: 80);
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text("Interaction Unlocked!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 8),
              Text("You successfully unlocked participation for '$contestName'", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14)
                  ),
                  child: const Text("AWESOME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  Widget _disclaimerRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 10, color: Colors.amber),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 9, color: Colors.black87))),
        ],
      ),
    );
  }
}
