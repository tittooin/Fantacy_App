import 'package:flutter/material.dart';
import 'package:axevora11/features/team/domain/player_model.dart';

import 'package:go_router/go_router.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';

class TeamPreviewScreen extends StatelessWidget {
  final List<PlayerModel> selectedPlayers;
  final String team1Name;
  final String team2Name;
  final bool isEditMode;
  final String? matchId;
  final CricketMatchModel? match; // Required for editing

  const TeamPreviewScreen({
    super.key,
    required this.selectedPlayers,
    required this.team1Name,
    required this.team2Name,
    this.isEditMode = false,
    this.matchId,
    this.match,
  });

  @override
  Widget build(BuildContext context) {
    // Categorize players
    final wk = selectedPlayers.where((p) => p.role == 'WK').toList();
    final bat = selectedPlayers.where((p) => p.role == 'BAT').toList();
    final ar = selectedPlayers.where((p) => p.role == 'AR').toList();
    final bowl = selectedPlayers.where((p) => p.role == 'BOWL').toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Team Preview", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               if (isEditMode && matchId != null && match != null) {
                 // Navigate to Team Builder with pre-filled data
                 context.push('/match/$matchId/create-team', extra: {
                   'match': match,
                   'initialPlayers': selectedPlayers
                 });
               } else {
                 Navigator.pop(context);
               }
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)], // Grass Green
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Pitch Background Painter (Optional, or just simple container)
            Positioned.fill(
              child: CustomPaint(
                painter: CricketPitchPainter(),
              ),
            ),
            
            // Player Layer
            Column(
              children: [
                const SizedBox(height: 80), // AppBar Space
                const Text("WICKET KEEPERS", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
                _buildPlayerRow(wk),
                
                const Spacer(),
                const Text("BATSMEN", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
                _buildPlayerRow(bat),
                
                const Spacer(),
                const Text("ALL ROUNDERS", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
                _buildPlayerRow(ar),
                
                const Spacer(),
                const Text("BOWLERS", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
                _buildPlayerRow(bowl),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(List<PlayerModel> players) {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: players.map((p) => _buildPlayerIcon(p)).toList(),
      ),
    );
  }

  Widget _buildPlayerIcon(PlayerModel player) {
    final isTeam1 = player.teamShortName == team1Name;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
             Container(
               width: 50, height: 50,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: Colors.white,
                 border: Border.all(color: isTeam1 ? Colors.white : Colors.black, width: 2),
                 image: (player.imageUrl.isNotEmpty) 
                    ? DecorationImage(image: NetworkImage(player.imageUrl), fit: BoxFit.cover)
                    : null,
                 boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
               ),
               child: player.imageUrl.isEmpty 
                  ? Center(child: Text(player.teamShortName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))
                  : null,
             ),
             // Role Badge
             Positioned(
               bottom: 0,
               right: 0,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                 decoration: BoxDecoration(
                   color: isTeam1 ? Colors.blue : Colors.red,
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   player.role, 
                   style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)
                 ),
               ),
             )
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4)
          ),
          child: Text(
            player.name.split(' ').last, // Last Name only
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
         Text(
          "${player.credits} Cr",
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
      ],
    );
  }
}

class CricketPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC2B280) // Dust/Pitch Color
      ..style = PaintingStyle.fill;
      
    // Draw Pitch in center
    final pitchWidth = size.width * 0.4;
    final pitchHeight = size.height * 0.6;
    final pitchRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: pitchWidth,
      height: pitchHeight,
    );
    
    // canvas.drawRect(pitchRect, paint); // Simple Pitch
    
    // Or better: Draw Inner Ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width/2, size.height/2), width: size.width * 0.8, height: size.height * 0.7), 
      ringPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
