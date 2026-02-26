import 'package:flutter/material.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class LandingPageContent extends StatelessWidget {
  const LandingPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.offWhite, AppColors.lightBlueBackground],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _SocialPatternPainter()),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
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

                const SizedBox(height: 40),

                // ── APK DOWNLOAD SECTION ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.skyBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.android_rounded, color: AppColors.skyBlue, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Available on Android",
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                              ),
                              Text(
                                "Download the App",
                                style: GoogleFonts.oswald(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Get the full social experience — join live rooms, chat in real-time, and connect with fans.",
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      // Download button + version
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              launchUrl(
                                Uri.parse("https://axevoralabs.com/downloads/axevoralabs.apk"),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            icon: const Icon(Icons.download_rounded, size: 20),
                            label: Text(
                              "Download APK",
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.skyBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: Text(
                              "v1.0 • Free",
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Privacy links as chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildLinkChip(context, "Privacy Policy", "/privacy-policy"),
                          _buildLinkChip(context, "Terms & Conditions", "/terms-and-conditions"),
                          _buildLinkChip(context, "Community Guidelines", "/social-safety"),
                          _buildLinkChip(context, "Contact Us", "/contact"),
                          _buildLinkChip(context, "FAQ", "/faq"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

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

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkChip(BuildContext context, String label, String route) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
        ),
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
          ),
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
