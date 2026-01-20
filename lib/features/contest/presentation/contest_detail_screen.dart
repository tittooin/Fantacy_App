import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/features/cricket_api/domain/contest_model.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart'; // Added Lottie

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/team/presentation/providers/team_provider.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
import 'package:axevora11/features/contest/presentation/providers/user_contest_provider.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ContestDetailScreen extends ConsumerStatefulWidget {
  final String contestId;
  final ContestModel? contest; // Made optional
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
  ContestModel? _contest;
  bool _isLoading = false;
  String? _error;
  late final String? _resolvedMatchId;

  @override
  void initState() {
    super.initState();
    // Resolve matchID from either direct ID or Match Object
    _resolvedMatchId = widget.matchId ?? widget.match?.id.toString();
    
    _contest = widget.contest;
    if (_contest == null) {
      _fetchContest();
    }
  }

  Future<void> _fetchContest() async {
    final mId = (widget.match?.id ?? widget.matchId)?.toString();
    if (mId == null) {
      setState(() => _error = "Match ID missing");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(mId!)
          .collection('contests')
          .doc(widget.contestId)
          .get();

      if (doc.exists) {
         setState(() {
           _contest = ContestModel.fromJson(doc.data()!);
           _isLoading = false;
         });
      } else {
         setState(() {
           _error = "Contest not found";
           _isLoading = false;
         });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
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
              title: const Text("Contest Details", style: TextStyle(fontSize: 16)),
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
                  Tab(text: "Winnings"),
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
                      _buildWinningsTab(contest),
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

  Widget _buildHeader(ContestModel contest) {
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
                  const Text("Prize Pool", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Row(
                    children: [
                       Text("₹${contest.prizePool}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
              if (contest.isGuaranteed)
                 Chip(
                   label: const Text("Guaranteed", style: TextStyle(fontSize: 10)),
                   backgroundColor: Colors.blue.withOpacity(0.1),
                   labelStyle: const TextStyle(color: Colors.blue), 
                   padding: EdgeInsets.zero,
                   visualDensity: VisualDensity.compact,
                 )
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: contest.totalSpots > 0 ? contest.filledSpots / contest.totalSpots : 0,
            backgroundColor: Colors.grey.shade200,
            color: Colors.orange,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          StreamBuilder<DocumentSnapshot>(
             stream: FirebaseFirestore.instance.collection('matches').doc(_resolvedMatchId ?? contest.id).snapshots(),
             builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final matchScore = data['matchScore'] as Map<String, dynamic>?;
                
                if (matchScore != null && matchScore.isNotEmpty) {
                   final t1 = matchScore['team1Score'] ?? "";
                   final t2 = matchScore['team2Score'] ?? "";
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
                return const SizedBox.shrink();
             }
          ),
          // const SizedBox(height: 8), // Removed as margin included above
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${contest.totalSpots - contest.filledSpots} spots left", 
                style: const TextStyle(color: Colors.orange, fontSize: 12)
              ),
              Text("${contest.totalSpots} spots", 
                style: const TextStyle(color: Colors.grey, fontSize: 12)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinningsTab(ContestModel contest) {
    if (contest.winningBreakdown.isEmpty) {
      return const Center(child: Text("Prize breakdown will be updated soon."));
    }

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text("Rank vs Winnings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        ...contest.winningBreakdown.map((tier) {
            final start = tier['rankStart'];
            final end = tier['rankEnd'];
            final amount = tier['amount'];
            final rankText = start == end ? "#$start" : "#$start - #$end";
            
            return Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rankText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("₹$amount"),
                ],
              ),
            );
        }).toList(),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "Note: This is a projected breakdown.\nActual winnings may vary based on participation.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildWinningRow(int rank, double amount) {
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
          Text("₹${amount.toStringAsFixed(0)}"),
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

  Widget _buildLeaderboardTab(ContestModel contest) {
    // Rely on resolved ID from initState
    final matchId = _resolvedMatchId; 
    
    if (matchId == null) {
      return const Center(child: Text("Error: Match ID not found"));
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.amber.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: const Text(
            "Points & Ranks are updated at the end of each over.",
            style: TextStyle(color: Colors.amber, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .doc(matchId)
                .collection('contests')
                .doc(contest.id)
                .collection('entries')
                .orderBy('points', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                 return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
              }
      
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                 return RefreshIndicator(
                   onRefresh: _handleRefresh,
                   child: ListView(
                     physics: const AlwaysScrollableScrollPhysics(), 
                     children: const [
                       SizedBox(height: 200),
                       Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("Be the first to join!", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                       ),
                     ],
                   ),
                 );
              }
      
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final rank = index + 1; 
                    final name = data['displayName'] ?? "User";
                    final team = data['teamName'] ?? "Team 1";
                    final points = data['points'] ?? 0;
                    final isCurrentUser = data['userId'] == FirebaseAuth.instance.currentUser?.uid;
      
                    return Container(
                      color: isCurrentUser ? Colors.indigo.withOpacity(0.05) : Colors.white,
                      child: ListTile(
                        onTap: () {
                           final userId = data['userId'] as String?;
                           if (userId != null) {
                             context.push('/profile/$userId');
                           }
                        },
                        leading: CircleAvatar(
                          backgroundColor: isCurrentUser ? Colors.indigo : Colors.grey[300],
                          child: Text("$rank", style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black)),
                        ),
                        title: Text(name, style: TextStyle(fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(team, style: const TextStyle(fontSize: 12)),
                        trailing: Text("$points pts", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ContestModel contest) {
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
              child: Text("Join for ₹${contest.entryFee.toStringAsFixed(0)}", 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleJoin(BuildContext context, ContestModel contest) {
     final userAsync = ref.read(userEntityProvider);
     final currentBalance = userAsync.value?.walletBalance ?? 0.0;
     
     if (currentBalance < contest.entryFee) {
       _showLowBalanceDialog(context, contest.entryFee - currentBalance);
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

  void _confirmJoin(BuildContext context, TeamEntity team, ContestModel contest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Join Contest Confirmation"),
        content: Text("Join '${contest.category}' with Team '${team.teamName}'?\nEntry: ₹${contest.entryFee}"),
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

                final joinedContest = UserContestEntity(
                  id: const Uuid().v4(),
                  userId: user.uid,
                  contestId: contest.id,
                  matchId: team.matchId,
                  teamId: team.id,
                  teamName: team.teamName,
                  entryFee: contest.entryFee,
                  joinedAt: DateTime.now(),
                  contestName: contest.category,
                );

                await ref.read(userContestProvider.notifier).joinContest(joinedContest);

                Navigator.pop(context); // Close loading
                
                // Show Success Dialog with Animation
                if (context.mounted) {
                   _showSuccessDialog(context, contest.category);
                }

              } catch (e) {
                Navigator.pop(context); // Close loading
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
              const Text("Contest Joined!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 8),
              Text("You successfully joined '$contestName'", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
}
