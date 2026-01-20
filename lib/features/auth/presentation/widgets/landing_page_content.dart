import 'package:flutter/material.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class LandingPageContent extends StatelessWidget {
  const LandingPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1565C0), // Blue 800 - Better contrast for white text
            Color(0xFF0D47A1), // Blue 900
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle Sports Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: _SportsPatternPainter(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "INDIA'S TRUSTED\nSKILL-BASED\nFANTASY PLATFORM",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 48,
                    letterSpacing: 1.2,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Play Skill-Based Fantasy Contests.\nCompete using Cricket Knowledge.\nWithdraw Winnings to Your Bank Account.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Feature Icon Cards (Stronger Flat style)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildFeatureCard(Icons.sports_cricket, "Skill-Based\nFantasy Sports"),
                    _buildFeatureCard(Icons.account_balance_wallet, "Secure Wallet\nSystem"),
                    _buildFeatureCard(Icons.bolt, "Fast\nWithdrawals*"),
                    _buildFeatureCard(Icons.verified_user, "Fair Play\nSystem"),
                  ],
                ),
                
                const SizedBox(height: 8),
                const Text(
                  "*Withdrawals subject to verification",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                
                const SizedBox(height: 56), // Increased spacing
                
                // CTA Button (Hero look)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                       launchUrl(Uri.parse('https://raw.githubusercontent.com/tittooin/Fantacy_App/main/release_builds/app-release.apk'), mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24), // Increased padding
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16), // Softer corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), // Stronger shadow
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.android, color: Color(0xFF2EA7FF), size: 32), // Bigger icon
                          const SizedBox(width: 16), // Increased gap
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Download Axevora11 App", 
                                style: TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  color: Color(0xFF0B1E3C), // Darker text for contrast
                                  fontSize: 20,
                                )),
                              Text("v1.0.0 • Size: 18MB", 
                                style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Micro-Legal & Navigation (Repositioned)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Skill-Based Fantasy Sports | 18+ Only",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Text("No Gambling | No Chance-Based Games",
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    // Legal Links
                    Wrap(
                      spacing: 20,
                      children: [
                        _buildFooterLink(context, "Terms", "/terms"),
                        _buildFooterLink(context, "Privacy", "/privacy"),
                        _buildFooterLink(context, "Refunds", "/refund-policy"),
                        _buildFooterLink(context, "Fair Play", "/fair-play"),
                        _buildFooterLink(context, "Responsible Play", "/responsible-play"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("© 2026 AXEVORA11. All Rights Reserved.",
                        style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
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
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // Solid White
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2EA7FF), size: 36), // Accented Icon
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0B1E3C), // Darker text for readability
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text, String route) {
    return InkWell(
      onTap: () => context.push(route),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _SportsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble() - 100, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
