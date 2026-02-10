
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/data/providers/match_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/contest/presentation/providers/user_contest_provider.dart';
import 'package:axevora11/core/utils/team_utils.dart';

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

    // Grouping Logic
    final groupedMatches = <String, List<Map<String, dynamic>>>{};
    for (var m in matches) {
      // Prioritize 'seriesName' if available, fallback to 'title'
      final String series = m['seriesName'] ?? m['title'] ?? 'Other Matches';
      if (!groupedMatches.containsKey(series)) {
        groupedMatches[series] = [];
      }
      groupedMatches[series]!.add(m);
    }

    return RefreshIndicator(
      onRefresh: _refreshMatches,
      child: ListView.builder(
          itemCount: groupedMatches.length,
          padding: const EdgeInsets.only(bottom: 80),
          itemBuilder: (context, index) {
            final seriesName = groupedMatches.keys.elementAt(index);
            final seriesMatches = groupedMatches[seriesName]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeriesHeader(seriesName),
                ...seriesMatches.map((m) {
                  // Adapter logic (D1 -> UI)
                  final id = m['id'].toString();
                  // For the card, we might duplicate seriesName, but it's fine.
                  final title = m['title'] ?? seriesName; 
                  
                  // Schema Adapter: Admin (CricketMatchModel) vs Legacy
                  final teamA = m['team1ShortName'] ?? m['team_a'] ?? 'Team A';
                  final teamB = m['team2ShortName'] ?? m['team_b'] ?? 'Team B';
                  final teamAImg = m['team1Img'] ?? m['team_a_img'] ?? '';
                  final teamBImg = m['team2Img'] ?? m['team_b_img'] ?? '';
                  
                  final startTime = m['startDate'] ?? m['start_time'] ?? 0;
                  final date = DateTime.fromMillisecondsSinceEpoch(startTime);
                  
                  final status = m['status'] ?? 'Upcoming';
                  final isLive = status == 'Live' || status == 'In Progress';

                  return MatchCard(
                    id: id,
                    teamA: teamA,
                    teamB: teamB,
                    teamAImg: teamAImg,
                    teamBImg: teamBImg,
                    seriesName: title, // Keep passing specific match title/series
                    date: date,
                    status: status,
                    isLive: isLive,
                    onPrivateContest: () {
                       context.push('/match/$id/create-private-contest', extra: m);
                    },
                    onTap: () {
                       if (status == 'Upcoming' || isLive || status == 'In Progress' || status == 'Completed' || status == 'Finished') {
                          context.push('/match/$id', extra: m);
                       } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Unavailable")));
                       }
                    }
                  );
                }).toList()
              ],
            );
          },
        ),
    );
  }

  Widget _buildSeriesHeader(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3949AB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3949AB).withOpacity(0.2))
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF3949AB),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0
        ),
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
             'IPL', 'Indian Premier League', 
             'World Cup', 'T20 World Cup', '2026' 
           ];

            bool isMajorMatch(Map<String, dynamic> m) {
               final title = (m['title'] as String? ?? '').toLowerCase();
               final series = (m['seriesName'] as String? ?? '').toLowerCase();
               final desc = (m['matchDesc'] as String? ?? '').toLowerCase();

               // Combined string to check (Title often missing in Firestore/Model usage)
               final fullText = "$title $series $desc";
               
               for (final k in majorKeywords) {
                  if (fullText.contains(k.toLowerCase())) return true;
               }
               return false;
            }

            final live = allMatches.where((m) {
              final status = m['status'];
              final isLive = status == 'Live' || status == 'In Progress';
              if (!isMajorMatch(m)) return false;
              return isLive;
           }).toList();

           final upcoming = allMatches.where((m) {
              final status = m['status'];
              final start = m['start_time'] ?? m['startDate'] ?? 0;
              
              // DEBUG PRINT
              debugPrint("Checking Match: ${m['title']} | Series: ${m['seriesName']} | Status: $status | Start: $start");

              if (!isMajorMatch(m)) {
                 debugPrint("-> Rejected by Major Filter: ${m['title']}");
                 return false; 
              }

              return status == 'Upcoming' && start > now;
           }).toList();
           
           final completed = allMatches.where((m) {
              final status = m['status'];
              final start = m['start_time'] ?? m['startDate'] ?? 0;
              final isFinished = status == 'Completed' || status == 'Finished' || status == 'Abandoned';
              final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
              
              if (!isMajorMatch(m)) return false;

              return isFinished && start > sevenDaysAgo;
           }).toList();

           return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Premium Banner Area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A237E), Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight
                    )
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text("AXEVORA", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                       SizedBox(height: 4),
                       Text("Premium Fantasy", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                       Text("Elite Matches • Exclusive Vouchers", style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                
                // My Matches Section
                _buildMyMatchesSection(allMatches),
                
                // TABS
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: Color(0xFF1A237E),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF1A237E),
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: "Live"),
                      Tab(text: "Upcoming"), 
                      Tab(text: "Completed")
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildMatchTab(matches: live, emptyMsg: "No Live Matches currently."),
                      _buildMatchTab(matches: upcoming, emptyMsg: "No Upcoming Matches."),
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

  Widget _buildMyMatchesSection(List<Map<String, dynamic>> allMatches) {
    // We can't easily watch another provider inside a build-helper if it depends on ref.
    // However, ref is available in the whole state class.
    final joinedContests = ref.watch(userContestProvider);
    final joinedMatchIds = joinedContests.map((c) => c.matchId.toString()).toSet();
    
    final myMatches = allMatches.where((m) {
       final isJoined = joinedMatchIds.contains(m['id'].toString());
       if (!isJoined) return false;
       final status = m['status'] ?? '';
       // Exclude completed matches from "My Matches" top section as per user request
       final isFinished = status == 'Completed' || status == 'Finished' || status == 'Abandoned';
       return !isFinished;
    }).toList();
    
    if (myMatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MY MATCHES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.black87)),
              Text("View All", style: TextStyle(fontSize: 10, color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: myMatches.length,
            itemBuilder: (context, index) {
              final m = myMatches[index];
              return _buildMyMatchItem(m);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyMatchItem(Map<String, dynamic> m) {
    final teamA = m['team1ShortName'] ?? m['team_a'] ?? 'T1';
    final teamB = m['team2ShortName'] ?? m['team_b'] ?? 'T2';
    final status = m['status'] ?? 'Upcoming';
    final isLive = status == 'Live' || status == 'In Progress';
    
    final t1Img = TeamUtils.getFlagUrl(teamA, fallbackUrl: m['team1Img'] ?? m['team_a_img']);
    final t2Img = TeamUtils.getFlagUrl(teamB, fallbackUrl: m['team2Img'] ?? m['team_b_img']);

    return GestureDetector(
      onTap: () => context.push('/match/${m['id']}', extra: m),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  _buildTeamSmallAvatarWithText(t1Img, teamA),
                  const Text("vs", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  _buildTeamSmallAvatarWithText(t2Img, teamB),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLive)
                  const Text("● LIVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10))
                else
                  Text(status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSmallAvatar(String img, String name) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey.shade100,
      backgroundImage: img.isNotEmpty ? CachedNetworkImageProvider(img) : null,
      child: img.isEmpty && name.isNotEmpty ? Text(name[0], style: const TextStyle(fontSize: 10)) : null,
    );
  }

  // Helper inside HomeScreen for Small Team Avatar with Name
  Widget _buildTeamSmallAvatarWithText(String img, String name) {
     return Column(
       children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: img.isNotEmpty ? CachedNetworkImageProvider(img) : null,
            child: img.isEmpty && name.isNotEmpty ? Text(name[0], style: const TextStyle(fontSize: 10)) : null,
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
       ],
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


  @override
  Widget build(BuildContext context) {
    String t1Img = TeamUtils.getFlagUrl(teamA, fallbackUrl: teamAImg);
    String t2Img = TeamUtils.getFlagUrl(teamB, fallbackUrl: teamBImg);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.grey.withOpacity(0.1))
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text(seriesName, style: TextStyle(fontSize: 9, color: Colors.grey[800], fontWeight: FontWeight.bold, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.notifications_none, size: 14, color: Colors.grey),
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
          
          const SizedBox(height: 16),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
                  const Spacer(), // Replaces Voucher Pool
                  
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
     // Show full name if short enough, else truncate gracefully or use short name if available?
     // User wants "India vs Pakistan". 
     // We will use the name as is, but handle overflow.
     return Column(
       children: [
         CircleAvatar(
           radius: 28,
           backgroundColor: Colors.grey.shade100,
           backgroundImage: (img.isNotEmpty) ? CachedNetworkImageProvider(img) : null,
           child: img.isEmpty ? Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)) : null,
         ),
         const SizedBox(height: 8),
         SizedBox(
            width: 80,
            child: Text(
              name, 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
         ),
       ],
     );
   }
}
