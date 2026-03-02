import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/features/team/domain/player_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed for D1-only compliance
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/data/providers/match_provider.dart'; // Added
import 'package:axevora11/features/cricket_api/domain/cricket_contest_model.dart';
import 'package:axevora11/core/api/axevora_api_client.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
import 'package:axevora11/features/team/presentation/providers/team_provider.dart';
import 'package:axevora11/features/contest/presentation/providers/user_contest_provider.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:axevora11/features/cricket_api/presentation/widgets/match_score_header.dart';
import 'package:axevora11/features/contest/presentation/widgets/scorecard_tab.dart';
import 'package:axevora11/features/contest/presentation/widgets/contest_card.dart';
import 'package:axevora11/features/chat/presentation/match_chat_room.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  final CricketMatchModel? match; // Optional, can be null if deep linked

  const MatchDetailScreen({super.key, required this.matchId, this.match});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  // Removed local Firestore state
  
  @override
  void initState() {
    super.initState();
  }

  CricketMatchModel? get _effectiveMatch {
    if (widget.match != null) return widget.match;
    // Use read(matchListProvider) because build() watches it.
    // This allows helper methods to access the current match state without passing it around.
    final matchesAsync = ref.read(matchListProvider);
    final allMatches = matchesAsync.value;
    if (allMatches == null) return null;
    
    try {
      final matchMap = allMatches.firstWhere((m) => m['id'] == widget.matchId, orElse: () => {});
      if (matchMap.isNotEmpty) {
        return CricketMatchModel.fromMap(matchMap);
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we WATCH the provider so build re-runs on updates
    ref.watch(matchListProvider);

    // If match is passed, use it. Match retrieval is handled by getter.
    final displayMatch = _effectiveMatch;
    
    final matchTitle = displayMatch != null 
        ? "${displayMatch.team1Name} vs ${displayMatch.team2Name}"
        : "Match Contests";
        
    final isLiveOrCompleted = displayMatch?.status == 'Live' || displayMatch?.status == 'Completed';

    // Watch teams and contests
    final allTeams = ref.watch(teamProvider);
    final myTeams = allTeams.where((t) => t.matchId == widget.matchId).toList();

    final allJoined = ref.watch(userContestProvider);
    final myContests = allJoined.where((c) => c.matchId == widget.matchId).toList();
    
    // Watch User Provider to ensure Balance is up-to-date
    ref.watch(userEntityProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 500;
        final mobileContent = DefaultTabController(
          length: 3,
          initialIndex: 0,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.vibrantBlue,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/home'),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _effectiveMatch != null 
                        ? "${_effectiveMatch!.team1Name} vs ${_effectiveMatch!.team2Name}" 
                        : "Match Hub", 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
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
              bottom: const PreferredSize(
                 preferredSize: Size.fromHeight(50),
                 child: TabBar(
                  isScrollable: false,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(text: "Live Chat"),
                    Tab(text: "Host Lounges"),
                    Tab(text: "Scorecard"),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              children: [
                MatchChatRoom(matchId: widget.matchId),
                _buildRoomsTab(),
                ScorecardTab(matchId: widget.matchId),
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

  Future<List<CricketRoomModel>> _fetchContests() async {
    try {
      // Convert String matchId to int for Firestore query
      final int matchIdInt = int.parse(widget.matchId);
      debugPrint("🔍 Fetching contests for matchId: $matchIdInt (converted from String '${widget.matchId}')");
      
      final contestsData = await ref.read(axevoraApiClientProvider).getInteractionHubs(widget.matchId);
      
      final contestsList = contestsData
          .map((json) => CricketRoomModel.fromJson(json))
          .toList();
      
      debugPrint("Found ${contestsList.length} contests from D1");
      return contestsList;
    } catch (e) {
      debugPrint("❌ Error fetching contests: $e");
      return [];
    }
  }


  String _selectedFilter = "All"; // Track selected filter

  // ... (existing code)

  Widget _buildRoomsTab() {
    final showScore = _effectiveMatch?.status == 'Live' || _effectiveMatch?.status == 'Completed';
    
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Triggers FutureBuilder
        await _fetchContests();
      },
      child: Column(
        children: [
          if (showScore) MatchScoreHeader(matchId: widget.matchId, match: _effectiveMatch),
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All", _selectedFilter == "All"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Social Hub", _selectedFilter == "Social Hub"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Hot", _selectedFilter == "Hot"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Head 2 Head", _selectedFilter == "Head 2 Head"),
                   const SizedBox(width: 8),
                  _buildFilterChip("Winner Takes All", _selectedFilter == "Winner Takes All"),
                   const SizedBox(width: 8),
                  _buildFilterChip("Practice", _selectedFilter == "Practice"),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<CricketRoomModel>>(
              future: _fetchContests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
  
                var contests = snapshot.data ?? [];
                
                // Client-side Filtering
                if (_selectedFilter != "All") {
                    contests = contests.where((c) {
                        // Loose matching for broader categories
                        if (_selectedFilter == "Social Hub") return c.category.contains("Social");
                        if (_selectedFilter == "Hot") return c.category.contains("Hot") || c.totalParticipants > 100;
                        if (_selectedFilter == "Head 2 Head") return c.category.contains("Head") || c.totalParticipants == 2;
                        return c.category == _selectedFilter;
                    }).toList();
                }

                if (contests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text("No $_selectedFilter Rooms Found", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
  
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Space for FAB if needed
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: contests.length,
                  itemBuilder: (context, index) {
                    return ContestCard(contest: contests[index], match: _effectiveMatch, matchId: widget.matchId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? Colors.black87 : Colors.grey.shade200,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: () {
          setState(() {
              _selectedFilter = label;
          });
      },
    );
  }

  // Legacy methods removed
}

