import 'package:flutter/material.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPageContent extends StatelessWidget {
  const LandingPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.offWhite,
            AppColors.lightBlueBackground,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle Modern Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: _SocialPatternPainter(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WATCH.\nTALK.\nCONNECT.",
                  style: GoogleFonts.oswald(
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 64,
                    letterSpacing: 1.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Join live interaction rooms around events,\ndiscuss moments in real-time with friends.",
                  style: GoogleFonts.inter(
                    color: AppColors.textDark.withOpacity(0.8),
                    fontSize: 20,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Feature Cards Grid
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _buildFeatureCard(Icons.forum_outlined, "Live Group\nDiscussions"),
                    _buildFeatureCard(Icons.lock_open_outlined, "Private Rooms\nfor Friends"),
                    _buildFeatureCard(Icons.public_outlined, "Global & Invite-\nOnly Rooms"),
                    _buildFeatureCard(Icons.bolt_outlined, "Real-Time\nEvent Updates"),
                  ],
                ),
                
                const Spacer(),
                
                // Mission Statement
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    "AxevoraLabs lets you join global and private rooms to interact around live events and shared interests.",
                    style: GoogleFonts.inter(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String text) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.skyBlue, size: 32),
          const SizedBox(height: 16),
          Text(
            text,
            style: GoogleFonts.oswald(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.2,
            ),
          )
        ],
      ),
    );
  }
}

class _SocialPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.skyBlue.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < size.width; i += 60) {
      for (var j = 0; j < size.height; j += 60) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
