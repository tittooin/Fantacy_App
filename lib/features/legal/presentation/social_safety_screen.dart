import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SocialSafetyScreen extends StatelessWidget {
  const SocialSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Safe & Social", style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.vibrantBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.vibrantBlue, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_user, size: 64, color: Colors.white).animate().scale(delay: 200.ms),
                  const SizedBox(height: 16),
                  Text(
                    "Strictly Social. Purely Sports.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    title: "No Betting, No Gambling",
                    description: "AxevoraLabs is a platform for social sports engagement. We do not facilitate any form of betting or gambling. Our rooms are for strategy and conversation only.",
                    icon: Icons.not_interested,
                    color: AppColors.stadiumRed,
                  ),
                  _buildSection(
                    context,
                    title: "Friendly Chats Only",
                    description: "We maintain a positive environment. Harassment, abusive language, or spamming in room chats will lead to an immediate ban.",
                    icon: Icons.forum_outlined,
                    color: AppColors.vibrantBlue,
                  ),
                  _buildSection(
                    context,
                    title: "Verified Users",
                    description: "Connect with real fans. Our KYC process ensures that you are interacting with verified community members.",
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                         const Text(
                          "Our Mission",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "To bring sports fans together in a safe, social lounge where the love for the game comes first.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vibrantBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("I Understand", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
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
                    fontSize: 13,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
