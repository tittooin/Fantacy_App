import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';

class AdminPlayersScreen extends ConsumerStatefulWidget {
  final CricketMatchModel match;

  const AdminPlayersScreen({super.key, required this.match});

  @override
  ConsumerState<AdminPlayersScreen> createState() => _AdminPlayersScreenState();
}

class _AdminPlayersScreenState extends ConsumerState<AdminPlayersScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _players = [];
  String _selectedTeam = 'All'; // 'All', 'Team1', 'Team2'
  
  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    setState(() => _isLoading = true);
    try {
      final qs = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.match.id.toString())
          .collection('players')
          .get();

      setState(() {
        _players = qs.docs.map((d) => d.data()).toList();
      });
    } catch (e) {
      debugPrint("Error fetching players: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlaying(String playerId, bool currentStatus) async {
    // Optimistic Update
    final index = _players.indexWhere((p) => p['id'].toString() == playerId);
    if(index != -1) {
      setState(() {
        _players[index]['isPlaying'] = !currentStatus;
      });
    }

    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.match.id.toString())
          .collection('players')
          .doc(playerId)
          .update({'isPlaying': !currentStatus});
    } catch (e) {
      // Revert if failed
      if(index != -1) {
        setState(() {
          _players[index]['isPlaying'] = currentStatus;
        });
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
  
  Future<void> _announceLineups() async {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.match.id.toString())
          .update({'lineupStatus': 'announced'}); 
      
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lineups Announced! Badge will be visible in App.")));
  }

  @override
  Widget build(BuildContext context) {
    // Filter Players
    final filtered = _players.where((p) {
      if (_selectedTeam == 'All') return true;
      // Depending on how team info is saved. Usually 'teamName' or 'teamId'
      // Assuming 'teamName' for now based on typical rapidapi structure, or we can check simple string match
      // If team data isn't clear, we show all.
      return true; 
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.match.team1ShortName} vs ${widget.match.team2ShortName}"),
            const Text("Manage Players & Lineups", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPlayers),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text("Select Playing 11:"),
                ElevatedButton(
                  onPressed: _announceLineups,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
                  child: const Text("Announce Lineups")
                )
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _players.isEmpty 
                    ? const Center(child: Text("No Players Found.\nUse 'Import' on Dashboard first.", textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final isPlaying = p['isPlaying'] == true;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: p['image_path'] != null ? NetworkImage(p['image_path']) : null,
                              child: p['image_path'] == null ? Text(p['fullname']?[0] ?? "?") : null,
                            ),
                            title: Text(p['fullname'] ?? "Unknown"),
                            subtitle: Text(p['position']?.toString().toUpperCase() ?? "PLAYER"),
                            trailing: Switch(
                              value: isPlaying, 
                              onChanged: (val) => _togglePlaying(p['id'].toString(), isPlaying),
                              activeColor: Colors.green,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
