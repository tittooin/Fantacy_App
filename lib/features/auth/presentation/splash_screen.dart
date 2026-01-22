
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/core/router/app_router.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      // Logic is handled by Redirect in AppRouter, 
      // but we force a refresh or push to trigger it if needed.
      // Since initial route is '/', Router will decide where to go next based on Auth.
      
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        debugPrint("Splash: User found, going to /home");
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: AppColors.primaryBackground),
          ),
          
          // Overlay Gradient (to make logo pop)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Logo & Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo_text.png',
                  width: 250,
                  errorBuilder: (c, e, s) => const Icon(Icons.sports_cricket, size: 100, color: AppColors.accentGreen),
                ).animate()
                 .fade(duration: 800.ms)
                 .scale(duration: 800.ms, curve: Curves.easeOutBack),
                 
                 const SizedBox(height: 20),
                 
                 // Loader
                 const CircularProgressIndicator(
                   color: AppColors.accentGreen,
                   strokeWidth: 2,
                 ).animate().fade(delay: 1000.ms),
              ],
            ),
          ),
          
          // Footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "India’s Skill-Based Fantasy Cricket Platform",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textGrey,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ).animate().fade(delay: 500.ms).slideY(begin: 1, end: 0),
          )
        ],
      ),
    );
  }
}
