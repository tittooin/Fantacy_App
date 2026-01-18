import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/data/cricket_api_service.dart';
import 'package:axevora11/features/team/domain/player_model.dart';
import 'package:axevora11/features/team/data/firestore_player_service.dart';

class LineupManagementScreen extends ConsumerStatefulWidget {
  final String matchId;
  final CricketMatchModel match;

  const LineupManagementScreen({super.key, required this.matchId, required this.match});

  @override
  ConsumerState<LineupManagementScreen> createState() => _LineupManagementScreenState();
}

class _LineupManagementScreenState extends ConsumerState<LineupManagementScreen> {
  List<PlayerModel> _team1Squad = [];
  List<PlayerModel> _team2Squad = [];
  
  Set<String> _selectedIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSquads();
  }





  Future<void> _loadSquads() async {
    // Fetch from Firestore
    final allPlayers = await FirestorePlayerService().getPlayers(widget.matchId);
    
    if (allPlayers.isEmpty) {
       // Optional: Show warning or handle empty state
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No players found in database for this match.")));
    }

    if (mounted) {
      setState(() {
        _team1Squad = _sortPlayersByRole(allPlayers.where((p) => p.teamShortName == widget.match.team1ShortName).toList());
        _team2Squad = _sortPlayersByRole(allPlayers.where((p) => p.teamShortName == widget.match.team2ShortName).toList());
      });
    }
    
    // Check if Playing XI already exists
    final matchDoc = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get();
    if (matchDoc.exists && matchDoc.data()!.containsKey('playingXI')) {
       final existing = List<String>.from(matchDoc.data()!['playingXI']);
       setState(() {
         _selectedIds = existing.toSet();
       });
    }
  }

  List<PlayerModel> _sortPlayersByRole(List<PlayerModel> players) {
    const roleOrder = {'WK': 0, 'BAT': 1, 'AR': 2, 'BOWL': 3};
    players.sort((a, b) {
      int roleA = roleOrder[a.role] ?? 99;
      int roleB = roleOrder[b.role] ?? 99;
      if (roleA != roleB) return roleA.compareTo(roleB);
      return a.name.compareTo(b.name); // Secondary sort by name
    });
    return players;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _confirmLineup() async {
    // Validate: 11 per team? 
    // User request: "Admin selects EXACTLY 11 players per team"
    
    int t1Count = _team1Squad.where((p) => _selectedIds.contains(p.id)).length;
    int t2Count = _team2Squad.where((p) => _selectedIds.contains(p.id)).length;

    if (t1Count != 11 || t2Count != 11) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text("Invalid Count! Team 1: $t1Count/11, Team 2: $t2Count/11"),
         backgroundColor: Colors.red,
       ));
       return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        'playingXI': _selectedIds.toList(),
        'lineupStatus': 'Confirmed',
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Playing XI Confirmed & Locked!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importSquadFromApi() async {
     setState(() => _isLoading = true);
     try {
       final apiService = ref.read(cricketApiServiceProvider);
       
       final result = await apiService.fetchSquads(
        widget.match.id, 
        widget.match.seriesId,
        widget.match.team1Id,
        widget.match.team2Id,
        widget.match.team1ShortName, 
        widget.match.team2ShortName
       );
       
       final rawPlayers = result['players'] as List<dynamic>;
       final isXI = result['isXI'] as bool;

       if (rawPlayers.isEmpty) {
          throw "No squad data found via API.";
       }
       
       List<PlayerModel> parsedPlayers = rawPlayers.map((json) {
         return PlayerModel(
           id: json['id'],
           name: json['name'],
           teamShortName: json['teamShortName'],
           role: json['role'],
           credits: (json['credits'] as num).toDouble(),
           imageUrl: json['imageUrl'] ?? '',
           points: 0,
         );
       }).toList();

       if (isXI) {
          // Auto-Select Logic
          setState(() {
             _selectedIds = parsedPlayers.map((p) => p.id).toSet();
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auto-Selected ${parsedPlayers.length} Playing XI Players!")));
       } else {
          // Full Squad Import Logic
          await FirestorePlayerService().saveSquad(widget.matchId, parsedPlayers);
          await _loadSquads();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Imported ${parsedPlayers.length} Players into Pool!")));
       }
       
     } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import Failed: $e")));
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Lineup Management"),
          bottom: TabBar(
            tabs: [
              Tab(text: "${widget.match.team1ShortName} (${_countSelected(_team1Squad)}/11)"),
              Tab(text: "${widget.match.team2ShortName} (${_countSelected(_team2Squad)}/11)"),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _importSquadFromApi,
              icon: const Icon(Icons.cloud_download),
              tooltip: "Import Squad from API",
            ),
            IconButton(
              onPressed: _isLoading ? null : _confirmLineup,
              icon: const Icon(Icons.check_circle),
              tooltip: "Confirm Playing XI",
            )
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                   _buildTeamList(_team1Squad),
                   _buildTeamList(_team2Squad),
                ],
              ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade900,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmLineup, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("CONFIRM PLAYING XI"),
          ),
        ),
      ),
    );
  }

  int _countSelected(List<PlayerModel> squad) {
    return squad.where((p) => _selectedIds.contains(p.id)).length;
  }

  Widget _buildTeamList(List<PlayerModel> squad) {
    return ListView.builder(
      itemCount: squad.length,
      itemBuilder: (context, index) {
        final player = squad[index];
        final isSelected = _selectedIds.contains(player.id);
        
        return CheckboxListTile(
          value: isSelected,
          onChanged: (val) => _toggleSelection(player.id),
          title: Text(player.name),
          subtitle: Text(player.role),
          secondary: CircleAvatar(child: Text(player.role[0])),
        );
      },
    );
  }
}
