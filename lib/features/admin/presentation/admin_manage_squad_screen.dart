
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/admin/data/admin_repository.dart';

class AdminManageSquadScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String team1ShortName;
  final String team2ShortName;
  final Map<String, dynamic>? existingSquadData; 

  const AdminManageSquadScreen({
    super.key,
    required this.matchId,
    required this.team1ShortName,
    required this.team2ShortName,
    this.existingSquadData,
  });

  @override
  ConsumerState<AdminManageSquadScreen> createState() => _AdminManageSquadScreenState();
}

class _AdminManageSquadScreenState extends ConsumerState<AdminManageSquadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State for Team A
  List<Map<String, dynamic>> teamPlayersA = [];
  final TextEditingController _nameControllerA = TextEditingController();
  String _selectedRoleA = 'Batsman';

  // State for Team B
  List<Map<String, dynamic>> teamPlayersB = [];
  final TextEditingController _nameControllerB = TextEditingController();
  String _selectedRoleB = 'Batsman';

  bool _isSaving = false;

  final List<String> roles = ['Batsman', 'Bowler', 'All Rounder', 'Wicket Keeper'];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchExistingData());
  }

  Future<void> _fetchExistingData() async {
    try {
      final data = await ref.read(adminRepositoryProvider).getSquad(widget.matchId);
      if (data['success'] == true) {
        final xiA = List<String>.from(data['xiA'] ?? []);
        final xiB = List<String>.from(data['xiB'] ?? []);

        if (data['teamA'] != null) {
          setState(() {
            teamPlayersA = List<Map<String, dynamic>>.from(data['teamA']).map((p) => _reverseTransform(p, xiA)).toList();
            teamPlayersB = List<Map<String, dynamic>>.from(data['teamB']).map((p) => _reverseTransform(p, xiB)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _reverseTransform(Map<String, dynamic> p, List<String> xiIds) {
    String roleFull = 'Batsman';
    switch(p['role']) {
      case 'BAT': roleFull = 'Batsman'; break;
      case 'BOWL': roleFull = 'Bowler'; break;
      case 'AR': roleFull = 'All Rounder'; break;
      case 'WK': roleFull = 'Wicket Keeper'; break;
      default: roleFull = p['role'] ?? 'Batsman';
    }
    
    // Check if ID is in XI List
    final pid = p['id'].toString();
    final isPlaying = xiIds.contains(pid) || p['isPlaying11'] == true;

    return {
      ...p,
      'role': roleFull,
      'image': p['imageUrl'] ?? p['image'] ?? "", 
      'isPlaying11': isPlaying, // Ensure not null
    };
  }

  void _addPlayer(bool isTeamA) {
    final controller = isTeamA ? _nameControllerA : _nameControllerB;
    final role = isTeamA ? _selectedRoleA : _selectedRoleB;
    final list = isTeamA ? teamPlayersA : teamPlayersB;

    if (controller.text.trim().isEmpty) return;

    setState(() {
      list.add({
        "id": "${widget.matchId}_${isTeamA ? 'T1' : 'T2'}_${Date.now()}_${list.length}",
        "name": controller.text.trim(),
        "role": role,
        "teamShortName": isTeamA ? widget.team1ShortName : widget.team2ShortName,
        "image": "",
        "credits": 9.0,
        "points": 0.0,
        "isCaptain": false, 
        "isWicketKeeper": role == 'Wicket Keeper',
        "isPlaying11": true
      });
      controller.clear();
    });
  }

  // Bulk Import Dialog
  void _showBulkImport(bool isTeamA) {
    final TextEditingController _bulkController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900], // Dark Background
        title: Text("Bulk Import ${isTeamA ? widget.team1ShortName : widget.team2ShortName}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Paste names (one per line).", style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _bulkController,
              maxLines: 10,
              style: const TextStyle(color: Colors.white), // Visible Text
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                hintText: "Rohit Sharma\nVirat Kohli\n...",
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
             onPressed: () {
              // Smart Parsing: Split by Newline OR Comma
              final rawText = _bulkController.text;
              debugPrint("🔍 Raw paste text: '$rawText'");
              final items = rawText.split(RegExp(r'[,\n]'));
              debugPrint("🔍 Split into ${items.length} items");

              int uniqueCounter = 0; 

              for (var item in items) {
                var cleanName = item.trim();
                if (cleanName.isEmpty) continue;
                
                uniqueCounter++;
                bool isCaptain = false;
                bool isWicketKeeper = false;
                String role = 'Batsman'; // Default

                // Detect Captain (c) or (C)
                if (cleanName.toLowerCase().contains('(c)')) {
                   isCaptain = true;
                   cleanName = cleanName.replaceAll(RegExp(r'\(c\)', caseSensitive: false), '');
                }

                // Detect WK (wk), (WK), or (w)
                if (cleanName.toLowerCase().contains('(wk)') || cleanName.toLowerCase().contains('(w)')) {
                   isWicketKeeper = true;
                   role = 'Wicket Keeper';
                   cleanName = cleanName.replaceAll(RegExp(r'\((wk|w)\)', caseSensitive: false), '');
                }

                cleanName = cleanName.trim();
                
                debugPrint("🔍 Adding player: '$cleanName', role: $role, WK: $isWicketKeeper");

                if (cleanName.isNotEmpty) {
                  setState(() {
                    (isTeamA ? teamPlayersA : teamPlayersB).add({
                      "id": "${widget.matchId}_${isTeamA ? 'T1' : 'T2'}_${DateTime.now().millisecondsSinceEpoch}_$uniqueCounter",
                      "name": cleanName,
                      "role": role,
                      "teamShortName": isTeamA ? widget.team1ShortName : widget.team2ShortName,
                      "image": "",
                      "credits": 9.0,
                      "points": 0.0,
                      "isCaptain": isCaptain,
                      "isWicketKeeper": isWicketKeeper,
                      "isPlaying11": true
                    });
                  });
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text("Import"),
          )
        ],
      ),
    );
  }

  Future<void> _saveSquads() async {
    if (teamPlayersA.length < 11 || teamPlayersB.length < 11) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Each team must have at least 11 players!")));
       return;
    }

    setState(() => _isSaving = true);

    try {
      // Filter Playing 11 IDs
      final xiA = teamPlayersA.where((p) => p['isPlaying11'] == true).map((p) => p['id'].toString()).toList();
      final xiB = teamPlayersB.where((p) => p['isPlaying11'] == true).map((p) => p['id'].toString()).toList();

      await ref.read(adminRepositoryProvider).saveManualSquad(
        matchId: widget.matchId,
        teamA: teamPlayersA.map((p) => _transformForUpload(p)).toList(),
        teamB: teamPlayersB.map((p) => _transformForUpload(p)).toList(),
        xiA: xiA,
        xiB: xiB,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Squad Saved Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Manage Squad (Manual)"),
        backgroundColor: Colors.grey[900],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: widget.team1ShortName),
            Tab(text: widget.team2ShortName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste),
            onPressed: () => _showBulkImport(_tabController.index == 0),
            tooltip: "Bulk Paste Names",
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSquads,
            tooltip: "Save to Database",
          )
        ],
      ),
      body: (_isSaving || _isLoading)
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
          controller: _tabController,
          children: [
            _buildTeamEditor(true),
            _buildTeamEditor(false),
          ],
        ),
    );
  }

  Widget _buildTeamEditor(bool isTeamA) {
    final list = isTeamA ? teamPlayersA : teamPlayersB;
    final controller = isTeamA ? _nameControllerA : _nameControllerB;

    return Column(
      children: [
        // Add Player Form
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[850],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Player Name",
                    hintStyle: TextStyle(color: Colors.white54),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12),
                 decoration: BoxDecoration(
                   color: Colors.grey[800],
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.white24)
                 ),
                 child: DropdownButton<String>(
                  value: isTeamA ? _selectedRoleA : _selectedRoleB,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  underline: const SizedBox(), // Hide default line
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    setState(() {
                      if (isTeamA) _selectedRoleA = val!; else _selectedRoleB = val!;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () => _addPlayer(isTeamA),
              )
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
              });
            },
            children: [
              for (int index = 0; index < list.length; index++)
                _buildPlayerTile(list[index], index, list)
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerTile(Map<String, dynamic> player, int index, List<Map<String, dynamic>> list) {
    return Card(
      key: ValueKey(player['id']),
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(player['role']),
          child: Text(player['role'][0], style: const TextStyle(color: Colors.white)),
        ),
        title: TextMultiStyle(
          children: [
            TextSpan(text: player['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (player['isCaptain']) const TextSpan(text: " (C)", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            if (player['isWicketKeeper']) const TextSpan(text: " (WK)", style: TextStyle(color: Colors.blueAccent)),
          ]
        ),
        subtitle: Row(
          children: [
            // Role Picker
             DropdownButton<String>(
                value: player['role'],
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                underline: Container(),
                items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  setState(() {
                    player['role'] = val!;
                    if (val == 'Wicket Keeper') player['isWicketKeeper'] = true;
                  });
                },
              ),
              const Spacer(),
              // Actions
              IconButton(
                icon: Icon(player['isCaptain'] ? Icons.star : Icons.star_border, color: player['isCaptain'] ? Colors.amber : Colors.grey),
                onPressed: () {
                   setState(() {
                     // Reset others
                     for(var p in list) p['isCaptain'] = false;
                     player['isCaptain'] = true;
                   });
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: "Set Captain",
              ),
              Checkbox(
                value: player['isPlaying11'],
                activeColor: Colors.green,
                onChanged: (val) => setState(() => player['isPlaying11'] = val),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    list.removeAt(index);
                  });
                },
              )
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch(role) {
      case 'Batsman': return Colors.red[700]!;
      case 'Bowler': return Colors.green[700]!;
      case 'All Rounder': return Colors.purple[700]!;
      case 'Wicket Keeper': return Colors.blue[700]!;
      default: return Colors.grey;
    }
  }

  Map<String, dynamic> _transformForUpload(Map<String, dynamic> p) {
     String roleShort = 'BAT';
     switch(p['role']) {
       case 'Batsman': roleShort = 'BAT'; break;
       case 'Bowler': roleShort = 'BOWL'; break;
       case 'All Rounder': roleShort = 'AR'; break;
       case 'Wicket Keeper': roleShort = 'WK'; break;
       default: roleShort = 'BAT';
     }

     // Determine teamShortName if missing (for legacy players)
     String teamShort = p['teamShortName'] ?? '';
     if (teamShort.isEmpty && p['id'] != null) {
       final id = p['id'].toString();
       if (id.contains('_T1_')) {
         teamShort = widget.team1ShortName;
       } else if (id.contains('_T2_')) {
         teamShort = widget.team2ShortName;
       }
     }

     return {
       ...p,
       'role': roleShort,
       'teamShortName': teamShort,
       'imageUrl': p['image'] ?? "",
       'credits': (p['credits'] is num) ? p['credits'] : 9.0,
       'points': (p['points'] is num) ? p['points'] : 0.0,
     };
  }
}

// Widget Helper
class TextMultiStyle extends StatelessWidget {
  final List<TextSpan> children;
  const TextMultiStyle({super.key, required this.children});
  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(children: children));
  }
}

// Fake Date.now helper for dart (DateTime.now)
extension Date on DateTime {
   static int now() => DateTime.now().millisecondsSinceEpoch;
}
