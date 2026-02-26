import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';

class CommentaryWidget extends StatelessWidget {
  final List commentaryList;

  const CommentaryWidget({super.key, required this.commentaryList});

  @override
  Widget build(BuildContext context) {
    if (commentaryList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text('Waiting for match commentary...', 
              style: GoogleFonts.inter(color: AppColors.textLight)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: commentaryList.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = commentaryList[index];
        final over = item['overNumber']?.toString() ?? '';
        final comm = item['commText'] ?? '';
        final isBoundary = comm.toString().toLowerCase().contains('four') || 
                           comm.toString().toLowerCase().contains('six') ||
                           comm.toString().contains('4') ||
                           comm.toString().contains('6');
        final isWicket = comm.toString().toLowerCase().contains('out') || 
                         comm.toString().toLowerCase().contains('wicket');

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (over.isNotEmpty)
                Container(
                  width: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(over, style: GoogleFonts.inter(color: AppColors.skyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comm,
                      style: GoogleFonts.inter(
                        color: isWicket ? AppColors.accentRed : AppColors.textDark,
                        fontSize: 13,
                        fontWeight: (isBoundary || isWicket) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
