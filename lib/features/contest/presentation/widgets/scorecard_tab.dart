import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ScorecardTab extends StatefulWidget {
  final String matchId;

  const ScorecardTab({super.key, required this.matchId});

  @override
  State<ScorecardTab> createState() => _ScorecardTabState();
}

class _ScorecardTabState extends State<ScorecardTab> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _scoreData;
  Timer? _timer;
  String? _error;
  late TabController _tabController;

  final String _workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchScore();
    // Poll every 30 seconds to save quota, but keep it "fresh"
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) => _fetchScore(isBackground: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchScore({bool isBackground = false}) async {
    if (!isBackground) setState(() { _isLoading = true; _error = null; });

    try {
      final url = '$_workerUrl/api/scorecard?matchId=${widget.matchId}';
      debugPrint("Fetching Scorecard from Worker (D1): $url");
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['scorecard'] != null) {
          if (mounted) {
            setState(() {
              _scoreData = data['scorecard'];
              _isLoading = false;
            });
          }
        } else {
           if (mounted) setState(() { _isLoading = false; }); // No data yet
        }
      } else {
        if (!isBackground && mounted) setState(() { _error = "Failed to load score"; _isLoading = false; });
      }
    } catch (e) {
      debugPrint("Score Fetch Error: $e");
      if (!isBackground && mounted) setState(() { _error = "Connection Error"; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _scoreData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _scoreData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _fetchScore(), child: const Text("Retry"))
          ],
        ),
      );
    }

    if (_scoreData == null) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Text("Match hasn't started or no data yet.", style: TextStyle(color: Colors.grey)),
             const SizedBox(height: 16),
             OutlinedButton.icon(
               onPressed: () => _fetchScore(), 
               icon: const Icon(Icons.refresh), 
               label: const Text("Check Now")
             )
           ],
         ),
       );
    }

    // Parse Data
    final detailsStr = _scoreData!['score_details'];
    final details = detailsStr != null 
        ? (detailsStr is String ? json.decode(detailsStr) : detailsStr) 
        : _scoreData;
        
    final List<dynamic> innings = details['innings'] ?? [];
    
    // Sort innings to show latest first or strict Match order?
    // Usually user wants T1 vs T2 tabs.
    // Let's deduce teams from innings data if available
    
    if (innings.isEmpty) {
      return const Center(child: Text("No detailed scorecard available yet."));
    }

    return Column(
      children: [
        // Match Header Status
        Container(
           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
           color: Colors.blueGrey.shade50,
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text("Live from D1 • Auto-refresh 30s", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
               Text(_scoreData!['status_note'] ?? 'Live', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
             ],
           ),
        ),
        
        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: innings.isNotEmpty ? (innings[0]['batteamname'] ?? 'Innings 1') : 'Innings 1'),
            Tab(text: innings.length > 1 ? (innings[1]['batteamname'] ?? 'Innings 2') : 'Innings 2'),
          ],
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInningsView(innings.isNotEmpty ? innings[0] : null),
              _buildInningsView(innings.length > 1 ? innings[1] : null),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInningsView(Map<String, dynamic>? inning) {
    if (inning == null) return const Center(child: Text("Yet to Bat"));

    final score = inning['score'] ?? 0;
    final wickets = inning['wickets'] ?? 0;
    final overs = inning['overs'] ?? 0.0;
    final runrate = inning['runrate'] ?? 0.0;

    final batters = inning['batsman'] ?? inning['scorecard'] ?? [];
    final bowlers = inning['bowler'] ?? [];

    // Filter bowlers from different source or same?
    // Cricbuzz API structure: innings -> scorecard (batters) AND likely 'bowlers' array separate?
    // Wait, debug structure showed:
    // innings[] -> scorecard[] (looks like batters)
    // We need to check if bowlers are in 'card' or separate.
    // Looking at debug log: 
    // "scorecard": [ { "batsmanid": ... } ]
    // Wait, where is bowler data? 
    // Usually Cricbuzz has a separate "bowlcard" or it is mixed.
    // Debug log above only showed "scorecard" with batsman entries.
    // Let's check debug output again for "bowlers"?
    // The previous debug output ended at "Alice Ikuzwe".
    // I need to assume standard structure or handle missing. 
    // If 'bowlers' key exists in inning, use it.
    
    // Fallback: If no bowler key, we might be only getting batting card.
    // Let's implement Batting Table first.

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Innings Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${score}/${wickets}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("(${overs} Ov) RR: $runrate", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        const Divider(),
        
        // Batting Table
        const Text("Batting", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildBattingHeader(),
        ...batters.map<Widget>((b) => _buildBatterRow(b)).toList(),
        
        const SizedBox(height: 24),

        // Bowling Table
        if (bowlers.isNotEmpty) ...[
          const Text("Bowling", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildBowlingHeader(),
          ...bowlers.map<Widget>((b) => _buildBowlerRow(b)).toList(),
        ],
        
        const SizedBox(height: 16),
        const Text("Details usually include Extras/FOW but simplified API might lack them.", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBowlingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: Colors.grey.shade100,
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("Bowler", style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("O", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("M", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("R", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("W", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("ER", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(Map<String, dynamic> b) {
    // "bowlerid": "...", "bowlernames": "..."
    // Keys might vary: 'name', 'bowlernames', 'o', 'm', 'r', 'w', 'economy'
    final name = b['bowlernames'] ?? b['name'] ?? 'Unknown';
    final overs = b['o'] ?? b['overs'] ?? '0';
    final maidens = b['m'] ?? b['maidens'] ?? '0';
    final runs = b['r'] ?? b['runs'] ?? '0';
    final wickets = b['w'] ?? b['wickets'] ?? '0';
    final eco = b['economy'] ?? '0.0';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.white, // FIX: White Background
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5))
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          ),
          Expanded(flex: 1, child: Text("$overs", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87))),
          Expanded(flex: 1, child: Text("$maidens", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87))),
          Expanded(flex: 1, child: Text("$runs", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87))),
          Expanded(flex: 1, child: Text("$wickets", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
          Expanded(flex: 1, child: Text("$eco", textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54))),
        ],
      ),
    );
  }
  Widget _buildBattingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: Colors.grey.shade100,
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("Batter", style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("R", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("B", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("4s", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("6s", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(flex: 1, child: Text("SR", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBatterRow(Map<String, dynamic> b) {
    // "batsmanid": "...", "batsmanname": "..."
    final name = b['names'] ?? b['batsmanname'] ?? b['name'] ?? 'Unknown';
    
    // Fix: Use correct key 'outdec' (lowercase) from API
    String status = b['outdec'] ?? b['outDesc'] ?? b['dismissal'] ?? '';
    status = status.trim();

    // Determine Status Type
    // API returns "not out" for current batters
    final isBatting = status.toLowerCase() == 'not out' || status.toLowerCase() == 'batting';
    final isYetToBat = status.isEmpty;

    final runs = int.tryParse(b['runs']?.toString() ?? '0') ?? 0;
    final balls = int.tryParse(b['balls']?.toString() ?? b['ballnbr']?.toString() ?? '0') ?? 0;
    final fours = b['fours'] ?? 0;
    final sixes = b['sixes'] ?? 0;
    
    // Safety: Calculate Locally to avoid API dependency/issues
    final sr = (balls > 0) ? ((runs / balls) * 100).toStringAsFixed(1) : "0.0";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.white, // Fix: Forced White background for visibility
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5))
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 2),
                if (isBatting)
                  const Text("Batting", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))
                else if (isYetToBat)
                   const Text("Yet to Bat", style: TextStyle(color: Colors.grey, fontSize: 10))
                else
                   Text(status, style: const TextStyle(color: Colors.red, fontSize: 10))
              ],
            ),
          ),
          Expanded(flex: 1, child: Text("$runs", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
          Expanded(flex: 1, child: Text("$balls", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87))),
          Expanded(flex: 1, child: Text("$fours", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87))),
          Expanded(flex: 1, child: Text("$sixes", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87))),
          Expanded(flex: 1, child: Text(sr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54))),
        ],
      ),
    );
  }

}
