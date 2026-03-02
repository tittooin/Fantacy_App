import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/data/providers/scorecard_provider.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';

class MatchScoreHeader extends ConsumerWidget {
  final String matchId;
  final CricketMatchModel? match; // Added

  const MatchScoreHeader({super.key, required this.matchId, this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(scorecardProvider(matchId));

    return scoreAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_,__) => const SizedBox.shrink(), // Fail silently or show error
      data: (data) {
         // Fallback logic
         String status = 'Live';
         String t1Score = '';
         String t2Score = '';
         String genericScore = '';
         
         if (data != null) {
           status = data['status_note'] ?? 'Live';
           t1Score = data['team_a_score'] ?? '';
           t2Score = data['team_b_score'] ?? '';
         } else if (match != null) {
           status = match!.status;
           final matchScoreMap = match!.score;
           if (matchScoreMap != null && matchScoreMap.containsKey('displayScore')) {
              genericScore = matchScoreMap['displayScore'].toString();
           }
         } else {
           return const SizedBox.shrink();
         }
         
         // Basic display logic: Show team batting current (simplified)
         // For now, simpler than parsing: Show Team A vs Team B scores
         
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
                         "Live Score",
                         style: const TextStyle(
                           color: Color(0xFF4FC3F7),
                           fontWeight: FontWeight.bold,
                           fontSize: 12,
                         ),
                       ),
                       if (t1Score.isNotEmpty) ...[
                         Text(
                           t1Score, // e.g. "MI 120/4 (15)"
                           style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 20,
                                 fontWeight: FontWeight.w900,
                               ),
                         ),
                         if (t2Score.isNotEmpty && t2Score != 'Yet to Bat')
                         Text(
                           t2Score,
                           style: const TextStyle(
                                 color: Colors.white70,
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold,
                               ),
                         ),
                       ] else if (genericScore.isNotEmpty) ...[
                         Text(
                           genericScore,
                           style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 16,
                                 fontWeight: FontWeight.w900,
                               ),
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ],
                     ],
                   ),
                   const Icon(Icons.analytics_outlined, color: Colors.orangeAccent, size: 28),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.red, size: 8),
                  const SizedBox(width: 8),
                  Text(
                    status.toString().toUpperCase(),
                    style: const TextStyle(
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
      }
    );
  }
}
