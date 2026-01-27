import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:intl/intl.dart';
import 'package:axevora11/core/widgets/loading_skeleton.dart';

import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<CricketMatchModel> _upcomingMatches = [];
  @override
  void initState() {
    super.initState();
    // Fetch only if needed (handled by provider logic)
    // Delay slightly to avoid provider unavailable in initState
    Future.microtask(() => ref.read(matchesProvider.notifier).fetchMatches());
  }

  Future<void> _fetchMatches() async {
    // Force Refresh on Pull
    await ref.read(matchesProvider.notifier).fetchMatches(forceRefresh: true);
  }

  void _showMatchSelectionDialog() {
    final matchesState = ref.read(matchesProvider);
    final upcomingMatches = matchesState.upcoming;

    if (upcomingMatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No upcoming matches available.")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select a Match"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
             shrinkWrap: true,
             itemCount: upcomingMatches.length,
             separatorBuilder: (_, __) => const Divider(),
             itemBuilder: (ctx, i) {
               final m = upcomingMatches[i];
               return ListTile(
                 leading: CircleAvatar(
                   backgroundImage: m.team1Img.isNotEmpty ? NetworkImage(m.team1Img) : null,
                   backgroundColor: Colors.indigo.shade100,
                   child: m.team1Img.isEmpty ? Text(m.team1ShortName[0]) : null,
                 ),
                 title: Text("${m.team1ShortName} vs ${m.team2ShortName}"),
                 subtitle: Text(m.seriesName, style: const TextStyle(fontSize: 10)),
                 trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                 onTap: () {
                   Navigator.pop(ctx);
                   context.push('/match/${m.id}/create-private-contest', extra: m);
                 }
               );
             }
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))]
      )
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final matchDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (matchDate == today) {
      return "Today, ${DateFormat('h:mm a').format(dateTime)}";
    } else if (matchDate == tomorrow) {
      return "Tomorrow, ${DateFormat('h:mm a').format(dateTime)}";
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  Widget _buildMatchTab({required List<CricketMatchModel> matches, required String emptyMsg}) {
    final state = ref.watch(matchesProvider);

    if (state.isLoading && matches.isEmpty) return const Center(child: CircularProgressIndicator());
    
    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: matches.isEmpty 
        ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(50), child: Text(emptyMsg, style: const TextStyle(color: Colors.grey))))])
        : ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final isLive = match.status == 'Live';
                final isLineupOut = match.lineupStatus == 'Confirmed';
                
                return GestureDetector(
                  onTap: () {
                    if (match.status == 'Upcoming') {
                      context.push('/contest/create/${match.id}', extra: match);
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only Upcoming matches are playable.")));
                    }
                  }, 
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                           colors: [Colors.white, Colors.blue.shade50.withOpacity(0.5)],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight
                        )
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(match.seriesName, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                              if (isLineupOut)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: const Text("LINEUPS OUT", style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                                )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Team 1
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.indigo.shade50,
                                    backgroundImage: match.team1Img.isNotEmpty ? NetworkImage(match.team1Img) : null,
                                    child: match.team1Img.isEmpty ? Text(match.team1ShortName[0]) : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(match.team1ShortName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              
                              // VS/Status
                              Column(
                                children: [
                                  if (isLive) 
                                    const Text("LIVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                                  else
                                    Text(_formatTime(match.startDate), style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  
                                  const SizedBox(height: 4),
                                  const Text("vs", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),

                              // Team 2
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.indigo.shade50,
                                    backgroundImage: match.team2Img.isNotEmpty ? NetworkImage(match.team2Img) : null,
                                    child: match.team2Img.isEmpty ? Text(match.team2ShortName[0]) : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(match.team2ShortName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Mega Contest Badge (Static for now)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Mega Contest", style: TextStyle(fontSize: 10, color: Colors.black54)),
                                Text("₹1 Crore", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);
    final walletBalance = userAsync.value?.walletBalance ?? 0.0;
    final matchesState = ref.watch(matchesProvider);

    final mobileContent = Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3949AB), 
        title: Row(
          children: [
             const Icon(Icons.sports_cricket, color: Colors.orangeAccent, size: 28),
             const SizedBox(width: 8),
             const Text("Axe11", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          InkWell(
            onTap: () => context.push('/wallet'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(walletBalance.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const Icon(Icons.chevron_right, color: Colors.white54, size: 16)
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                if(userAsync.value != null) context.push('/profile/${userAsync.value!.uid}');
              },
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(userAsync.value?.photoUrl ?? "https://i.pravatar.cc/150?img=33"),
              ),
            ),
          )
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Banner Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF8E24AA)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Welcome back, Tittoo", style: TextStyle(color: Colors.white70, fontSize: 12)),
                   const SizedBox(height: 4),
                   const Text("IPL 2026 is Here!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                   const Text("Join India's biggest fantasy league now.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                   const SizedBox(height: 20),
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton.icon(
                       onPressed: _showMatchSelectionDialog,
                       icon: const Icon(Icons.add_moderator, color: Colors.white), 
                       label: const Text("CREATE PRIVATE CONTEST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43A047), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 4),
                     ),
                   )
                ],
              ),
            ),
            
            // TABS
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Color(0xFF3949AB),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF3949AB),
                indicatorWeight: 3,
                tabs: [Tab(text: "Upcoming"), Tab(text: "Completed")],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildMatchTab(matches: matchesState.upcoming, emptyMsg: "No Upcoming Matches.\nPull to Refresh."),
                  _buildMatchTab(matches: matchesState.completed, emptyMsg: "No Completed Matches."),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          return Scaffold(backgroundColor: Colors.black, body: Center(child: Container(width: 450, color: Colors.white, child: mobileContent)));
        }
        return mobileContent;
      },
    );
  }

