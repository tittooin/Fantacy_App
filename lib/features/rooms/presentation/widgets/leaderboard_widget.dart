import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';

class LeaderboardWidget extends StatelessWidget {
  final List leaderboard;

  const LeaderboardWidget({super.key, required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    if (leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard_outlined, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text('No ranks yet.\nCreate your team to join!', 
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textLight)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.offWhite,
          child: Row(
            children: [
              SizedBox(width: 40, child: Text('#', style: GoogleFonts.oswald(color: AppColors.textLight, fontSize: 12))),
              Expanded(child: Text('TEAM NAME', style: GoogleFonts.oswald(color: AppColors.textLight, fontSize: 12))),
              Text('POINTS', style: GoogleFonts.oswald(color: AppColors.textLight, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: leaderboard.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              final rank = index + 1;
              final isTop3 = rank <= 3;

              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isTop3 ? AppColors.skyBlue : AppColors.offWhite,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$rank', 
                      style: GoogleFonts.oswald(
                        color: isTop3 ? Colors.white : AppColors.textDark, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                  ),
                ),
                title: Text(entry['teamName'] ?? 'Anonymous Team', 
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('User ID: ${entry['userId']?.toString().substring(0, 8) ?? 'Unknown'}...', 
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                trailing: Text('${entry['points'] ?? 0}', 
                  style: GoogleFonts.oswald(
                    color: AppColors.skyBlue, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  )),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.accentRed.withOpacity(0.05),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.accentRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Points are calculated based on your 11 selected players. Real-time updates every 60s.',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.accentRed, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
