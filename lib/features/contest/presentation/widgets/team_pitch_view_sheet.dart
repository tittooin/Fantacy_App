import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
import 'package:axevora11/features/team/presentation/providers/team_provider.dart';
import 'package:axevora11/features/cricket_api/data/providers/fantasy_points_provider.dart';

class TeamPitchViewSheet extends ConsumerWidget {
  final String teamId;
  final String teamName;
  final double totalPoints;
  final String matchId;

  const TeamPitchViewSheet({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.totalPoints,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch team details
    final allTeams = ref.watch(teamProvider);
    final team = allTeams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => TeamEntity(
        id: teamId,
        userId: '',
        matchId: matchId,
        teamName: teamName,
        players: [],
        captainId: '',
        viceCaptainId: '',
        totalPoints: totalPoints,
      ),
    );

    // Fetch player points
    final pointsAsync = ref.watch(fantasyPointsProvider(matchId));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teamName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${team.players.length} Players',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                totalPoints.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Total Points',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Player List
              Expanded(
                child: pointsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Unable to load player points.\nShowing team composition only.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  data: (pointsMap) {
                    if (team.players.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Team data not available'),
                        ),
                      );
                    }

                    // Group players by role
                    final wk = team.players.where((p) => p.role == 'WK').toList();
                    final bat = team.players.where((p) => p.role == 'BAT').toList();
                    final ar = team.players.where((p) => p.role == 'AR').toList();
                    final bowl = team.players.where((p) => p.role == 'BOWL').toList();

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (wk.isNotEmpty) _buildRoleSection('WICKET-KEEPERS', wk, pointsMap ?? {}, team),
                        if (bat.isNotEmpty) _buildRoleSection('BATTERS', bat, pointsMap ?? {}, team),
                        if (ar.isNotEmpty) _buildRoleSection('ALL-ROUNDERS', ar, pointsMap ?? {}, team),
                        if (bowl.isNotEmpty) _buildRoleSection('BOWLERS', bowl, pointsMap ?? {}, team),
                        const SizedBox(height: 20),
                        _buildLegend(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleSection(
    String roleTitle,
    List<dynamic> players,
    Map<String, double> pointsMap,
    TeamEntity team,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            '$roleTitle (${players.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...players.map((player) => _buildPlayerCard(player, pointsMap, team)),
      ],
    );
  }

  Widget _buildPlayerCard(
    dynamic player,
    Map<String, double> pointsMap,
    TeamEntity team,
  ) {
    final playerId = player.id.toString();
    final basePoints = pointsMap[playerId] ?? 0.0;
    final isCaptain = playerId == team.captainId;
    final isViceCaptain = playerId == team.viceCaptainId;
    
    // Calculate multiplied points
    double finalPoints = basePoints;
    String multiplierText = '';
    
    if (isCaptain) {
      finalPoints = basePoints * 2;
      multiplierText = '2x';
    } else if (isViceCaptain) {
      finalPoints = basePoints * 1.5;
      multiplierText = '1.5x';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCaptain
              ? Colors.amber.shade300
              : isViceCaptain
                  ? Colors.blue.shade300
                  : Colors.grey.shade200,
          width: isCaptain || isViceCaptain ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Player Avatar/Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCaptain
                  ? Colors.amber.shade100
                  : isViceCaptain
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isCaptain
                    ? 'C'
                    : isViceCaptain
                        ? 'VC'
                        : player.role ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isCaptain
                      ? Colors.amber.shade900
                      : isViceCaptain
                          ? Colors.blue.shade900
                          : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name ?? 'Unknown Player',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      player.role ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (multiplierText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCaptain ? Colors.amber.shade200 : Colors.blue.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          multiplierText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCaptain ? Colors.amber.shade900 : Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Points Display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                finalPoints.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              if (multiplierText.isNotEmpty)
                Text(
                  '(${basePoints.toStringAsFixed(1)})',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Captain (2x points)', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Vice-Captain (1.5x)', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
