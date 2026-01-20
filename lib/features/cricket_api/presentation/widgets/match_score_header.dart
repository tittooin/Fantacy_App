import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchScoreHeader extends ConsumerWidget {
  final String matchId;

  const MatchScoreHeader({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to Firestore 'matches' collection for real-time updates
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').doc(matchId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink(); // Initial load or error

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null || !data.containsKey('score')) {
           // FAIL-SAFE: If no score data yet, show nothing or "Waiting for update"
           return const SizedBox.shrink();
        }
        
        final scoreMap = data['score'] as Map<String, dynamic>;
        final scoreData = scoreMap['scoreCard'] as List<dynamic>?;

        if (scoreData == null || scoreData.isEmpty) return const SizedBox.shrink();

        final inning = scoreData.last;
        final batTeam = inning['batTeamDetails']?['batTeamName'] ?? "Team";
        final runs = inning['runs'] ?? 0;
        final wickets = inning['wickets'] ?? 0;
        final overs = inning['overs'] ?? 0.0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1E3C), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         batTeam,
                         style: const TextStyle(
                           color: Color(0xFF4FC3F7),
                           fontWeight: FontWeight.bold,
                           fontSize: 14,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.baseline,
                         textBaseline: TextBaseline.alphabetic,
                         children: [
                           Text(
                             "$runs-$wickets",
                             style: const TextStyle(
                               color: Colors.white,
                               fontSize: 28,
                               fontWeight: FontWeight.w900,
                             ),
                           ),
                           const SizedBox(width: 8),
                           Text(
                             "($overs)",
                             style: const TextStyle(
                               color: Colors.white70,
                               fontSize: 16,
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                   const Icon(Icons.analytics_outlined, color: Colors.orangeAccent, size: 28),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 8),
                  SizedBox(width: 8),
                  Text(
                    "LIVE MATCH SCORE",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
