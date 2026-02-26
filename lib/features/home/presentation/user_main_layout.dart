import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/cricket_api/data/providers/match_provider.dart';

class UserMainLayout extends ConsumerWidget {
  final Widget child;

  const UserMainLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/my-matches')) return 1;
    if (location.contains('room')) return 2; // Highlighting Chat/Global
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/my-matches');
        break;
      case 2:
        final allMatches = ref.read(matchListProvider).value ?? [];
        Map<String, dynamic>? liveMatch;
        try {
          liveMatch = allMatches.firstWhere(
            (m) => m['status'] == 'Live' || m['status'] == 'In Progress',
          );
        } catch (_) {
          liveMatch = allMatches.isNotEmpty ? allMatches.first : null;
        }

        if (liveMatch != null && liveMatch['id'] != null) {
          context.push('/room/${liveMatch['id']}', extra: liveMatch);
        } else {
          context.go('/home');
        }
        break;
      case 3:
        final uid = ref.read(authUserIdProvider);
        if (uid != null) {
           context.go('/profile/$uid');
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile loading...")));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Desktop Wrapper logic can be added here if needed, 
    // but typically ShellRoute wraps the internal content.
    // For now, simple Scaffold with BottomNav.
    
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0EB0E2)); // AppColors.skyBlue
            }
            return const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B)); // AppColors.textLight
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
             if (states.contains(MaterialState.selected)) {
               return const IconThemeData(color: Colors.white, size: 24);
             }
             return const IconThemeData(color: Color(0xFF64748B), size: 22);
          }),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF0EB0E2), // AppColors.skyBlue
          elevation: 10,
          shadowColor: Colors.black,
          height: 70,
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (idx) => _onItemTapped(idx, context, ref),
          destinations: const [
             NavigationDestination(
                icon: Icon(Icons.bolt_outlined), 
                selectedIcon: Icon(Icons.bolt_rounded),
                label: "Live"
             ),
             NavigationDestination(
               icon: Icon(Icons.forum_outlined), 
               selectedIcon: Icon(Icons.forum_rounded),
               label: "My Rooms"
             ),
             NavigationDestination(
               icon: Icon(Icons.public_rounded), 
               selectedIcon: Icon(Icons.public_rounded),
               label: "Global"
             ),
             NavigationDestination(
               icon: Icon(Icons.person_outline_rounded), 
               selectedIcon: Icon(Icons.person_rounded),
               label: "Profile"
             ),
          ],
        ),
      ),
    );
  }
}
