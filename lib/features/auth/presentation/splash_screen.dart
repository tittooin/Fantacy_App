import 'package:axevora11/core/constants/app_colors.dart';
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
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
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
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: AppColors.primaryBackground),
          ),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_text.png',
                  width: 250,
                  errorBuilder: (c, e, s) => const Icon(Icons.sports_cricket, size: 100, color: AppColors.accentGreen),
                ).animate()
                 .fade(duration: 800.ms)
                 .scale(duration: 800.ms, curve: Curves.easeOutBack),
                 
                 const SizedBox(height: 20),
                 
                 const CircularProgressIndicator(
                   color: AppColors.accentGreen,
                   strokeWidth: 2,
                 ).animate().fade(delay: 1000.ms),
              ],
            ),
          ),
          
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "India’s Skill-Based Fantasy Cricket Platform",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textLight,
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
