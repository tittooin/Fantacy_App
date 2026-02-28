import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_contest_model.dart'; // contains CricketRoomModel
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
import 'package:axevora11/features/team/presentation/providers/team_provider.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';
import 'package:axevora11/features/contest/presentation/providers/user_contest_provider.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/access/presentation/providers/access_provider.dart';

class ContestCard extends StatefulWidget {
  final CricketRoomModel contest;
  final CricketMatchModel? match; // Threading match
  final String matchId;

  const ContestCard({super.key, required this.contest, this.match, required this.matchId});

  @override
  State<ContestCard> createState() => _ContestCardState();
}

class _ContestCardState extends State<ContestCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Calculate filled percentage
        final double filledPercent = widget.contest.totalParticipants > 0 ? (widget.contest.filledParticipants / widget.contest.totalParticipants) : 0;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              debugPrint("APP_DEBUG: Contest Card Tapped! ID: ${widget.contest.id}");
              try {
                 context.push('/contest/${widget.contest.id}', extra: {
                   'contest': widget.contest,
                   'match': widget.match,
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
                          const Text("Interaction Scope", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("${widget.contest.benefitTiers.isNotEmpty ? 'Benefits Included' : 'Standard Room'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      _isLoading 
                        ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton(
                            onPressed: (widget.match?.status == 'Live' || widget.match?.status == 'Completed') 
                                ? null 
                                : () => _handleContestJoin(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              disabledBackgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              minimumSize: const Size(80, 36),
                            ),
                            child: Text(
                               (widget.match?.status == 'Live' || widget.match?.status == 'Completed') 
                                 ? "View" 
                                 : "${widget.contest.accessUsage.toStringAsFixed(0)} Credits"
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
                      Text("${widget.contest.totalParticipants - widget.contest.filledParticipants} spots left", style: const TextStyle(fontSize: 11, color: Colors.orange)),
                      Text("${widget.contest.totalParticipants} spots", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text("Multiple Winners", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const Spacer(),
                      if (widget.contest.category.toLowerCase().contains('mega')) 
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
      },
    );
  }

  void _handleContestJoin(BuildContext context, WidgetRef ref) {
     final userCredits = ref.watch(accessCreditsProvider);

     if (userCredits < widget.contest.accessUsage) {
       _showLowBalanceDialog(context, widget.contest.accessUsage - userCredits);
       return;
     }

     final allTeams = ref.read(teamProvider);
     final myTeams = allTeams.where((t) => t.matchId == widget.matchId).toList(); 

     // Check which teams already joined THIS contest
     final allJoined = ref.read(userContestProvider);
     final joinedTeamIds = allJoined
         .where((uc) => uc.contestId == widget.contest.id)
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
         height: 400,
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text("Confirm Participation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 TextButton.icon(
                   onPressed: () {
                     Navigator.pop(ctx);
                     if (widget.match != null) {
                        context.push('/match/${widget.match!.id}/create-team', extra: widget.match!);
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

                     final captain = team.players.firstWhere((p) => p.id == team.captainId, orElse: () => team.players.first);
                     final viceCaptain = team.players.firstWhere((p) => p.id == team.viceCaptainId, orElse: () => team.players.last);

                     return ListTile(
                       title: Text(team.teamName),
                       subtitle: Text("C: ${captain.name} | VC: ${viceCaptain.name}"),
                       trailing: ElevatedButton(
                         onPressed: isJoined 
                           ? null 
                           : () { 
                                Navigator.pop(ctx);
                                _confirmContestJoin(context, team, ref, widget.contest, widget.matchId);
                              },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: isJoined ? Colors.grey : Colors.green,
                           foregroundColor: Colors.white,
                           elevation: 0,
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
        content: Text("You need ${deficit.toStringAsFixed(0)} Credits more to unlock this interaction."), // Keep currency consistent
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet'); // Navigate to Add Cash
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("ADD CREDITS"), // Consistent with Wallet
          )
        ],
      )
    );
  }

  void _confirmContestJoin(BuildContext context, TeamEntity team, WidgetRef ref, CricketRoomModel contest, String matchIdArg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unlock Participation Confirmation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("Unlock Interaction for '${contest.category}'?", style: const TextStyle(fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   _disclaimerRow("Platform charge is for interaction access only."),
                   _disclaimerRow("Platform does not distribute rewards/payouts."),
                   _disclaimerRow("Hosts independently provide vouchers/coupons."),
                 ],
               ),
             ),
             const Divider(height: 24),
             const Text("• Access charge is non-refundable.", style: TextStyle(fontSize: 12, color: Colors.grey)),
             const Text("• This is a skill-based interaction.", style: TextStyle(fontSize: 12, color: Colors.grey)),
             const Text("• Platform decision is final.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              setState(() => _isLoading = true);

              try {
                debugPrint("Attempting to join contest: ${contest.category}");
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                   setState(() => _isLoading = false);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to join")));
                   return;
                }

                final joinedContest = UserContestEntity(
                  id: const Uuid().v4(),
                  userId: user.uid,
                  contestId: contest.id,
                  matchId: matchIdArg, 
                  teamId: team.id,
                  teamName: team.teamName,
                  entryFee: contest.accessUsage,
                  joinedAt: DateTime.now(),
                  contestName: contest.category, // Use category
                );

                await ref.read(userContestProvider.notifier).joinContest(joinedContest);
                
                if (mounted) setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Unlocked Interaction for '${contest.category}'! 🎉"))
                );
              } catch (e) {
                if (mounted) setState(() => _isLoading = false);
                debugPrint("Join Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Failed to participate: $e"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("UNLOCK PARTICIPATION")
          )
        ],
      )
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
