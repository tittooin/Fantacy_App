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

  const TeamBuilderScreen({super.key, required this.match, this.initialPlayers});

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
  int _wkCount = 0;
  int _batCount = 0;
  int _arCount = 0;
  int _bowlCount = 0;

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
    _activeMatch = widget.match; // Initialize with passed data
    _loadData();
  }

  Future<void> _loadData() async {
    // NOTE: We removed the Firestore auto-sync step here because we now use D1 database exclusively.
    // Squad data is managed by Cloudflare Workers and stored in D1, not Firestore.
    // The Worker API automatically syncs squad data when needed.

    // 1. Fetch Fresh Match Data to ensure ShortNames are correct
    try {
      final doc = await FirebaseFirestore.instance.collection('matches').doc(widget.match.id.toString()).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
           _activeMatch = CricketMatchModel.fromMap(doc.data()!);
        });
        debugPrint("✅ Fresh Match Data: ${_activeMatch?.team1ShortName} vs ${_activeMatch?.team2ShortName}");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to refresh match data: $e");
    }

    // 2. Load Players from D1 (Cloudflare Worker)
    final fetched = await ref.read(d1PlayerServiceProvider).getPlayers(widget.match.id.toString());
    
    // DEBUG: Print first few players to verify teamShortName and imageUrl
    if (fetched.isNotEmpty) {
      debugPrint("🔍 DEBUG: First 3 players from D1:");
      for (var i = 0; i < (fetched.length > 3 ? 3 : fetched.length); i++) {
        final p = fetched[i];
        debugPrint("  Player ${i + 1}: ${p.name}");
        debugPrint("    - teamShortName: '${p.teamShortName}'");
        debugPrint("    - imageUrl: '${p.imageUrl}'");
        debugPrint("    - teamId: '${p.teamId}'");
      }
    }
    
    if (mounted) {
       setState(() {
         _allPlayers = fetched;
         _isLoading = false;
         
         // Pre-fill if editing (moved logic inside async completion)
          if (widget.initialPlayers != null) {
            for (var p in widget.initialPlayers!) {
              _selectedIds.add(p.id);
              _totalCreditsUsed += p.credits;
              
              if (_isTeam1(p)) {
                _team1Count++;
              } else {
                _team2Count++;
              }
              _updateRoleCount(p.role, 1);
            }
          }
       });
    }
  }

  bool _isTeam1(PlayerModel player) {
    if (_activeMatch == null) return false;
    
    // PRIMARY Check: Team IDs (Robust)
    final pTeamId = (player.teamId ?? '').trim();
    final mTeam1Id = _activeMatch!.team1Id.toString().trim();
    if (pTeamId.isNotEmpty && mTeam1Id.isNotEmpty) {
      return pTeamId == mTeam1Id;
    }

    // FALLBACK Check: Team Names (Legacy)
    final pTeam = (player.teamShortName ?? '').trim().toUpperCase();
    final mTeam1 = _activeMatch!.team1ShortName.trim().toUpperCase();
    return pTeam == mTeam1; 
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

        // Role Validations
        if (player.role == 'WK' && _wkCount >= maxWK) { _showError("Max $maxWK Wicket Keepers allowed!"); return; }
        if (player.role == 'BAT' && _batCount >= maxBAT) { _showError("Max $maxBAT Batsmen allowed!"); return; }
        if (player.role == 'AR' && _arCount >= maxAR) { _showError("Max $maxAR All-Rounders allowed!"); return; }
        if (player.role == 'BOWL' && _bowlCount >= maxBOWL) { _showError("Max $maxBOWL Bowlers allowed!"); return; }

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

  void _updateRoleCount(String role, int delta) {
    switch (role) {
      case 'WK': _wkCount += delta; break;
      case 'BAT': _batCount += delta; break;
      case 'AR': _arCount += delta; break;
      case 'BOWL': _bowlCount += delta; break;
    }
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
                      Tab(text: "WK (${_wkCount})"),
                      Tab(text: "BAT (${_batCount})"),
                      Tab(text: "AR (${_arCount})"),
                      Tab(text: "BOWL (${_bowlCount})"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPlayerList("WK"),
                      _buildPlayerList("BAT"),
                      _buildPlayerList("AR"),
                      _buildPlayerList("BOWL"),
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
                     Image.network("https://via.placeholder.com/20?text=${_activeMatch?.team2ShortName ?? 'T2'}", width: 20, errorBuilder: (c,e,s)=>const Icon(Icons.circle, size: 10, color: Colors.red)),
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

  Widget _buildPlayerList(String role) {
    final players = _allPlayers.where((p) => p.role == role).toList();
    
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isSelected = _selectedIds.contains(player.id);
        final isPlaying = widget.match.playingXI.contains(player.id);
        
        // DEBUG: Log player team assignment
        if (index == 0) {
          final isT1 = _isTeam1(player);
          debugPrint("🏏 PLAYER TEAM DEBUG:");
          debugPrint("   Player: ${player.name}");
          debugPrint("   Player.teamId: '${player.teamId}'");
          debugPrint("   Match.team1Id: '${_activeMatch?.team1Id}'");
          debugPrint("   Matches Team1? $isT1");
          debugPrint("   Image: ${player.imageUrl}");
        }
        
        final isTeam1 = _isTeam1(player);
        
        // Use player's teamShortName directly from D1 data (most reliable)
        // Fallback to match data only if player data is missing
        final teamBadgeText = (player.teamShortName?.isNotEmpty == true) 
            ? player.teamShortName! 
            : (isTeam1 ? (_activeMatch?.team1ShortName ?? 'T1') : (_activeMatch?.team2ShortName ?? 'T2'));
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
                  if (_wkCount < minWK || _wkCount > maxWK) { _showError("Select $minWK-$maxWK Wicket Keepers"); return; }
                  if (_batCount < minBAT || _batCount > maxBAT) { _showError("Select $minBAT-$maxBAT Batsmen"); return; }
                  if (_arCount < minAR || _arCount > maxAR) { _showError("Select $minAR-$maxAR All-Rounders"); return; }
                  if (_bowlCount < minBOWL || _bowlCount > maxBOWL) { _showError("Select $minBOWL-$maxBOWL Bowlers"); return; }

                  final selectedPlayers = _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
                  context.push('/match/${widget.match.id}/create-team/captain', extra: selectedPlayers);
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
