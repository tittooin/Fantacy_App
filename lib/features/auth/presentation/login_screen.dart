
import 'package:axevora11/features/auth/presentation/widgets/landing_page_content.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Desktop Split View
            return Row(
              children: [
                // Left Side: Login Card (Phone Mockup Look)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: AppColors.skyBlue.withOpacity(0.1),
                    child: Center(
                      child: Container(
                        width: 420,
                        height: 850,
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white, width: 12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.skyBlue.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: SingleChildScrollView(
                            child: _buildLoginContent(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Right Side: Landing Content
                const Expanded(
                  flex: 3,
                  child: LandingPageContent(),
                ),
              ],
            );
          } else {
            // Mobile View
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.lightBlueBackground, Colors.white],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: _buildLoginContent(context),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoginContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. APP BRANDING (TOP)
          Column(
            children: [
              Text(
                "AXEVORA",
                style: GoogleFonts.oswald(
                  color: AppColors.darkNavy,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                 "LABS",
                 style: GoogleFonts.oswald(
                   color: AppColors.skyBlue,
                   fontSize: 32,
                   fontWeight: FontWeight.w900,
                   letterSpacing: 2,
                 ),
              ),
              const SizedBox(height: 4),
              Text(
                "A Social Interaction Platform",
                style: GoogleFonts.inter(
                  color: AppColors.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 48),

          // 2. MAIN HEADLINE (CENTER)
          Text(
            "Watch. Talk. Connect.",
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(
              color: AppColors.textDark,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Join live interaction rooms around events,\ndiscuss moments in real-time with friends.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontSize: 16,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 48),

          // 3. PRIMARY CTA
          Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade100, width: 2),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        else ...[
                           // Representing Google G with a colored circle for now or Icon
                          const Icon(Icons.login_rounded, color: AppColors.skyBlue),
                          const SizedBox(width: 12),
                          Text(
                            "Continue with Google", 
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Quick & secure sign-in",
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),

          // 4. SUPPORTING FEATURES SECTION
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureItem(Icons.forum_rounded, "Live Group\nDiscussions"),
              _buildFeatureItem(Icons.lock_person_rounded, "Private Rooms\nfor Friends"),
              _buildFeatureItem(Icons.public_rounded, "Global & Invite-\nOnly Rooms"),
              _buildFeatureItem(Icons.bolt_rounded, "Real-Time\nEvent Updates"),
            ],
          ),

          const SizedBox(height: 32),

          // 5. INFO / EXPLANATION CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightBlueBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.skyBlue.withOpacity(0.1)),
            ),
            child: Text(
              "AxevoraLabs lets you join global and private rooms to interact around live events and shared interests.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 6. DISCLAIMER
          Text(
            "This platform is designed for social interaction and discussions only. No betting, gambling, or cash-based rewards are supported.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // 7. AGE DISCLAIMER
          Text(
            "18+ Only. Please use responsibly.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.accentRed.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 32),

          // 8. FOOTER LINKS
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildFooterLink("Privacy Policy", "/privacy"),
              const Text("|", style: TextStyle(color: Colors.grey, fontSize: 12)),
              _buildFooterLink("Terms & Conditions", "/terms"),
              const Text("|", style: TextStyle(color: Colors.grey, fontSize: 12)),
              _buildFooterLink("Community Guidelines", "/community"),
              const Text("|", style: TextStyle(color: Colors.grey, fontSize: 12)),
              _buildFooterLink("Contact Us", "/contact"),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.skyBlue, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(
              color: AppColors.textDark,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, String route) {
    return InkWell(
      onTap: () => context.push(route),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In Failed: $e"))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
