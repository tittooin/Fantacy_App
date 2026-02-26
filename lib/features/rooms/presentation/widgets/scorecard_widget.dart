import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';

class ScorecardWidget extends StatelessWidget {
  final Map<String, dynamic> scorecardData;

  const ScorecardWidget({super.key, required this.scorecardData});

  @override
  Widget build(BuildContext context) {
    // Structural parsing of scorecardData based on processScorecardData in Worker
    final summary = scorecardData['summary'] ?? {};
    final innings = scorecardData['innings'] as List? ?? [];
    final status = scorecardData['status'] ?? 'Live';

    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildMatchSummary(summary, status),
          const SizedBox(height: 20),
          if (innings.isNotEmpty) ...innings.map((inning) => _buildInningSection(inning)).toList(),
          if (innings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text('Scorecard data is being updated...', 
                    style: GoogleFonts.inter(color: AppColors.textLight)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchSummary(Map<dynamic, dynamic> summary, String status) {
    final t1 = summary['team1'] ?? {};
    final t2 = summary['team2'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.skyBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryTeam('Team 1', t1['runs'], t1['wickets'], t1['overs']),
              Text('VS', style: GoogleFonts.oswald(color: AppColors.skyBlue, fontSize: 20, fontWeight: FontWeight.bold)),
              _buildSummaryTeam('Team 2', t2['runs'], t2['wickets'], t2['overs']),
            ],
          ),
          const SizedBox(height: 12),
          Text(status, style: GoogleFonts.inter(color: AppColors.accentRed, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSummaryTeam(String name, dynamic runs, dynamic wkts, dynamic overs) {
    return Column(
      children: [
        Text(name, style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 4),
        Text('${runs ?? 0}/${wkts ?? 0}', style: GoogleFonts.oswald(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.bold)),
        Text('${overs ?? 0} ov', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
      ],
    );
  }

  Widget _buildInningSection(dynamic inning) {
    final batList = inning['batsman'] as List? ?? [];
    final bowlList = inning['bowler'] as List? ?? [];
    final teamName = inning['batTeamName'] ?? 'Innings';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(teamName, style: GoogleFonts.oswald(color: AppColors.skyBlue, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        _buildBattingTable(batList),
        const SizedBox(height: 16),
        _buildBowlingTable(bowlList),
        const Divider(height: 40),
      ],
    );
  }

  Widget _buildBattingTable(List batsmen) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: ['Batter', 'R', 'B', '4s', '6s'].map((h) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )).toList(),
        ),
        ...batsmen.map((b) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.all(8.0), child: Text(b['name'] ?? '', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('${b['runs'] ?? 0}', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('${b['balls'] ?? 0}', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('${b['fours'] ?? 0}', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('${b['sixes'] ?? 0}', style: const TextStyle(fontSize: 12))),
          ],
        )).toList(),
      ],
    );
  }

  Widget _buildBowlingTable(List bowlers) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: ['Bowler', 'O', 'M', 'R', 'W'].map((h) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )).toList(),
        ),
        ...bowlers.map((b) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.all(8.0), child: Text(b['name'] ?? '', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('${b['overs'] ?? 0}', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('${b['maidens'] ?? 0}', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('${b['runs'] ?? 0}', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('${b['wickets'] ?? 0}', style: const TextStyle(fontSize: 12))),
          ],
        )).toList(),
      ],
    );
  }
}
