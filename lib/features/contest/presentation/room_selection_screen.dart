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
          "Create Private Room",
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.vibrantBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose Your Experience",
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create a private room for you and your friends to watch the match and compete!",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildRoomCard(
              context,
              title: "Single Match Room",
              price: "₹19",
              description: "Full access to this match's private chat and contest.",
              color: AppColors.vibrantBlue,
              icon: Icons.sports_cricket,
              onTap: () {
                // Navigate to name creation with 19 as preset
                context.push('/match/${match.id}/create-private-contest', extra: match);
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildRoomCard(
              context,
              title: "Full Day Pass",
              price: "₹39",
              description: "Create rooms for ALL matches happening today. Best value!",
              color: AppColors.stadiumRed,
              icon: Icons.flash_on,
              isBestValue: true,
              onTap: () {
                // Feature for full day
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Full Day Pass coming soon!")));
              },
            ),
            
            const SizedBox(height: 40),
            
            _buildBenefitRow(Icons.lock_person, "Private chat only for your circle"),
            _buildBenefitRow(Icons.emoji_events, "Custom prize pools and winners"),
            _buildBenefitRow(Icons.verified_user, "Safe and strictly social (no betting)"),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context, {
    required String title,
    required String price,
    required String description,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool isBestValue = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isBestValue ? color : Colors.grey.shade200, width: isBestValue ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (isBestValue)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
                    ),
                    child: const Text(
                      "BEST VALUE",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.oswald(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      price,
                      style: GoogleFonts.oswald(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
