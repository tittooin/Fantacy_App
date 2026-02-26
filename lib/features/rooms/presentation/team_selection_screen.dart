import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/core/api/fantasy_api_client.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';

class TeamSelectionScreen extends ConsumerStatefulWidget {
  final String matchId;
  const TeamSelectionScreen({super.key, required this.matchId});

  @override
  ConsumerState<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends ConsumerState<TeamSelectionScreen> {
  List<Map<String, dynamic>> _squad = [];
  final List<Map<String, dynamic>> _selectedPlayers = [];
  bool _isLoading = true;
  String? _teamName;

  @override
  void initState() {
    super.initState();
    _fetchSquad();
  }

  Future<void> _fetchSquad() async {
    final client = ref.read(fantasyApiClientProvider);
    final data = await client.getSquads(widget.matchId);
    if (data != null && data['squads'] != null) {
      final List players = [];
      data['squads'].forEach((teamId, squadData) {
        if (squadData['players'] != null) {
          players.addAll((squadData['players'] as List).map((p) => {
            ...p,
            'teamId': teamId,
            'teamName': squadData['teamName'] ?? 'Team',
          }));
        }
      });
      setState(() {
        _squad = List<Map<String, dynamic>>.from(players);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _togglePlayer(Map<String, dynamic> player) {
    setState(() {
      if (_selectedPlayers.any((p) => p['id'] == player['id'])) {
        _selectedPlayers.removeWhere((p) => p['id'] == player['id']);
      } else {
        if (_selectedPlayers.length < 11) {
          _selectedPlayers.add(player);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only select 11 players')),
          );
        }
      }
    });
  }

  Future<void> _saveTeam() async {
    if (_selectedPlayers.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select exactly 11 players')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = ref.read(userEntityProvider).value;
    final client = ref.read(fantasyApiClientProvider);

    final payload = {
      'userId': user?.uid ?? 'guest',
      'matchId': widget.matchId,
      'teamName': _teamName ?? 'My Team ${DateTime.now().millisecond}',
      'players': _selectedPlayers.map((p) => {
        'player_id': p['id'],
        'name': p['name'],
        'role': p['role'],
      }).toList(),
      'captainId': _selectedPlayers[0]['id'], // Default first for now
      'viceCaptainId': _selectedPlayers[1]['id'], // Default second for now
    };

    final res = await client.saveTeam(payload);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team saved successfully!')),
        );
        context.pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res['error']}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('SELECT YOUR 11', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${_selectedPlayers.length}/11', 
                style: GoogleFonts.oswald(color: AppColors.skyBlue, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _squad.length,
                  itemBuilder: (context, index) {
                    final p = _squad[index];
                    final isSelected = _selectedPlayers.any((sp) => sp['id'] == p['id']);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.offWhite,
                        child: Text(p['role']?[0] ?? 'P', style: const TextStyle(fontSize: 10)),
                      ),
                      title: Text(p['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${p['teamName']} • ${p['role'] ?? 'Player'}', style: const TextStyle(fontSize: 12)),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _togglePlayer(p),
                        activeColor: AppColors.skyBlue,
                      ),
                      onTap: () => _togglePlayer(p),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: ElevatedButton(
                  onPressed: _selectedPlayers.length == 11 ? _saveTeam : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('SAVE TEAM', style: GoogleFonts.oswald(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
    );
  }
}
