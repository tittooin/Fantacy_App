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
  List<CricketMatchModel> _completedMatches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    try {
      final qs = await FirebaseFirestore.instance.collection('matches')
          .orderBy('startDate', descending: true)
          .limit(50)
          .get();
      
      final all = qs.docs.map((d) => CricketMatchModel.fromMap(d.data())).toList();
      
      if(mounted) {
        setState(() {
          _upcomingMatches = all.where((m) => m.status == 'Upcoming' || m.status == 'Live').toList();
          _completedMatches = all.where((m) => m.status == 'Completed').toList();
        });
      }
    } catch (e) {
      debugPrint("Matches Fetch Error: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _showMatchSelectionDialog() {
    if (_upcomingMatches.isEmpty) {
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
             itemCount: _upcomingMatches.length,
             separatorBuilder: (_, __) => const Divider(),
             itemBuilder: (ctx, i) {
               final m = _upcomingMatches[i];
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

  Widget _buildMatchTab({required List<CricketMatchModel> matches, required String emptyMsg}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: matches.isEmpty 
        ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(50), child: Text(emptyMsg, style: const TextStyle(color: Colors.grey))))])
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) => MatchCard(match: matches[index], onPrivateContest: () {
               context.push('/match/${matches[index].id}/create-private-contest', extra: matches[index]);
            }),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);
    final walletBalance = userAsync.value?.walletBalance ?? 0.0;
    
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
                  _buildMatchTab(matches: _upcomingMatches, emptyMsg: "No Upcoming Matches.\nPull to Refresh."),
                  _buildMatchTab(matches: _completedMatches, emptyMsg: "No Completed Matches."),
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
