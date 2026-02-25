import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/data/providers/match_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/user/domain/user_entity.dart';
import 'package:axevora11/features/contest/presentation/providers/user_contest_provider.dart';
import 'package:axevora11/core/utils/team_utils.dart';
import 'package:axevora11/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isCheckingNickname = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorial());
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_tutorial') ?? false;

    if (!seen && mounted) {
       _showTutorialDialog();
       await prefs.setBool('has_seen_tutorial', true);
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
               Icon(Icons.help_outline, color: Colors.indigo),
               SizedBox(width: 8),
               Text("How to Play?", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tutorialStep("1. Select a Match", "Choose an upcoming match from the home screen.", Icons.sports_cricket),
              _tutorialStep("2. Create Team", "Pick your best 11 players. Use your cricket knowledge!", Icons.group_add),
              _tutorialStep("3. Join Contest", "Join a contest with your team to win prizes.", Icons.emoji_events),
              const SizedBox(height: 12),
              const Center(child: Text("Good Luck!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              child: const Text("Let's Play"),
            )
          ],
        );
      }
    );
  }

  Widget _tutorialStep(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _checkNickname(UserEntity? user) {
    if (user == null || _isCheckingNickname) return;
    final name = user.displayName;
    if (name == null || name.isEmpty || name.trim() == 'Player User' || name.startsWith('Player ')) {
       _isCheckingNickname = true;
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNicknameDialog(user.uid);
       });
    }
  }

  void _showNicknameDialog(String uid) {
    final TextEditingController _nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text("Set Your Nickname"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Welcome to Axe11! Choose a unique nickname to stand out on the leaderboard."),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: "Nickname",
                    labelStyle: TextStyle(color: Colors.indigo),
                    border: OutlineInputBorder(),
                    hintText: "e.g. CricketKing7",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                   final name = _nameController.text.trim();
                   if (name.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nickname cannot be empty")));
                     return;
                   }
                   if (name.length < 3) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nickname too short")));
                     return;
                   }
                   try {
                     await FirebaseFirestore.instance.collection('users').doc(uid).update({
                       'displayName': name
                     });
                     if (context.mounted) Navigator.pop(context);
                   } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                   }
                },
                child: const Text("Save & Continue"),
              )
            ],
          ),
        );
      }
    );
  }

  Future<void> _refreshMatches() async {
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

  Widget _buildMatchTab({required List<Map<String, dynamic>> matches, required String emptyMsg, required Set<String> joinedMatchIds}) {
    if (matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshMatches,
        child: ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(child: Text(emptyMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)))
        ]),
      );
    }
    final groupedMatches = <String, List<Map<String, dynamic>>>{};
    for (var m in matches) {
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
                  final id = m['id'].toString();
                  final title = m['title'] ?? seriesName; 
                  final teamA = m['team1ShortName'] ?? m['team_a'] ?? 'Team A';
                  final teamB = m['team2ShortName'] ?? m['team_b'] ?? 'Team B';
                  final teamAImg = m['team1Img'] ?? m['team_a_img'] ?? '';
                  final teamBImg = m['team2Img'] ?? m['team_b_img'] ?? '';
                  final startTime = m['startDate'] ?? m['start_time'] ?? 0;
                  final date = DateTime.fromMillisecondsSinceEpoch(startTime);
                   final status = m['status'] ?? 'Upcoming';
                   final isLive = status == 'Live' || status == 'In Progress';
                   final isJoined = joinedMatchIds.contains(id);
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
                    isJoined: isJoined,
                    onPrivateContest: () {
                       context.push('/match/$id/create-room', extra: m);
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
    ref.listen<AsyncValue<UserEntity?>>(userEntityProvider, (previous, next) {
       final user = next.value;
       if (user != null) {
          _checkNickname(user);
       }
    });

    final userAsync = ref.watch(userEntityProvider);
    final matchesAsync = ref.watch(matchListProvider);
    final joinedContests = ref.watch(userContestProvider);
    final joinedMatchIds = joinedContests.map((c) => c.matchId.toString()).toSet();

    final mobileContent = Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.vibrantBlue,
        title: Text(
          "AxevoraLabs.com",
          style: GoogleFonts.oswald(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/wallet'),
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                if(userAsync.value != null) context.push('/profile/${userAsync.value!.uid}');
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                backgroundImage: userAsync.value?.photoUrl != null 
                    ? NetworkImage(userAsync.value!.photoUrl!) 
                    : null,
                child: userAsync.value?.photoUrl == null 
                    ? const Icon(Icons.person, size: 18, color: Colors.white) 
                    : null,
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
            bool isUpcomingLikeStatus(dynamic rawStatus) {
              final status = (rawStatus ?? '').toString().trim().toLowerCase();
              return status == 'upcoming' || status == 'scheduled';
            }
            final live = allMatches.where((m) {
              final status = m['status'];
              return status == 'Live' || status == 'In Progress';
            }).toList();
            final upcoming = allMatches.where((m) {
              final status = m['status'];
              return isUpcomingLikeStatus(status);
            }).toList();
            final completed = allMatches.where((m) {
              final status = m['status'];
              return status == 'Completed' || status == 'Finished' || status == 'Abandoned';
            }).toList();

          return DefaultTabController(
            length: 3,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.vibrantBlue, Color(0xFF1D4ED8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      image: DecorationImage(
                        image: NetworkImage("https://www.transparentpng.com/download/stadium/cricket-stadium-lights-png-2.png"),
                        fit: BoxFit.cover,
                        opacity: 0.1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Watch Matches.\nCreate Private Rooms!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Enjoy Live Sports with Friends!\nJoin Exclusive Group Chats while you watch.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.stadiumRed,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Download App", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => context.push('/social-safety'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Learn More"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    minHeight: 50,
                    maxHeight: 50,
                    child: Container(
                      color: Colors.white,
                      child: TabBar(
                        labelColor: AppColors.vibrantBlue,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.vibrantBlue,
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.oswald(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: "Live Matches"),
                          Tab(text: "Upcoming"), 
                          Tab(text: "Completed")
                        ],
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    children: [
                      _buildMatchTab(matches: live, emptyMsg: "No Live Matches currently.", joinedMatchIds: joinedMatchIds),
                      _buildMatchTab(matches: upcoming, emptyMsg: "No Upcoming Matches.", joinedMatchIds: joinedMatchIds),
                      _buildMatchTab(matches: completed, emptyMsg: "No Completed Matches.", joinedMatchIds: joinedMatchIds),
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
  final bool isJoined;
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
    this.isJoined = false,
    required this.onPrivateContest, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String t1Img = TeamUtils.getFlagUrl(teamA, fallbackUrl: teamAImg);
    String t2Img = TeamUtils.getFlagUrl(teamB, fallbackUrl: teamBImg);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    seriesName.toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 10,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isLive)
                    const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        SizedBox(width: 4),
                        Text("LIVE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildTeam(teamA, t1Img),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "VS",
                          style: GoogleFonts.oswald(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.vibrantBlue.withOpacity(0.3),
                          ),
                        ),
                        if (!isLive)
                          Text(
                            DateFormat('h:mm a').format(date),
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  _buildTeam(teamB, t2Img),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.stadiumRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: Text(
                          "Join Match Rooms",
                          style: GoogleFonts.oswald(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: onPrivateContest,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.vibrantBlue, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "Create Room",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.vibrantBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeam(String name, String img) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.offWhite,
            backgroundImage: img.isNotEmpty ? CachedNetworkImageProvider(img) : null,
            child: img.isEmpty ? Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