class MatchCard extends StatelessWidget {
  final CricketMatchModel match;
  final VoidCallback onPrivateContest;

  const MatchCard({super.key, required this.match, required this.onPrivateContest});

  @override
  Widget build(BuildContext context) {
    bool isLive = match.status == 'Live';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E), // Deep Navy Blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0,2))]
      ),
      child: Column(
        children: [
          // Header Row (Status + Lineups)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                      child: Text(isLive ? "LIVE" : (match.status == 'Upcoming' ? "UPCOMING" : "COMPLETED"), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text("${match.team1ShortName} vs ${match.team2ShortName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                if(match.lineupStatus == 'Out')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                      SizedBox(width: 4),
                      Text("Lineups Out", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),

          // Teams Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 _buildTeamCircle(match.team1ShortName, match.team1Img),
                 Column(
                   children: [
                     const Text("VS", style: TextStyle(color: Colors.white54, fontSize: 12)),
                     const SizedBox(height: 4),
                     Text(isLive ? "In Progress" : "Starts 7:30 PM", style: const TextStyle(color: Colors.white70, fontSize: 10))
                   ],
                 ),
                 _buildTeamCircle(match.team2ShortName, match.team2Img),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF283593), // Slightly lighter blue for footer
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Row(
                   children: [
                     Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                     SizedBox(width: 4),
                     Text("MEGA ₹1 Crore", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                   ],
                 ),
                 
                 Row(
                   children: [
                     SizedBox(
                       height: 32,
                       child: ElevatedButton(
                         onPressed: () => context.push('/match/${match.id}', extra: match),
                         style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43A047), padding: const EdgeInsets.symmetric(horizontal: 16)), // Green
                         child: const Text("Join Contest", style: TextStyle(fontSize: 12)),
                       ),
                     ),
                     const SizedBox(width: 8),
                     SizedBox(
                       height: 32,
                       child: OutlinedButton(
                         onPressed: onPrivateContest,
                         style: OutlinedButton.styleFrom(
                           backgroundColor: const Color(0xFF3949AB), 
                           foregroundColor: Colors.white,
                           side: BorderSide.none,
                           padding: const EdgeInsets.symmetric(horizontal: 16)
                         ),
                         child: const Text("Create Private", style: TextStyle(fontSize: 12)),
                       ),
                     )
                   ],
                 )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTeamCircle(String code, String img) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          backgroundImage: (img.isNotEmpty) ? NetworkImage(img) : null,
          child: img.isEmpty ? Text(code[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)) : null,
        ),
        const SizedBox(width: 12),
        Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
      ],
    );
  }
}
