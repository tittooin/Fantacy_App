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
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo);
            }
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey);
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
             if (states.contains(MaterialState.selected)) {
               return const IconThemeData(color: Colors.white, size: 28);
             }
             return const IconThemeData(color: Colors.grey, size: 24);
          }),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: Colors.indigo,
          elevation: 10,
          shadowColor: Colors.black,
          height: 70,
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (idx) => _onItemTapped(idx, context, ref),
          destinations: const [
             NavigationDestination(
                icon: Icon(Icons.flash_on_outlined), 
                selectedIcon: Icon(Icons.flash_on),
                label: "Live"
             ),
             NavigationDestination(
               icon: Icon(Icons.sports_cricket_outlined), 
               selectedIcon: Icon(Icons.sports_cricket),
               label: "My Rooms"
             ),
             NavigationDestination(
               icon: Icon(Icons.chat_bubble_outline), 
               selectedIcon: Icon(Icons.chat_bubble),
               label: "Global"
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
