import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
=======
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
>>>>>>> dev-update
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

<<<<<<< HEAD
=======
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
    if (!mounted) return; // Added check
    setState(() => _isLoading = true);

    // Hardcoded Real Data from 4th T20I (IND vs NZ) with Images
    // Source: Scraper + Manual Role Mapping
    // Note: Using images.weserv.nl proxy to avoid CORS issues on Web
    final List<Map<String, dynamic>> realPlayers = [
      // INDIA - WK
      { "id": "8352", "name": "Sanju Samson", "teamShortName": "IND", "role": "WK", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c8352/i.jpg", "isPlaying": true },
      { "id": "10276", "name": "Ishan Kishan", "teamShortName": "IND", "role": "WK", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c10276/i.jpg", "isPlaying": true },
      
      // INDIA - BAT
      { "id": "7915", "name": "Suryakumar Yadav", "teamShortName": "IND", "role": "BAT", "credits": 9.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c7915/i.jpg", "isPlaying": true },
      { "id": "12086", "name": "Abhishek Sharma", "teamShortName": "IND", "role": "BAT", "credits": 8.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c12086/i.jpg", "isPlaying": true },
      { "id": "10896", "name": "Rinku Singh", "teamShortName": "IND", "role": "BAT", "credits": 8.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c10896/i.jpg", "isPlaying": true },
      { "id": "9428", "name": "Shreyas Iyer", "teamShortName": "IND", "role": "BAT", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9428/i.jpg", "isPlaying": true },

      // INDIA - AR
      { "id": "11195", "name": "Shivam Dube", "teamShortName": "IND", "role": "AR", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c11195/i.jpg", "isPlaying": true },
      { "id": "9647", "name": "Hardik Pandya", "teamShortName": "IND", "role": "AR", "credits": 9.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9647/i.jpg", "isPlaying": true },
      { "id": "8808", "name": "Axar Patel", "teamShortName": "IND", "role": "AR", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c8808/i.jpg", "isPlaying": true },

      // INDIA - BOWL
      { "id": "9311", "name": "Jasprit Bumrah", "teamShortName": "IND", "role": "BOWL", "credits": 9.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9311/i.jpg", "isPlaying": true },
      { "id": "8292", "name": "Kuldeep Yadav", "teamShortName": "IND", "role": "BOWL", "credits": 9.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c8292/i.jpg", "isPlaying": true },
      { "id": "14659", "name": "Ravi Bishnoi", "teamShortName": "IND", "role": "BOWL", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c14659/i.jpg", "isPlaying": true },
      { "id": "24729", "name": "Harshit Rana", "teamShortName": "IND", "role": "BOWL", "credits": 7.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c24729/i.jpg", "isPlaying": true },
      { "id": "12926", "name": "Varun Chakaravarthy", "teamShortName": "IND", "role": "BOWL", "credits": 8.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c12926/i.jpg", "isPlaying": true },
      { "id": "13217", "name": "Arshdeep Singh", "teamShortName": "IND", "role": "BOWL", "credits": 9.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c13217/i.jpg", "isPlaying": true },

      // NZ - WK
      { "id": "9443", "name": "Tim Seifert", "teamShortName": "NZ", "role": "WK", "credits": 8.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9443/i.jpg", "isPlaying": true },
      { "id": "9838", "name": "Devon Conway", "teamShortName": "NZ", "role": "WK", "credits": 9.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9838/i.jpg", "isPlaying": true },

      // NZ - BAT
      { "id": "10693", "name": "Glenn Phillips", "teamShortName": "NZ", "role": "BAT", "credits": 9.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c10693/i.jpg", "isPlaying": true },
      { "id": "9976", "name": "Mark Chapman", "teamShortName": "NZ", "role": "BAT", "credits": 8.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9976/i.jpg", "isPlaying": true },
      { "id": "52428", "name": "Bevon Jacobs", "teamShortName": "NZ", "role": "BAT", "credits": 7.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c52428/i.jpg", "isPlaying": true },

      // NZ - AR
      { "id": "10100", "name": "Mitchell Santner", "teamShortName": "NZ", "role": "AR", "credits": 9.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c10100/i.jpg", "isPlaying": true },
      { "id": "11177", "name": "Rachin Ravindra", "teamShortName": "NZ", "role": "AR", "credits": 9.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c11177/i.jpg", "isPlaying": true },
      { "id": "10713", "name": "Daryl Mitchell", "teamShortName": "NZ", "role": "AR", "credits": 9.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c10713/i.jpg", "isPlaying": true },
      { "id": "8983", "name": "James Neesham", "teamShortName": "NZ", "role": "AR", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c8983/i.jpg", "isPlaying": true },
      { "id": "9551", "name": "Michael Bracewell", "teamShortName": "NZ", "role": "AR", "credits": 8.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9551/i.jpg", "isPlaying": true },

      // NZ - BOWL
      { "id": "9441", "name": "Kyle Jamieson", "teamShortName": "NZ", "role": "BOWL", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9441/i.jpg", "isPlaying": true },
      { "id": "9067", "name": "Matt Henry", "teamShortName": "NZ", "role": "BOWL", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c9067/i.jpg", "isPlaying": true },
      { "id": "8561", "name": "Ish Sodhi", "teamShortName": "NZ", "role": "BOWL", "credits": 8.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c8561/i.jpg", "isPlaying": true },
      { "id": "8554", "name": "Jacob Duffy", "teamShortName": "NZ", "role": "BOWL", "credits": 7.5, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c8554/i.jpg", "isPlaying": true },
      { "id": "10692", "name": "Lockie Ferguson", "teamShortName": "NZ", "role": "BOWL", "credits": 9.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c10692/i.jpg", "isPlaying": true },
      { "id": "24391", "name": "Zakary Foulkes", "teamShortName": "NZ", "role": "BOWL", "credits": 7.0, "imageUrl": "https://images.weserv.nl/?url=static.cricbuzz.com/a/img/v1/152x152/i1/c24391/i.jpg", "isPlaying": true },
    ];

    try {
      final batch = FirebaseFirestore.instance.batch();
      final collectionRef = FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.match.id.toString())
          .collection('players');

      // 1. Delete existing (Optional, but safe)
      final existing = await collectionRef.get();
      for (var doc in existing.docs) {
        batch.delete(doc.reference);
      }

      // 2. Insert new
      for (var p in realPlayers) {
        final docRef = collectionRef.doc(p['id'].toString());
        batch.set(docRef, p);
      }

      await batch.commit();
      await _fetchPlayers(); // Refresh UI List

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Real Squad Imported Successfully (with Photos)"),
          backgroundColor: Colors.green,
        ));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ));
        setState(() => _isLoading = false);
      }
    }
  }

>>>>>>> dev-update
  @override
  Widget build(BuildContext context) {
    // Filter Players
    final filtered = _players.where((p) {
      if (_selectedTeam == 'All') return true;
<<<<<<< HEAD
      // Depending on how team info is saved. Usually 'teamName' or 'teamId'
      // Assuming 'teamName' for now based on typical rapidapi structure, or we can check simple string match
      // If team data isn't clear, we show all.
      return true; 
=======
      final pTeam = p['teamShortName'] as String?;
      return pTeam == _selectedTeam;
>>>>>>> dev-update
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.match.team1ShortName} vs ${widget.match.team2ShortName}"),
<<<<<<< HEAD
            const Text("Manage Players & Lineups", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
=======
            const Text("Manage Players (Real Data)", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
             icon: const Icon(Icons.cloud_download), 
             tooltip: "Load Real Squad",
             onPressed: _loadRealSquad
          ),
>>>>>>> dev-update
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPlayers),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
<<<<<<< HEAD
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
=======
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
>>>>>>> dev-update
                )
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _players.isEmpty 
<<<<<<< HEAD
                    ? const Center(child: Text("No Players Found.\nUse 'Import' on Dashboard first.", textAlign: TextAlign.center))
=======
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
>>>>>>> dev-update
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final isPlaying = p['isPlaying'] == true;
<<<<<<< HEAD
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: p['image_path'] != null ? NetworkImage(p['image_path']) : null,
                              child: p['image_path'] == null ? Text(p['fullname']?[0] ?? "?") : null,
                            ),
                            title: Text(p['fullname'] ?? "Unknown"),
                            subtitle: Text(p['position']?.toString().toUpperCase() ?? "PLAYER"),
=======
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
>>>>>>> dev-update
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
