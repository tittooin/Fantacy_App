import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:intl/intl.dart';
import 'package:axevora11/core/widgets/loading_skeleton.dart';

import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/home/presentation/providers/matches_provider.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<CricketMatchModel> _upcomingMatches = [];
<<<<<<< HEAD
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
=======
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
>>>>>>> dev-update
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
<<<<<<< HEAD
             itemCount: _upcomingMatches.length,
             separatorBuilder: (_, __) => const Divider(),
             itemBuilder: (ctx, i) {
               final m = _upcomingMatches[i];
=======
             itemCount: upcomingMatches.length,
             separatorBuilder: (_, __) => const Divider(),
             itemBuilder: (ctx, i) {
               final m = upcomingMatches[i];
>>>>>>> dev-update
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

<<<<<<< HEAD
  Widget _buildMatchTab({required List<CricketMatchModel> matches, required String emptyMsg}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
=======
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
>>>>>>> dev-update
    
    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: matches.isEmpty 
        ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(50), child: Text(emptyMsg, style: const TextStyle(color: Colors.grey))))])
        : ListView.builder(
<<<<<<< HEAD
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) => MatchCard(match: matches[index], onPrivateContest: () {
               context.push('/match/${matches[index].id}/create-private-contest', extra: matches[index]);
            }),
          ),
=======
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final isLive = match.status == 'Live';
                final isLineupOut = match.lineupStatus == 'Confirmed';
                
                return MatchCard(
                  match: match,
                  onPrivateContest: () {
                     context.push('/match/${match.id}/create-private-contest', extra: match);
                  },
                  onTap: () {
                     if (match.status == 'Upcoming' || match.status == 'Live') {
                        context.push('/match/${match.id}', extra: match);
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Completed")));
                     }
                  }
                );
              },
            ),
>>>>>>> dev-update
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);
    final walletBalance = userAsync.value?.walletBalance ?? 0.0;
<<<<<<< HEAD
    
=======
    final matchesState = ref.watch(matchesProvider);

>>>>>>> dev-update
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
<<<<<<< HEAD
                  _buildMatchTab(matches: _upcomingMatches, emptyMsg: "No Upcoming Matches.\nPull to Refresh."),
                  _buildMatchTab(matches: _completedMatches, emptyMsg: "No Completed Matches."),
=======
                  _buildMatchTab(matches: matchesState.upcoming, emptyMsg: "No Upcoming Matches.\nPull to Refresh."),
                  _buildMatchTab(matches: matchesState.completed, emptyMsg: "No Completed Matches."),
>>>>>>> dev-update
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
<<<<<<< HEAD

  const MatchCard({super.key, required this.match, required this.onPrivateContest});
=======
  final VoidCallback onTap;

  const MatchCard({super.key, required this.match, required this.onPrivateContest, required this.onTap});

  String _getFlagUrl(String teamName) {
    // Basic mapping for major teams if URL is missing
    final lower = teamName.toLowerCase();
    if (lower.contains('ind')) return 'https://flagcdn.com/w80/in.png';
    if (lower.contains('aus')) return 'https://flagcdn.com/w80/au.png';
    if (lower.contains('eng')) return 'https://flagcdn.com/w80/gb-eng.png';
    if (lower.contains('sa') || lower.contains('africa')) return 'https://flagcdn.com/w80/za.png';
    if (lower.contains('nz') || lower.contains('zealand')) return 'https://flagcdn.com/w80/nz.png';
    if (lower.contains('pak')) return 'https://flagcdn.com/w80/pk.png';
    if (lower.contains('sl') || lower.contains('lanka')) return 'https://flagcdn.com/w80/lk.png';
    if (lower.contains('wi') || lower.contains('west')) return 'https://flagcdn.com/w80/bq-bo.png'; // Prox
    if (lower.contains('ban')) return 'https://flagcdn.com/w80/bd.png';
    if (lower.contains('afg')) return 'https://flagcdn.com/w80/af.png';
    return '';
  }
>>>>>>> dev-update

  @override
  Widget build(BuildContext context) {
    bool isLive = match.status == 'Live';
<<<<<<< HEAD

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E), // Deep Navy Blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0,2))]
=======
    String t1Img = match.team1Img.isNotEmpty ? match.team1Img : _getFlagUrl(match.team1ShortName);
    String t2Img = match.team2Img.isNotEmpty ? match.team2Img : _getFlagUrl(match.team2ShortName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0,4))],
        border: Border.all(color: Colors.grey.shade200)
>>>>>>> dev-update
      ),
      child: Column(
        children: [
          // Header Row (Status + Lineups)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
<<<<<<< HEAD
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
=======
                Text(match.seriesName, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                if(match.lineupStatus == 'Out')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 6),
                      SizedBox(width: 4),
                      Text("LINEUPS OUT", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
>>>>>>> dev-update
                    ],
                  ),
                )
              ],
            ),
          ),
          
<<<<<<< HEAD
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
=======
          const Divider(height: 24, thickness: 0.5),
>>>>>>> dev-update

          // Teams Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
<<<<<<< HEAD
                 _buildTeamCircle(match.team1ShortName, match.team1Img),
                 Column(
                   children: [
                     const Text("VS", style: TextStyle(color: Colors.white54, fontSize: 12)),
                     const SizedBox(height: 4),
                     Text(isLive ? "In Progress" : "Starts 7:30 PM", style: const TextStyle(color: Colors.white70, fontSize: 10))
                   ],
                 ),
                 _buildTeamCircle(match.team2ShortName, match.team2Img),
=======
                 _buildTeamCircle(match.team1ShortName, t1Img),
                 Column(
                   children: [
                     if (isLive) 
                        const Text("● LIVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                     else
                        Text(DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(match.startDate)), style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                     
                     const SizedBox(height: 4),
                     const Text("vs", style: TextStyle(fontSize: 12, color: Colors.grey)),
                   ],
                 ),
                 _buildTeamCircle(match.team2ShortName, t2Img),
>>>>>>> dev-update
              ],
            ),
          ),
          
          const SizedBox(height: 20),

<<<<<<< HEAD
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF283593), // Slightly lighter blue for footer
=======
          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
>>>>>>> dev-update
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Row(
                   children: [
<<<<<<< HEAD
                     Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                     SizedBox(width: 4),
                     Text("MEGA ₹1 Crore", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
=======
                     Icon(Icons.emoji_events_outlined, color: Colors.grey, size: 16),
                     SizedBox(width: 4),
                     Text("Mega ₹1 Crore", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
>>>>>>> dev-update
                   ],
                 ),
                 
                 Row(
                   children: [
                     SizedBox(
<<<<<<< HEAD
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
=======
                       height: 28,
                       child: OutlinedButton(
                         onPressed: onPrivateContest,
                         style: OutlinedButton.styleFrom(
                           side: BorderSide(color: Colors.indigo.shade200),
                           padding: const EdgeInsets.symmetric(horizontal: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                         ),
                         child: const Text("Create Private", style: TextStyle(fontSize: 10, color: Colors.indigo)),
>>>>>>> dev-update
                       ),
                     )
                   ],
                 )
              ],
            ),
          )
        ],
      ),
    ));
  }

  Widget _buildTeamCircle(String code, String img) {
<<<<<<< HEAD
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
=======
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: (img.isNotEmpty) ? NetworkImage(img) : null,
          child: img.isEmpty ? Text(code[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)) : null,
        ),
        const SizedBox(height: 8),
        Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
>>>>>>> dev-update
      ],
    );
  }
}
