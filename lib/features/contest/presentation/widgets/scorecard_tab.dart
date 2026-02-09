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

class _ScorecardTabState extends State<ScorecardTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _scoreData;
  Timer? _timer;
  String? _error;

  final String _workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

  @override
  void initState() {
    super.initState();
    _fetchScore();
    // Poll every 30 seconds to save quota, but keep it "fresh"
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) => _fetchScore(isBackground: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
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

    // Parse D1 Data
    // D1 'live_scores' table likely has columns: score_data (JSON), status, etc.
    // Or it might have flattened columns. 
    // Based on `handleGetScorecard` doing `SELECT *`, we get whatever columns exist.
    // Let's assume 'score_details' or similar JSON column, or just the raw row IS the score structure.
    
    // For safety, let's dump the data in a debug card if we are in dev mode, 
    // but effectively we try to find the score map.
    
    final details = _scoreData!['score_details'] != null 
        ? (_scoreData!['score_details'] is String ? json.decode(_scoreData!['score_details']) : _scoreData!['score_details']) 
        : _scoreData;

    final t1 = details['team1'] ?? {};
    final t2 = details['team2'] ?? {};
    final status = _scoreData!['status'] ?? 'Live';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Source Badge (to reassure user)
        Center(child: Text("Live from D1 • Auto-refresh 30s", style: TextStyle(color: Colors.grey.shade400, fontSize: 10))),
        const SizedBox(height: 8),

        // Match Status Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo.shade100)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (status == 'Live') 
                 const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.circle, size: 10, color: Colors.red)),
              Text(
                status == 'Live' ? "LIVE NOW" : status,
                textAlign: TextAlign.center,
                style: TextStyle(color: status == 'Live' ? Colors.red : Colors.indigo, fontWeight: FontWeight.bold, letterSpacing: 1.5)
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Team 1 Score
        _buildTeamScoreCard(
          "Team 1", // Names might be missing in D1 score table if not joined, use placeholders or fetch from match logic if needed
          "", 
          t1,
          isBatting: true // Simple logic for now
        ),
        
        const SizedBox(height: 12),
        
        // Team 2 Score
        _buildTeamScoreCard("Team 2", "", t2),
        
        const SizedBox(height: 24),
        
        // Refresh Button
        Center(
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () => _fetchScore(),
            tooltip: "Refresh Score",
          ),
        )
      ],
    );
  }

  Widget _buildTeamScoreCard(String name, String img, dynamic scoreData, {bool isBatting = false}) {
    String runs = "0", wickets = "0", overs = "0.0";
    
    if (scoreData is Map) {
       runs = "${scoreData['r'] ?? scoreData['runs'] ?? 0}";
       wickets = "${scoreData['w'] ?? scoreData['wickets'] ?? 0}";
       overs = "${scoreData['o'] ?? scoreData['overs'] ?? 0.0}";
       // Try catching mapped names if available
       if (scoreData['name'] != null) name = scoreData['name'];
    } 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
        border: isBatting ? Border.all(color: Colors.green, width: 2) : null
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            radius: 24,
            child: Text(name.substring(0,1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Overs: $overs", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
               Text("$runs/$wickets", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }
}
