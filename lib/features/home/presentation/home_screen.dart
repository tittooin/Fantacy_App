
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/data/providers/match_provider.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  Future<void> _refreshMatches() async {
    // Manual Refresh triggers provider update
    await ref.read(matchListProvider.notifier).fetchMatches();
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

  Widget _buildMatchTab({required List<Map<String, dynamic>> matches, required String emptyMsg}) {
    if (matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshMatches,
        child: ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(child: Text(emptyMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)))
        ]),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshMatches,
      child: ListView.builder(
          itemCount: matches.length,
          padding: const EdgeInsets.only(bottom: 80),
          itemBuilder: (context, index) {
            final m = matches[index];
            // Convert to Model for cleaner UI code or use Map directly
            // Using Map directly for now since CricketMatchModel might expect different field names from D1
            // D1 fields: id, title, team_a, team_b...
            
            // Adapter logic (D1 -> UI)
            final id = m['id'].toString();
            final title = m['title'] ?? 'Match';
            final teamA = m['team_a'] ?? 'Team A';
            final teamB = m['team_b'] ?? 'Team B';
            final date = DateTime.fromMillisecondsSinceEpoch(m['start_time'] ?? 0);
            final status = m['status'] ?? 'Upcoming';
            final isLive = status == 'Live' || status == 'In Progress';
            final teamAImg = m['team_a_img'] ?? '';
            final teamBImg = m['team_b_img'] ?? '';

            return MatchCard(
              id: id,
              teamA: teamA,
              teamB: teamB,
              teamAImg: teamAImg,
              teamBImg: teamBImg,
              seriesName: title,
              date: date,
              status: status,
              isLive: isLive,
              onPrivateContest: () {
                 // Pass map as extra
                 context.push('/match/$id/create-private-contest', extra: m);
              },
              onTap: () {
                 if (status == 'Upcoming' || isLive || status == 'In Progress') {
                    context.push('/match/$id', extra: m);
                 } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Completed")));
                 }
              }
            );
          },
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);
    final walletBalance = userAsync.value?.walletBalance ?? 0.0;
    
    // Watch the Match List Provider
    final matchesAsync = ref.watch(matchListProvider);

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
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Error loading matches"),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _refreshMatches, child: const Text("Retry"))
          ],
        )),
        data: (allMatches) {
           final now = DateTime.now().millisecondsSinceEpoch;
           
           // Major League Filter Keywords (Case Insensitive)
           final majorKeywords = [
             'IPL', 'WPL', 'Women\'s Premier League', // Indian Leagues
             'BBL', 'Big Bash', 'WBBL', // Australian Leagues
             'PSL', 'Pakistan Super League', 
             'SA20', 'ILT20', 'The Hundred', 
             'CPL', 'Caribbean Premier League',
             'LPL', 'Lanka Premier League',
             'BPL', 'Bangladesh Premier League',
             'Super Smash', 'Major League Cricket', 'MLC',
             'T20 World Cup', 'World Cup', 'Champions Trophy', 'Asia Cup',
             'ODI', 'Test', 'T20I', // Format Indicators often in Int. matches
             'IND', 'AUS', 'ENG', 'SA', 'PAK', 'NZ', 'WI', 'SL', 'BAN', 'AFG', 'IRE', 'ZIM' // Intl Teams
           ];

           bool isMajorMatch(Map<String, dynamic> m) {
              final title = (m['title'] as String? ?? '').toLowerCase();
              final teamA = (m['team_a'] as String? ?? '').toLowerCase();
              final teamB = (m['team_b'] as String? ?? '').toLowerCase();
              
              // Check Title
              for (final k in majorKeywords) {
                 if (title.contains(k.toLowerCase())) return true;
              }
              // Check Teams (for International matches like "India vs Australia")
              // Only check strict team codes if title fail? Or just check if title contains them?
              // Usually title is "IND vs AUS".
              
              return false;
           }

           final upcoming = allMatches.where((m) {
              final status = m['status'];
              final start = m['start_time'] ?? 0;
              final isLive = status == 'Live' || status == 'In Progress';
              final isFuture = start > now;
              
              if (!isMajorMatch(m)) return false; // FILTER STEP

              // Only show if Live OR strictly Future
              return isLive || (status == 'Upcoming' && isFuture);
           }).toList();
           
           final completed = allMatches.where((m) {
              final status = m['status'];
              final start = m['start_time'] ?? 0;
              final isFinished = status == 'Completed' || status == 'Finished' || status == 'Abandoned';
              // User Constraint: Show only last 1 week of completed matches
              final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
              
              if (!isMajorMatch(m)) return false; // FILTER STEP

              return isFinished && start > sevenDaysAgo;
           }).toList();

           return DefaultTabController(
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
                      _buildMatchTab(matches: upcoming, emptyMsg: "No Upcoming Matches.\nPull to Refresh."),
                      _buildMatchTab(matches: completed, emptyMsg: "No Completed Matches."),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
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
  final String id;
  final String teamA;
  final String teamB;
  final String teamAImg;
  final String teamBImg;
  final String seriesName;
  final DateTime date;
  final String status;
  final bool isLive;
  
  final VoidCallback onPrivateContest;
  final VoidCallback onTap;

  const MatchCard({
    super.key, 
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.teamAImg,
    required this.teamBImg,
    required this.seriesName,
    required this.date,
    required this.status,
    required this.isLive,
    required this.onPrivateContest, 
    required this.onTap
  });

  String _getFlagUrl(String teamName) {
    // Basic mapping
    final lower = teamName.toLowerCase();
    if (lower.contains('ind')) return 'https://flagcdn.com/w80/in.png';
    if (lower.contains('aus')) return 'https://flagcdn.com/w80/au.png';
    if (lower.contains('eng')) return 'https://flagcdn.com/w80/gb-eng.png';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    String t1Img = teamAImg.isNotEmpty ? teamAImg : _getFlagUrl(teamA);
    String t2Img = teamBImg.isNotEmpty ? teamBImg : _getFlagUrl(teamB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0,4))],
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(seriesName, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          
          const Divider(height: 24, thickness: 0.5),

          // Teams Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 _buildTeamCircle(teamA, t1Img),
                 Column(
                   children: [
                     if (isLive) 
                        const Text("● LIVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                     else
                        Text(DateFormat('h:mm a').format(date), style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                     
                     const SizedBox(height: 4),
                     const Text("vs", style: TextStyle(fontSize: 12, color: Colors.grey)),
                   ],
                 ),
                 _buildTeamCircle(teamB, t2Img),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Row(
                   children: [
                     Icon(Icons.emoji_events_outlined, color: Colors.grey, size: 16),
                     SizedBox(width: 4),
                     Text("Mega ₹1 Crore", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                   ],
                 ),
                 
                 Row(
                   children: [
                     // Join
                     SizedBox(
                       height: 28,
                       child: ElevatedButton(
                         onPressed: onTap,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF43A047),
                           padding: const EdgeInsets.symmetric(horizontal: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                         ),
                         child: const Text("Join", style: TextStyle(fontSize: 10, color: Colors.white)),
                       ),
                     ),
                     const SizedBox(width: 8),
                     // Private
                     SizedBox(
                       height: 28,
                       child: OutlinedButton(
                         onPressed: onPrivateContest,
                         style: OutlinedButton.styleFrom(
                           side: BorderSide(color: Colors.indigo.shade200),
                           padding: const EdgeInsets.symmetric(horizontal: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                         ),
                         child: const Text("Create Private", style: TextStyle(fontSize: 10, color: Colors.indigo)),
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

  Widget _buildTeamCircle(String name, String img) {
    String short = name.length > 3 ? name.substring(0,3).toUpperCase() : name;
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: (img.isNotEmpty) ? NetworkImage(img) : null,
          child: img.isEmpty ? Text(short[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)) : null,
        ),
        const SizedBox(height: 8),
        Text(short, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
      ],
    );
  }
}
