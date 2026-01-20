import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';

class UserMainLayout extends ConsumerWidget {
  final Widget child;

  const UserMainLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/my-matches')) return 1;
    if (location.startsWith('/rewards')) return 2;
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
        context.go('/rewards');
        break;
      case 3:
        final user = ref.read(userEntityProvider).value;
        if (user != null) {
           context.go('/profile/${user.uid}');
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
          labelTextStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          iconTheme: MaterialStateProperty.resolveWith((states) {
             if (states.contains(MaterialState.selected)) {
               return const IconThemeData(color: Colors.white);
             }
             return const IconThemeData(color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: Colors.indigo,
          elevation: 2,
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (idx) => _onItemTapped(idx, context, ref),
          destinations: const [
             NavigationDestination(
               icon: Icon(Icons.home_outlined), 
               selectedIcon: Icon(Icons.home),
               label: "Home"
             ),
             NavigationDestination(
               icon: Icon(Icons.emoji_events_outlined), 
               selectedIcon: Icon(Icons.emoji_events),
               label: "My Matches"
             ),
             NavigationDestination(
               icon: Icon(Icons.card_giftcard_outlined), 
               selectedIcon: Icon(Icons.card_giftcard),
               label: "Rewards"
             ),
             NavigationDestination(
               icon: Icon(Icons.person_outline), 
               selectedIcon: Icon(Icons.person),
               label: "Profile"
             ),
          ],
        ),
      ),
    );
  }
}
