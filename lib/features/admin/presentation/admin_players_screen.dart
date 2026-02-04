import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
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

  Future<void> _importSquad() async {
     setState(() => _isLoading = true);
     try {
       await ref.read(rapidApiServiceProvider).fetchAndSaveSquad(
         widget.match.id.toString(), 
         widget.match.id.toString()
       );
       await _fetchPlayers();
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Squad Imported Successfully!")));
     } catch (e) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("Import Failed: $e"), 
             backgroundColor: Colors.red,
             duration: const Duration(seconds: 5),
             action: SnackBarAction(
               label: "LOAD REAL SQUAD",
               textColor: Colors.white,
               onPressed: _loadRealSquad
             ),
           )
         );
       }
     } finally {
       if(mounted) setState(() => _isLoading = false);
     }
  }

  Future<void> _loadRealSquad() async {
    // Retry Import
    await _importSquad();
  }

  // Removed Hardcoded Fake Data


  @override
  Widget build(BuildContext context) {
    // Filter Players
    final filtered = _players.where((p) {
      if (_selectedTeam == 'All') return true;
      final pTeam = p['teamShortName'] as String?;
      return pTeam == _selectedTeam;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.match.team1ShortName} vs ${widget.match.team2ShortName}"),
            const Text("Manage Players (Real Data)", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
             icon: const Icon(Icons.cloud_download), 
             tooltip: "Load Real Squad",
             onPressed: _loadRealSquad
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPlayers),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedTeam,
                  dropdownColor: Colors.grey.shade800,
                  style: const TextStyle(color: Colors.white),
                  items: ['All', widget.match.team1ShortName, widget.match.team2ShortName].map((t) {
                    return DropdownMenuItem(value: t, child: Text(t == 'All' ? 'All Teams' : t));
                  }).toList(),
                  onChanged: (val) {
                    if(val != null) setState(() => _selectedTeam = val);
                  },
                ),
                ElevatedButton(
                  onPressed: _announceLineups,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
                  child: Text("Announce (${filtered.where((p) => p['isPlaying'] == true).length})")
                )
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _players.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("No Squad Data Found.", textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRealSquad,
                              child: const Text("Load Real Squad Now"),
                            )
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final isPlaying = p['isPlaying'] == true;
                          final role = p['role'] ?? 'Unknown';
                          final imageUrl = p['imageUrl'] as String?;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                              child: (imageUrl == null || imageUrl.isEmpty) ? Text(p['name']?[0] ?? "?") : null,
                            ),
                            title: Text(p['name'] ?? "Unknown"),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200)
                                  ),
                                  child: Text(role.toString(), style: const TextStyle(fontSize: 10, color: Colors.blue)),
                                ),
                                const SizedBox(width: 8),
                                Text("${p['credits']} Cr", style: const TextStyle(fontSize: 12)),
                              ],
                            ),
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
