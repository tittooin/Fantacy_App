import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/features/team/domain/player_model.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
import 'package:axevora11/features/team/presentation/providers/team_provider.dart';

class CaptainSelectionScreen extends ConsumerStatefulWidget {
  final List<PlayerModel> selectedPlayers;
  final String matchId;

  const CaptainSelectionScreen({
    super.key,
    required this.selectedPlayers,
    required this.matchId,
  });

  @override
  ConsumerState<CaptainSelectionScreen> createState() => _CaptainSelectionScreenState();
}

class _CaptainSelectionScreenState extends ConsumerState<CaptainSelectionScreen> {
  String? _captainId;
  String? _viceCaptainId;
  bool _isSaving = false;

  void _saveTeam() async {
    if (_captainId == null || _viceCaptainId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both Captain and Vice-Captain"))
      );
      return;
    }

    setState(() => _isSaving = true);

    // Create and Save Team
    final existingTeams = ref.read(teamProvider).where((t) => t.matchId == widget.matchId).toList();
    final newTeamNumber = existingTeams.length + 1;
    
    final newTeam = TeamEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: widget.matchId,
      userId: "currentUser", // Placeholder
      players: widget.selectedPlayers,
      captainId: _captainId!,
      viceCaptainId: _viceCaptainId!,
      totalPoints: 0,
      teamName: "Team $newTeamNumber",
    );
    
    ref.read(teamProvider.notifier).addTeam(newTeam);
    
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Team $newTeamNumber Saved Successfully!"))
      );
      // Navigate back to Match Detail
      context.goNamed('match_detail', pathParameters: {'matchId': widget.matchId});
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choose Captain & VC", style: TextStyle(color: Colors.white, fontSize: 16)),
            Text("C gets 2x points, VC gets 1.5x points", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: widget.selectedPlayers.length,
        itemBuilder: (context, index) {
          final player = widget.selectedPlayers[index];
          final isCaptain = _captainId == player.id;
          final isViceCaptain = _viceCaptainId == player.id;

          return Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
              color: Colors.black, 
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: (player.imageUrl.isNotEmpty) ? NetworkImage(player.imageUrl) : null,
                      child: player.imageUrl.isEmpty ? Text(player.teamShortName[0], style: const TextStyle(color: Colors.white)) : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(2)),
                        child: Text(player.role, style: const TextStyle(fontSize: 8, color: Colors.white)),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("${player.points} pts", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                
                // Captain Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _captainId = player.id;
                      if (_viceCaptainId == player.id) {
                        _viceCaptainId = null; // Cannot he both
                      }
                    });
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCaptain ? AppColors.accentGold : Colors.transparent,
                      border: Border.all(color: Colors.grey),
                    ),
                    alignment: Alignment.center,
                    child: Text("C", style: TextStyle(fontWeight: FontWeight.bold, color: isCaptain ? Colors.black : Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Vice Captain Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _viceCaptainId = player.id;
                       if (_captainId == player.id) {
                        _captainId = null; // Cannot be both
                      }
                    });
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isViceCaptain ? Colors.white : Colors.transparent,
                      border: Border.all(color: Colors.grey),
                    ),
                    alignment: Alignment.center,
                    child: Text("VC", style: TextStyle(fontWeight: FontWeight.bold, color: isViceCaptain ? Colors.black : Colors.grey)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[900],
        child: ElevatedButton(
          onPressed: (_isSaving || _captainId == null || _viceCaptainId == null) ? null : _saveTeam,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("SAVE TEAM", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
