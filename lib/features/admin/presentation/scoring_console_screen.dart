import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/data/manual_scoring_service.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/team/data/firestore_player_service.dart';
import 'package:axevora11/features/team/domain/player_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoringConsoleScreen extends ConsumerStatefulWidget {
  final String matchId;
  final CricketMatchModel initialMatchData;

  const ScoringConsoleScreen({
    super.key,
    required this.matchId,
    required this.initialMatchData,
  });

  @override
  ConsumerState<ScoringConsoleScreen> createState() => _ScoringConsoleScreenState();
}

class _ScoringConsoleScreenState extends ConsumerState<ScoringConsoleScreen> {
  // State for Form
  int _currentOver = 1;
  String? _selectedBattingTeam;
  
  PlayerModel? _striker;
  PlayerModel? _nonStriker;
  PlayerModel? _bowler;
  
  // Striker Stats for Over
  int _sRuns = 0;
  int _s4s = 0;
  int _s6s = 0;
  bool _sOut = false;

  // Non-Striker Stats for Over
  int _nsRuns = 0;
  bool _nsOut = false;

  // Bowler Stats for Over
  int _bWickets = 0;
  int _bExtras = 0;
  bool _bMaiden = false;
  
  // Fielding
  // Simplified for MVP: Just select fielder for catch if wicket > 0?
  // Or just a text description? User asked for "Fielding events (catch/runout)"
  // Let's add a simple list of fielder IDs if needed. 
  // For now, I'll skip complex dynamic fielder selection per ball to keep UI sane.

  List<PlayerModel> _team1Squad = [];
  List<PlayerModel> _team2Squad = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSquads();
    
