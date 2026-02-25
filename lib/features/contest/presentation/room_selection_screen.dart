import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';

class RoomSelectionScreen extends ConsumerWidget {
  final CricketMatchModel match;

  const RoomSelectionScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          "Social Hub Selection",
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Start Your Social Hub",
              style: GoogleFonts.oswald(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create a private space for real-time discussion, voice chat, and social interaction with your friends.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildRoomCard(
              context,
              title: "Friends Lounge (Private)",
              subtitle: "Best for close friends",
              description: "Invite-only room with host moderation, live voice chat, and ephemeral notes.",
              color: AppColors.skyBlue,
              icon: Icons.lock_person_rounded,
              onTap: () {
                context.push('/private-room/${match.id}', extra: {
                  'matchData': match.toJson(),
                  'isHost': true,
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildRoomCard(
              context,
              title: "Global Discussion (Public)",
              subtitle: "Connect with everyone",
              description: "Join the largest real-time conversation for this match with thousands of fans.",
              color: AppColors.accentRed,
              icon: Icons.public_rounded,
              onTap: () {
                context.push('/room/${match.id}', extra: match.toJson());
              },
            ),
            
            const SizedBox(height: 40),
            
            _buildBenefitRow(Icons.security_rounded, "Moderated and safe social environment"),
            _buildBenefitRow(Icons.record_voice_over_rounded, "Real-time voice discussions (Live only)"),
            _buildBenefitRow(Icons.verified_user, "Strictly social – No betting or wallet required"),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.oswald(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subtitle.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textLight.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.textLight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
