import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/team/domain/player_model.dart';
import 'package:axevora11/features/team/data/d1_player_service.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart'; // Added
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamBuilderScreen extends ConsumerStatefulWidget {
  final CricketMatchModel match;
  final List<PlayerModel>? initialPlayers; // For Editing
  final String? existingTeamId;
  final String? existingTeamName;

  const TeamBuilderScreen({
    super.key, 
    required this.match, 
    this.initialPlayers,
    this.existingTeamId,
    this.existingTeamName,
  });

  @override
  ConsumerState<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends ConsumerState<TeamBuilderScreen> {
  // State
  CricketMatchModel? _activeMatch; // New local source of truth
  List<PlayerModel> _allPlayers = [];
  Set<String> _selectedIds = {};
  
  double _totalCreditsUsed = 0;
  int _team1Count = 0;
  int _team2Count = 0;
  
  // Role Counts
  final Map<PlayerRole, int> _roleCounts = {
    PlayerRole.wicketKeeper: 0,
    PlayerRole.batsman: 0,
    PlayerRole.allRounder: 0,
    PlayerRole.bowler: 0,
  };

  // Validation Constants
  static const int minWK = 1, maxWK = 4;
  static const int minBAT = 3, maxBAT = 6;
  static const int minAR = 1, maxAR = 4;
  static const int minBOWL = 3, maxBOWL = 6;

  bool _isLoading = true;

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  
  @override
  void initState() {
    super.initState();
    debugPrint("🏗️ TeamBuilderScreen INIT called - ${DateTime.now()}");
    _activeMatch = widget.match; 
    
    // Force Fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // 1. Load Players from D1 (Cloudflare Worker)
    final fetched = await ref.read(d1PlayerServiceProvider).getPlayers(
      widget.match.id.toString(),
      team1Id: widget.match.team1Id.toString(),
      team2Id: widget.match.team2Id.toString(),
      team1ShortName: widget.match.team1ShortName,
      team2ShortName: widget.match.team2ShortName,
    );
    
    // VERIFICATION STEP 1: LOG COUNTS
    final wkList = fetched.where((p) => p.role == PlayerRole.wicketKeeper).toList();
    final batList = fetched.where((p) => p.role == PlayerRole.batsman).toList();
    final arList = fetched.where((p) => p.role == PlayerRole.allRounder).toList();
    final bowlList = fetched.where((p) => p.role == PlayerRole.bowler).toList();

    debugPrint("📊 DATA FOR UI:");
    debugPrint("   Total Fetched: ${fetched.length}");
    debugPrint("   WK Count: ${wkList.length}");
    debugPrint("   BAT Count: ${batList.length}");
    debugPrint("   AR Count: ${arList.length}");
    debugPrint("   BOWL Count: ${bowlList.length}");
    final parsedTeam1 = fetched.where(_isTeam1).length;
    final parsedTeam2 = fetched.length - parsedTeam1;
    debugPrint("   Team1 Parsed Count: $parsedTeam1");
    debugPrint("   Team2 Parsed Count: $parsedTeam2");
    
    // Sample check
    if (batList.isNotEmpty) debugPrint("   Sample BAT: ${batList.first.name} (${batList.first.role})");
    if (bowlList.isNotEmpty) debugPrint("   Sample BOWL: ${bowlList.first.name} (${bowlList.first.role})");
    
    if (mounted) {
       setState(() {
         _allPlayers = fetched;
         _isLoading = false;
         final fetchedById = {for (final p in fetched) p.id: p};
         
         // Pre-fill if editing
          if (widget.initialPlayers != null) {
            for (var p in widget.initialPlayers!) {
              final normalized = fetchedById[p.id] ?? p;
              _selectedIds.add(normalized.id);
              _totalCreditsUsed += normalized.credits;
              if (_isTeam1(normalized)) {
                _team1Count++;
              } else {
                _team2Count++;
              }
              _updateRoleCount(normalized.role, 1);
            }
          }
       });
    }
  }

  bool _isTeam1(PlayerModel player) {
    return (player.teamBucket ?? '') == 'A';
  }

  void _toggleSelection(PlayerModel player) {
    setState(() {
      final isT1 = _isTeam1(player);
      
      if (_selectedIds.contains(player.id)) {
        // Deselect
        _selectedIds.remove(player.id);
        _totalCreditsUsed -= player.credits;
        if (isT1) {
          _team1Count--;
        } else {
          _team2Count--;
        }
        _updateRoleCount(player.role, -1);
      } else {

        // Select validations
        if (_selectedIds.length >= 11) {
          _showError("Max 11 players allowed!");
          return;
        }
        if (_totalCreditsUsed + player.credits > 100) {
          _showError("Not enough credits!");
          return;
        }
        
        final maxPerTeam = 7;
        
        if (isT1 && _team1Count >= maxPerTeam) {
            _showError("Max $maxPerTeam players from ${_activeMatch!.team1ShortName}!");
            return;
        }
        if (!isT1 && _team2Count >= maxPerTeam) {
            _showError("Max $maxPerTeam players from ${_activeMatch!.team2ShortName}!");
            return;
        }

        // Role Validations - Enum Based
        if (player.role == PlayerRole.wicketKeeper && _roleCounts[PlayerRole.wicketKeeper]! >= maxWK) { _showError("Max $maxWK Wicket Keepers allowed!"); return; }
        if (player.role == PlayerRole.batsman && _roleCounts[PlayerRole.batsman]! >= maxBAT) { _showError("Max $maxBAT Batsmen allowed!"); return; }
        if (player.role == PlayerRole.allRounder && _roleCounts[PlayerRole.allRounder]! >= maxAR) { _showError("Max $maxAR All-Rounders allowed!"); return; }
        if (player.role == PlayerRole.bowler && _roleCounts[PlayerRole.bowler]! >= maxBOWL) { _showError("Max $maxBOWL Bowlers allowed!"); return; }

        _selectedIds.add(player.id);
        _totalCreditsUsed += player.credits;
        if (isT1) {
          _team1Count++;
        } else {
          _team2Count++;
        }
        _updateRoleCount(player.role, 1);
      }
    });
  }

  void _updateRoleCount(PlayerRole role, int delta) {
    _roleCounts[role] = (_roleCounts[role] ?? 0) + delta;
  }

  void _showError(String message) {
     ScaffoldMessenger.of(context).clearSnackBars();
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text(message),
       backgroundColor: Colors.red,
       behavior: SnackBarBehavior.floating,
     ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 500;
        final mobileContent = DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: const Color(0xFF0B1E3C), // Dark Blue Background
            appBar: AppBar(
              backgroundColor: const Color(0xFF0B1E3C),
              title: const Text("Create Team", style: TextStyle(color: Colors.white, fontSize: 16)),
              bottom: _buildStatsHeader(),
            ),
            body: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : Column(
              children: [
                Container(
                  color: const Color(0xFF0B1E3C),
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: "WK (${_roleCounts[PlayerRole.wicketKeeper]})"),
                      Tab(text: "BAT (${_roleCounts[PlayerRole.batsman]})"),
                      Tab(text: "AR (${_roleCounts[PlayerRole.allRounder]})"),
                      Tab(text: "BOWL (${_roleCounts[PlayerRole.bowler]})"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPlayerList(PlayerRole.wicketKeeper),
                      _buildPlayerList(PlayerRole.batsman),
                      _buildPlayerList(PlayerRole.allRounder),
                      _buildPlayerList(PlayerRole.bowler),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomButton(),
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

  PreferredSize _buildStatsHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: const Color(0xFF0B1E3C),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            const Text("Max 7 players from a team", style: TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Players", style: TextStyle(color: Colors.white, fontSize: 12)),
                    Text("${_selectedIds.length}/11", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Row(
                  children: [
                     // Team 1 Badge
                     Image.network("https://via.placeholder.com/20?text=${_activeMatch?.team1ShortName ?? 'T1'}", width: 20, errorBuilder: (c,e,s)=>const Icon(Icons.circle, size: 10, color: Colors.blue)),
                     const SizedBox(width: 4),
                     Text(_activeMatch?.team1ShortName.isNotEmpty == true ? _activeMatch!.team1ShortName : 'Team 1', style: const TextStyle(color: Colors.white, fontSize: 12)),
                     const SizedBox(width: 4),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: _team1Count >= 7 ? Colors.red : Colors.green.withOpacity(0.3),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text("$_team1Count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                     ),
                     const SizedBox(width: 16),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: _team2Count >= 7 ? Colors.red : Colors.green.withOpacity(0.3),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text("$_team2Count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                     ),
                     const SizedBox(width: 4),
                     Text(_activeMatch?.team2ShortName.isNotEmpty == true ? _activeMatch!.team2ShortName : 'Team 2', style: const TextStyle(color: Colors.white, fontSize: 12)),
                     const SizedBox(width: 4),
                     Image.network("https://via.placeholder.com/20?text=${_activeMatch?.team2ShortName ?? 'T2'}", width: 20, errorBuilder: (c,e,s)=>const Icon(Icons.circle, size: 10, color: Colors.blue)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Credits Left", style: TextStyle(color: Colors.white, fontSize: 12)),
                    Text((100 - _totalCreditsUsed).toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
             Stack(
               children: [
                 Container(
                   height: 6,
                   width: double.infinity,
                   decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
                 ),
                 FractionallySizedBox(
                   widthFactor: _selectedIds.length / 11,
                   child: Container(
                     height: 6,
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                       borderRadius: BorderRadius.circular(3),
                       boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4)]
                     ),
                   ),
                 ),
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList(PlayerRole role) {
    // STRICT Filtering by Enum
    final players = _allPlayers.where((p) => p.role == role).toList();
    
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isSelected = _selectedIds.contains(player.id);
        final isPlaying = widget.match.playingXI.contains(player.id);
        
        // DEBUG: First player per tab
        if (index == 0) {
           debugPrint("📋 List for $role: First player is ${player.name}");
        }
        
        final isTeam1 = _isTeam1(player);
        
        final teamBadgeText =
            isTeam1 ? (_activeMatch?.team1ShortName ?? 'T1') : (_activeMatch?.team2ShortName ?? 'T2');
        final teamBadgeColor = isTeam1 ? Colors.blue : Colors.red;
        
        return Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1B5E20).withOpacity(0.4) : Colors.transparent, // Dark Green vs Transparent
            border: const Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                 CircleAvatar(
                   backgroundColor: Colors.grey.shade800,
                   backgroundImage: player.imageUrl.isNotEmpty ? NetworkImage(player.imageUrl) : null,
                   child: player.imageUrl.isEmpty ? Text(_getInitials(player.name), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)) : null,
                 ),
                 Positioned(
                   bottom: 0, 
                   left: 0, 
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                     decoration: BoxDecoration(
                       color: teamBadgeColor,
                       borderRadius: BorderRadius.circular(3),
                       border: Border.all(color: Colors.white, width: 0.5),
                     ),
                     child: Text(
                       teamBadgeText,
                       style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                     ),
                   ),
                 ),
              ],
            ),
            title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
             subtitle: Row(
               children: [
                 Text("Sel: ${player.fantasyRating.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 10, color: Colors.amberAccent)), // NEW Rating
                 const SizedBox(width: 8),
                 Text("${player.points} pts", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                 if (isPlaying) ...[
                    const SizedBox(width: 8),
                    const Text("● Playing", style: TextStyle(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                 ],
               ],
             ),
            trailing: SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${player.credits}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      const Text("CREDITS", style: TextStyle(fontSize: 8, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _toggleSelection(player),
                    icon: isSelected 
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                      : const Icon(Icons.add_circle_outline, color: Colors.white70, size: 24),
                  ),
                ],
              ),
            ),
            onTap: () => _toggleSelection(player),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
     final bool isComplete = _selectedIds.length == 11;
     
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF0B1E3C),
          border: Border(top: BorderSide(color: Colors.white10))
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                   final selectedPlayers = _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
                   context.push('/match/${widget.match.id}/create-team/preview', extra: {
                     'players': selectedPlayers,
                     'team1Name': widget.match.team1ShortName,
                     'team2Name': widget.match.team2ShortName,
                     'isEditMode': true,
                     'match': widget.match,
                     'existingTeamId': widget.existingTeamId,
                     'existingTeamName': widget.existingTeamName,
                   });
                }, 
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.white54),
                  foregroundColor: Colors.white
                ),
                child: const Text("PREVIEW", style: TextStyle(fontWeight: FontWeight.bold))
              ),
            ),
            const SizedBox(width: 16),
           Expanded(
              child: ElevatedButton(
                onPressed: isComplete ? () {
                   if (_roleCounts[PlayerRole.wicketKeeper]! < minWK || _roleCounts[PlayerRole.wicketKeeper]! > maxWK) { _showError("Select $minWK-$maxWK Wicket Keepers"); return; }
                   if (_roleCounts[PlayerRole.batsman]! < minBAT || _roleCounts[PlayerRole.batsman]! > maxBAT) { _showError("Select $minBAT-$maxBAT Batsmen"); return; }
                   if (_roleCounts[PlayerRole.allRounder]! < minAR || _roleCounts[PlayerRole.allRounder]! > maxAR) { _showError("Select $minAR-$maxAR All-Rounders"); return; }
                   if (_roleCounts[PlayerRole.bowler]! < minBOWL || _roleCounts[PlayerRole.bowler]! > maxBOWL) { _showError("Select $minBOWL-$maxBOWL Bowlers"); return; }

                  final selectedPlayers = _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
                  debugPrint("TeamBuilder Debug: Passing existingTeamId to Captain: ${widget.existingTeamId}");
                  context.push('/match/${widget.match.id}/create-team/captain', extra: {
                    'players': selectedPlayers,
                    'existingTeamId': widget.existingTeamId,
                    'existingTeamName': widget.existingTeamName,
                  });
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete ? Colors.green : Colors.grey.shade800, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0
                ),
                child: const Text("NEXT", style: TextStyle(fontWeight: FontWeight.bold))
              ),
            ),
          ],
        ),
      );
  }
}
