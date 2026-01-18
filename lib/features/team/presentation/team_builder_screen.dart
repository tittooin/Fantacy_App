import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/team/domain/player_model.dart';
import 'package:axevora11/features/team/data/firestore_player_service.dart';

class TeamBuilderScreen extends ConsumerStatefulWidget {
  final CricketMatchModel match;
  final List<PlayerModel>? initialPlayers; // For Editing

  const TeamBuilderScreen({super.key, required this.match, this.initialPlayers});

  @override
  ConsumerState<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends ConsumerState<TeamBuilderScreen> {
  // State
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
  
  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    // Load from Firestore
    final fetched = await FirestorePlayerService().getPlayers(widget.match.id.toString());
    
    if (mounted) {
       setState(() {
         _allPlayers = fetched;
         _isLoading = false;
         
         // Pre-fill if editing (moved logic inside async completion)
          if (widget.initialPlayers != null) {
            for (var p in widget.initialPlayers!) {
              _selectedIds.add(p.id);
              _totalCreditsUsed += p.credits;
              
              if (p.teamShortName == widget.match.team1ShortName) {
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

  void _toggleSelection(PlayerModel player) {
    setState(() {
      if (_selectedIds.contains(player.id)) {
        // Deselect
        _selectedIds.remove(player.id);
        _totalCreditsUsed -= player.credits;
        if (player.teamShortName == widget.match.team1ShortName) {
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
        if (player.teamShortName == widget.match.team1ShortName && _team1Count >= 7) {
            _showError("Max 7 players from ${widget.match.team1ShortName}!");
            return;
        }
         if (player.teamShortName != widget.match.team1ShortName && _team2Count >= 7) {
            _showError("Max 7 players from ${widget.match.team2ShortName}!");
            return;
        }

        // Role Validations
        if (player.role == 'WK' && _wkCount >= maxWK) { _showError("Max $maxWK Wicket Keepers allowed!"); return; }
        if (player.role == 'BAT' && _batCount >= maxBAT) { _showError("Max $maxBAT Batsmen allowed!"); return; }
        if (player.role == 'AR' && _arCount >= maxAR) { _showError("Max $maxAR All-Rounders allowed!"); return; }
        if (player.role == 'BOWL' && _bowlCount >= maxBOWL) { _showError("Max $maxBOWL Bowlers allowed!"); return; }

        _selectedIds.add(player.id);
        _totalCreditsUsed += player.credits;
        if (player.teamShortName == widget.match.team1ShortName) {
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
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: const Text("Create Team", style: TextStyle(color: Colors.white, fontSize: 16)),
              bottom: _buildStatsHeader(),
            ),
            body: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : Column(
              children: [
                Container(
                  color: Colors.black,
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
        color: Colors.black,
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
                     Image.network("https://via.placeholder.com/20?text=${widget.match.team1ShortName}", width: 20, errorBuilder: (c,e,s)=>const Icon(Icons.circle, size: 10, color: Colors.white)),
                     const SizedBox(width: 4),
                     Text(widget.match.team1ShortName, style: const TextStyle(color: Colors.white)),
                     const SizedBox(width: 8),
                     Text("$_team1Count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     const SizedBox(width: 16),
                      Text("$_team2Count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     const SizedBox(width: 8),
                     Text(widget.match.team2ShortName, style: const TextStyle(color: Colors.white)),
                     const SizedBox(width: 4),
                     Image.network("https://via.placeholder.com/20?text=${widget.match.team2ShortName}", width: 20, errorBuilder: (c,e,s)=>const Icon(Icons.circle, size: 10, color: Colors.white)),
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
            const SizedBox(height: 6),
             LinearProgressIndicator(
               value: _selectedIds.length / 11,
               backgroundColor: Colors.grey.shade800,
               color: Colors.green,
               minHeight: 2,
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
                   child: Text(player.teamShortName[0], style: const TextStyle(fontSize: 12, color: Colors.white)),
                 ),
                 if (player.teamShortName == widget.match.team1ShortName)
                   const Positioned(bottom: 0, left: 0, child: Icon(Icons.circle, size: 10, color: Colors.blue))
                 else 
                   const Positioned(bottom: 0, right: 0, child: Icon(Icons.circle, size: 10, color: Colors.red))
              ],
            ),
            title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            subtitle: Text("Sel by 10% • ${player.points} pts", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(player.credits.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _toggleSelection(player),
                  icon: isSelected 
                    ? const Icon(Icons.remove_circle_outline, color: Colors.red)
                    : const Icon(Icons.add_circle_outline, color: Colors.green),
                ),
              ],
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
       padding: const EdgeInsets.all(16),
       color: Colors.white,
       child: Row(
         children: [
           Expanded(
             child: OutlinedButton(
               onPressed: () {
                  debugPrint("Preview Button Clicked!");
                  final selectedPlayers = _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
                  debugPrint("Selected Players: ${selectedPlayers.length}");
                  
                  try {
                    context.push('/match/${widget.match.id}/create-team/preview', extra: {
                      'players': selectedPlayers,
                      'team1Name': widget.match.team1ShortName,
                      'team2Name': widget.match.team2ShortName,
                    });
                  } catch (e) {
                    debugPrint("Navigation Error: $e");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nav Error: $e")));
                  }
               }, 
               style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
               child: const Text("TEAM PREVIEW")
             ),
           ),
           const SizedBox(width: 16),
          Expanded(
             child: ElevatedButton(
               onPressed: isComplete ? () {
                 // Final Role Validation before proceeding
                 if (_wkCount < minWK || _wkCount > maxWK) { _showError("Select $minWK-$maxWK Wicket Keepers"); return; }
                 if (_batCount < minBAT || _batCount > maxBAT) { _showError("Select $minBAT-$maxBAT Batsmen"); return; }
                 if (_arCount < minAR || _arCount > maxAR) { _showError("Select $minAR-$maxAR All-Rounders"); return; }
                 if (_bowlCount < minBOWL || _bowlCount > maxBOWL) { _showError("Select $minBOWL-$maxBOWL Bowlers"); return; }

                 // Navigate to Captain Selection
                 final selectedPlayers = _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
                 context.push('/match/${widget.match.id}/create-team/captain', extra: selectedPlayers);

               } : null,
               style: ElevatedButton.styleFrom(
                 backgroundColor: isComplete ? Colors.green : Colors.grey, 
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 disabledBackgroundColor: Colors.grey.shade300
               ),
               child: const Text("NEXT")
             ),
           ),
         ],
       ),
     );
  }
}
