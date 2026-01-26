import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/domain/contest_model.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
import 'package:axevora11/features/team/presentation/providers/team_provider.dart';
import 'package:axevora11/features/contest/presentation/providers/user_contest_provider.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:axevora11/features/cricket_api/presentation/widgets/match_score_header.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  final CricketMatchModel? match; // Optional, can be null if deep linked

  const MatchDetailScreen({super.key, required this.matchId, this.match});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  CricketMatchModel? _fetchedMatch;
  bool _isLoadingMatch = false;

  @override
  void initState() {
    super.initState();
    if (widget.match == null) {
      _fetchMatchData();
    } else {
      _fetchedMatch = widget.match;
    }
  }

  Future<void> _fetchMatchData() async {
    setState(() => _isLoadingMatch = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _fetchedMatch = CricketMatchModel.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      debugPrint("Error fetching match: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMatch = false);
    }
  }

  CricketMatchModel? get _effectiveMatch => widget.match ?? _fetchedMatch;

  @override
  Widget build(BuildContext context) {
    // If match is passed, use it. If not, we might need to fetch it (skipping fetch logic for now, assuming passed from Home)
    final displayMatch = _effectiveMatch;
    
    final matchTitle = displayMatch != null 
        ? "${displayMatch.team1ShortName} vs ${displayMatch.team2ShortName}"
        : "Match Contests";
        
    final isLiveOrCompleted = displayMatch?.status == 'Live' || displayMatch?.status == 'Completed';

    // Watch teams and contests
    final allTeams = ref.watch(teamProvider);
    final myTeams = allTeams.where((t) => t.matchId == widget.matchId).toList();

    final allJoined = ref.watch(userContestProvider);
    final myContests = allJoined.where((c) => c.matchId == widget.matchId).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 500;
        final mobileContent = DefaultTabController(
          length: 3,
          initialIndex: isLiveOrCompleted ? 1 : 0, // Default to "My Contests" if Live/Completed
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.indigo,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/home'),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(matchTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (_effectiveMatch != null) ...[
                     Text("${_effectiveMatch!.seriesName} • ${_effectiveMatch!.venue}", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                     if (_effectiveMatch!.lineupStatus == 'Confirmed')
                       Container(
                         margin: const EdgeInsets.only(top: 2),
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                         child: const Text("Lineups Announced", style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                       )
                  ]
                ],
              ),
              bottom: PreferredSize(
                 preferredSize: const Size.fromHeight(75),
                 child: Column(
                   children: [
                     Container(
                       width: double.infinity,
                       color: Colors.black26,
                       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                       child: const Text(
                         "⚠ Only players in the Playing XI earn fantasy points.",
                         style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                         textAlign: TextAlign.center,
                       ),
                     ),
                     TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      tabs: [
                        const Tab(text: "Contests"),
                        Tab(text: "My Contests (${myContests.length})"),
                        Tab(text: "My Teams (${myTeams.length})"),
                      ],
                    ),
                   ],
                 ),
              ),
            ),
            body: TabBarView(
              children: [
                _buildContestsTab(),
                _buildMyContestsTab(),
                _buildMyTeamsTab(myTeams),
              ],
            ),
          ),
        );


        if (isLargeScreen) {
          return Scaffold(
            backgroundColor: Colors.grey[900], // Dark background for desktop
            body: Center(
              child: Container(
                width: 450, // Mobile width simulation
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

  Widget _buildContestsTab() {
    final showScore = _effectiveMatch?.status == 'Live' || _effectiveMatch?.status == 'Completed';
    
    return Column(
      children: [
        if (showScore) MatchScoreHeader(matchId: widget.matchId),
        // Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All", true),
                const SizedBox(width: 8),
                _buildFilterChip("Mega", false),
                const SizedBox(width: 8),
                _buildFilterChip("Hot", false),
                const SizedBox(width: 8),
                _buildFilterChip("Head 2 Head", false),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .doc(widget.matchId)
                .collection('contests')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No Contests Active", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB if needed
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  try {
                    final contest = ContestModel.fromJson(data);
                    return ContestCard(contest: contest, match: _effectiveMatch, matchId: widget.matchId);
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Chip(
      label: Text(label),
      backgroundColor: isSelected ? Colors.black87 : Colors.grey.shade200,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildMyContestsTab() {
    final allJoined = ref.watch(userContestProvider);
    final myContests = allJoined.where((c) => c.matchId == widget.matchId).toList();

    if (myContests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("You haven't joined any contests yet.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Switch to Contests tab (Index 0)
                DefaultTabController.of(context).animateTo(0);
              },
              child: const Text("Join a Contest"),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myContests.length + 1, // +1 for Disclaimer
      itemBuilder: (context, index) {
        if (index == 0) {
           return Container(
             margin: const EdgeInsets.only(bottom: 12),
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
             child: const Row(
               children: [
                 Icon(Icons.info_outline, size: 20, color: Colors.blue),
                 SizedBox(width: 8),
                 Expanded(child: Text("Scores & Ranks update at the end of each over. Only Playing XI earns points.", style: TextStyle(color: Colors.blue, fontSize: 12))),
               ],
             ),
           );
        }
        
        final contest = myContests[index - 1]; // Offset index
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
               // Navigation provided by context.push needs a ContestModel
               // Since UserContestEntity is different, we either fetch or mock
               // For now, let's navigate to contest detail 
               // Note: We might lack full contest data here, so ideally we fetch it.
               // But usually we just want to see the Leaderboard.
               context.push('/contest/${contest.contestId}', extra: {
                 'contestId': contest.contestId, 
                 'matchId': contest.matchId, // Pass matchId for fetching
               }); 
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(contest.contestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Entry: ₹${contest.entryFee.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Team: ${contest.teamName}", style: const TextStyle(color: Colors.grey)),
                      Text("Joined: ${_formatDate(contest.joinedAt)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}";
  }

  Widget _buildMyTeamsTab(List<TeamEntity> teams) {
    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("You haven't created any teams yet.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                 if (_effectiveMatch != null) {
                    context.push('/match/${widget.matchId}/create-team', extra: _effectiveMatch!);
                 }
              },
              child: const Text("Create Team"),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        final captain = team.players.firstWhere((p) => p.id == team.captainId);
        final viceCaptain = team.players.firstWhere((p) => p.id == team.viceCaptainId);
        
        // Count roles
        final wk = team.players.where((p) => p.role == 'WK').length;
        final bat = team.players.where((p) => p.role == 'BAT').length;
        final ar = team.players.where((p) => p.role == 'AR').length;
        final bowl = team.players.where((p) => p.role == 'BOWL').length;

        return Card(
           margin: const EdgeInsets.only(bottom: 12),
           child: InkWell(
             onTap: () {
               // Check if match is Live or Completed
               if (_effectiveMatch?.status == 'Live' || _effectiveMatch?.status == 'Completed') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match is Live/Completed. Team editing is disabled.")));
                  return;
               }

               // Retrieve team names or fallback
               final t1 = _effectiveMatch?.team1ShortName ?? "Home";
               final t2 = _effectiveMatch?.team2ShortName ?? "Away";

               // Use the existing nested route for preview
               context.push('/match/${widget.matchId}/create-team/preview', extra: {
                 'players': team.players,
                 'team1Name': t1,
                 'team2Name': t2,
                 'isEditMode': true,
                 'match': _effectiveMatch, // Pass full match model for editing
               });
             },
             borderRadius: BorderRadius.circular(12),
             child: Padding(
               padding: const EdgeInsets.all(12),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       Icon(
                         (_effectiveMatch?.status == 'Live' || _effectiveMatch?.status == 'Completed') 
                             ? Icons.visibility 
                             : Icons.edit, 
                         size: 16, 
                         color: (_effectiveMatch?.status == 'Live' || _effectiveMatch?.status == 'Completed')
                             ? Colors.grey
                             : Colors.indigo
                       ),
                     ],
                   ),
                   const Divider(),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                       Column(children: [Text("WK", style: TextStyle(color: Colors.grey, fontSize: 10)), Text("$wk")]),
                       Column(children: [Text("BAT", style: TextStyle(color: Colors.grey, fontSize: 10)), Text("$bat")]),
                       Column(children: [Text("AR", style: TextStyle(color: Colors.grey, fontSize: 10)), Text("$ar")]),
                       Column(children: [Text("BOWL", style: TextStyle(color: Colors.grey, fontSize: 10)), Text("$bowl")]),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Chip(
                         label: Text("C: ${captain.name.split(' ').last}"), 
                         avatar: CircleAvatar(backgroundColor: Colors.black, child: Text("C", style: TextStyle(fontSize: 10))),
                         visualDensity: VisualDensity.compact,
                         padding: EdgeInsets.zero,
                       ),
                       const SizedBox(width: 8),
                        Chip(
                         label: Text("VC: ${viceCaptain.name.split(' ').last}"), 
                         avatar: CircleAvatar(backgroundColor: Colors.white, child: Text("VC", style: TextStyle(fontSize: 10, color: Colors.black))),
                         visualDensity: VisualDensity.compact,
                         padding: EdgeInsets.zero,
                       ),
                     ],
                   )
                 ],
               ),
             ),
           ),
        );
      },
    );
  }
}

class ContestCard extends ConsumerWidget {
  final ContestModel contest;
  final CricketMatchModel? match; // Threading match
  final String matchId;

  const ContestCard({super.key, required this.contest, this.match, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... code truncated ...
    // Using filtered team count for debugging if needed
    
    final double filledPercent = contest.totalSpots > 0 ? (contest.filledSpots / contest.totalSpots) : 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          debugPrint("APP_DEBUG: Contest Card Tapped! ID: ${contest.id}");
          try {
             context.push('/contest/${contest.id}', extra: {
               'contest': contest,
               'match': match,
             });
          } catch (e) {
            debugPrint("APP_DEBUG: Navigation Error: $e");
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Prize Pool", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("₹${contest.prizePool.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: (match?.status == 'Live' || match?.status == 'Completed') 
                        ? null 
                        : () {
                      _handleJoin(context, ref);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(80, 36),
                    ),
                    child: Text(
                       (match?.status == 'Live' || match?.status == 'Completed') 
                         ? "View" 
                         : "₹${contest.entryFee.toStringAsFixed(0)}"
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: filledPercent,
                backgroundColor: Colors.grey.shade200,
                color: Colors.orange,
                minHeight: 4,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${contest.totalSpots - contest.filledSpots} spots left", style: const TextStyle(fontSize: 11, color: Colors.orange)),
                  Text("${contest.totalSpots} spots", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.emoji_events, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  // Since winningBreakdown was removed, just showing generic text
                  const Text("Multiple Winners", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const Spacer(),
                  if (contest.isGuaranteed) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 10, color: Colors.blue),
                          SizedBox(width: 4),
                          Text("Guaranteed", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleJoin(BuildContext context, WidgetRef ref) {
     final userAsync = ref.read(userEntityProvider);
     final currentBalance = userAsync.value?.walletBalance ?? 0.0;

     if (currentBalance < contest.entryFee) {
       _showLowBalanceDialog(context, contest.entryFee - currentBalance);
       return;
     }

     final allTeams = ref.watch(teamProvider);
     final myTeams = allTeams.where((t) => t.matchId == matchId).toList(); 

     // Check which teams already joined THIS contest
     final allJoined = ref.read(userContestProvider);
     final joinedTeamIds = allJoined
         .where((uc) => uc.contestId == contest.id)
         .map((uc) => uc.teamId)
         .toSet();

     if (joinedTeamIds.length >= 20) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max 20 teams allowed per contest.")));
        return;
     }

     // Always show selection dialog
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
                     if (match != null) {
                        context.push('/match/${match!.id}/create-team', extra: match!);
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
                         onPressed: isJoined 
                           ? null 
                           : () { 
                               Navigator.pop(ctx);
                               _confirmJoin(context, team, ref);
                             },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: isJoined ? Colors.grey : Colors.green,
                           foregroundColor: Colors.white,
                         ),
                         child: Text(isJoined ? "Joined" : "Select"),
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
        content: Text("You need ₹${deficit.toStringAsFixed(0)} more to join this contest."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet'); // Navigate to Add Cash
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("ADD CASH"),
          )
        ],
      )
    );
  }

  void _confirmJoin(BuildContext context, TeamEntity team, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Join Contest Confirmation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("Join '${contest.category}' with Team '${team.teamName}'?", style: const TextStyle(fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             Text("Entry Fee: ₹${contest.entryFee}", style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
             const Divider(height: 24),
             const Text("• Entry fee is non-refundable.", style: TextStyle(fontSize: 12, color: Colors.grey)),
             const Text("• This is a skill-based contest.", style: TextStyle(fontSize: 12, color: Colors.grey)),
             const Text("• Platform decision is final.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              // Show Loading Dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(child: CircularProgressIndicator());
                },
              );

              try {
                debugPrint("Attempting to join contest: ${contest.category}");
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                   Navigator.pop(context); // Close loading
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to join")));
                   return;
                }

                final joinedContest = UserContestEntity(
                  id: const Uuid().v4(),
                  userId: user.uid,
                  contestId: contest.id,
                  matchId: matchId, 
                  teamId: team.id,
                  teamName: team.teamName,
                  entryFee: contest.entryFee,
                  joinedAt: DateTime.now(),
                  contestName: contest.category, // Use category
                );

                await ref.read(userContestProvider.notifier).joinContest(joinedContest);
                
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Successfully Joined '${contest.category}'! 🎉"))
                );
              } catch (e) {
                Navigator.pop(context); // Close loading
                debugPrint("Join Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Failed to join: $e"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("JOIN NOW")
          )
        ],
      )
    );
  }
}