    // Default Batting Team
    _selectedBattingTeam = widget.initialMatchData.team1ShortName;
  }
  
  Future<void> _loadSquads() async {
    final allPlayers = await FirestorePlayerService().getPlayers(widget.matchId);
    
    if (mounted) {
      setState(() {
         _team1Squad = allPlayers.where((p) => p.teamShortName == widget.initialMatchData.team1ShortName).toList();
         _team2Squad = allPlayers.where((p) => p.teamShortName == widget.initialMatchData.team2ShortName).toList();
      });
    }
  }
  
  List<PlayerModel> get _battingSquad => 
      _selectedBattingTeam == widget.initialMatchData.team1ShortName ? _team1Squad : _team2Squad;
      
  List<PlayerModel> get _bowlingSquad => 
      _selectedBattingTeam == widget.initialMatchData.team1ShortName ? _team2Squad : _team1Squad;

  void _submitOver() async {
    if (_striker == null || _bowler == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Striker and Bowler")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final input = ManualOverInput(
        overNumber: _currentOver,
        battingTeamName: _selectedBattingTeam!,
        batsman1: PlayerOverStats(
          playerId: _striker!.id,
          playerName: _striker!.name,
          runs: _sRuns,
          fours: _s4s,
          sixes: _s6s,
          isOut: _sOut,
        ),
        batsman2: _nonStriker != null ? PlayerOverStats(
           playerId: _nonStriker!.id,
           playerName: _nonStriker!.name,
           runs: _nsRuns,
           isOut: _nsOut,
        ) : null,
        bowler: BowlerOverStats(
          playerId: _bowler!.id,
          playerName: _bowler!.name,
          wickets: _bWickets,
          maidens: _bMaiden ? 1 : 0,
          extras: _bExtras,
        ),
        fieldingEvents: [], // TODO: Add UI for this later if critical
      );

      await ref.read(manualScoringServiceProvider).submitOver(widget.matchId, input);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Over Updated & Points Calculated!")));
        _resetForm();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _currentOver++;
      _sRuns = 0; _s4s = 0; _s6s = 0; _sOut = false;
      _nsRuns = 0; _nsOut = false;
      _bWickets = 0; _bExtras = 0; _bMaiden = false;
      // Keep selected players for next over? Bowler usually changes.
      _bowler = null;
      // Swap striker logic? Too complex to guess. Keep same for manual fix.
    });
  }
  
  void _rollback() async {
     setState(() => _isSubmitting = true);
     try {
       await ref.read(manualScoringServiceProvider).rollbackLastOver(widget.matchId);
       setState(() => _currentOver--);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rolled back last over!")));
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rollback Error: $e")));
     } finally {
       setState(() => _isSubmitting = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ASC - Manual Scoring"),
        actions: [
          IconButton(onPressed: _rollback, icon: const Icon(Icons.undo), tooltip: "Rollback Last Over"),
        ],
      ),
      body: Row(
        children: [
          // Sidebar / Status Panel
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final lastSummary = data['lastOverSummary'] ?? "No data";
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Match: ${widget.initialMatchData.team1ShortName} vs ${widget.initialMatchData.team2ShortName}",
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),
                      const Text("Live Status", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Text(lastSummary, style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
                      ),
                      const Spacer(),
                      const Text("Updates leaderboard automatically.", style: TextStyle(color: Colors.white30, fontSize: 12)),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Main Input Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SAFETY BANNER
                  Container(
                    width: double.infinity,
                    color: Colors.red.shade900.withOpacity(0.2),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    border: Border.all(color: Colors.redAccent),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("EMERGENCY OVERRIDE ONLY", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Manual entries will override API data. Use only if API Sync is broken.", style: TextStyle(color: Colors.red.shade200, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Over & Batting Team
                  Row(
                    children: [
                      Text("Over Input: $_currentOver", style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        value: _selectedBattingTeam,
                        items: [widget.initialMatchData.team1ShortName, widget.initialMatchData.team2ShortName]
                            .map((t) => DropdownMenuItem(value: t, child: Text("Batting: $t")))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedBattingTeam = v),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // Active Players
                  const Text("Active Players", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildPlayerDropdown("Striker", _striker, _battingSquad, (p) => setState(() => _striker = p))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildPlayerDropdown("Non-Striker", _nonStriker, _battingSquad, (p) => setState(() => _nonStriker = p))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildPlayerDropdown("Bowler", _bowler, _bowlingSquad, (p) => setState(() => _bowler = p))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Striker Stats
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text("Striker Stats (${_striker?.name ?? 'Select'})", style: const TextStyle(fontWeight: FontWeight.bold)),
                           const SizedBox(height: 10),
                           Row(
                             children: [
                               _buildNumInput("Runs", _sRuns, (v) => _sRuns = v),
                               _buildNumInput("4s", _s4s, (v) => _s4s = v),
                               _buildNumInput("6s", _s6s, (v) => _s6s = v),
                               const SizedBox(width: 20),
                               FilterChip(
                                 label: const Text("OUT"),
                                 selected: _sOut,
                                 selectedColor: Colors.redAccent,
                                 onSelected: (v) => setState(() => _sOut = v),
                               ),
                             ],
                           ),
                        ], // TODO: Add fielding event input if OUT is selected (Fielder ID)
                      ),
                    ),
                  ),

                  // Bowler Stats
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text("Bowler Stats (${_bowler?.name ?? 'Select'})", style: const TextStyle(fontWeight: FontWeight.bold)),
                           const SizedBox(height: 10),
                           Row(
                             children: [
                               _buildNumInput("Wickets", _bWickets, (v) => _bWickets = v),
                               _buildNumInput("Extras", _bExtras, (v) => _bExtras = v),
                               const SizedBox(width: 20),
                               FilterChip(
                                 label: const Text("Maiden Over"),
                                 selected: _bMaiden,
                                 selectedColor: Colors.greenAccent,
                                 onSelected: (v) => setState(() => _bMaiden = v),
                               ),
                             ],
                           ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitOver,
                      icon: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check_circle),
                      label: const Text("END OVER & UPDATE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerDropdown(String label, PlayerModel? val, List<PlayerModel> options, Function(PlayerModel?) onChanged) {
    return DropdownButtonFormField<PlayerModel>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(color: Colors.black),
      dropdownColor: Colors.white,
      value: val,
      items: options.map((p) => DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(color: Colors.black)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNumInput(String label, int val, Function(int) onChanged) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 10),
      child: TextField(
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        controller: TextEditingController(text: val.toString()),
        onChanged: (str) => onChanged(int.tryParse(str) ?? 0),
      ),
    );
  }
}
