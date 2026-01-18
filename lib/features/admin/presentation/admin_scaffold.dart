import 'package:axevora11/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/features/admin/data/match_scheduler_service.dart'; // Added


class AdminScaffold extends StatefulWidget {
  final Widget child;
  const AdminScaffold({super.key, required this.child});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}



class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start Background Scheduler
    MatchSchedulerService().startService();
  }

  @override
  void dispose() {
    // Stop Background Scheduler
    MatchSchedulerService().stopService();
    super.dispose();
  }

  final List<Map<String, dynamic>> _destinations = [
    {'label': 'Dashboard', 'icon': Icons.dashboard, 'route': '/admin/dashboard'},
    {'label': 'Matches', 'icon': Icons.sports_cricket, 'route': '/admin/matches'},
    {'label': 'Leagues', 'icon': Icons.emoji_flags, 'route': '/admin/leagues'}, // Added
    {'label': 'Contests', 'icon': Icons.emoji_events, 'route': '/admin/contests'},
    {'label': 'Users', 'icon': Icons.people, 'route': '/admin/users'},
    {'label': 'Wallet', 'icon': Icons.account_balance_wallet, 'route': '/admin/wallet'},
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    context.go(_destinations[index]['route']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Row(
        children: [
          // Sidebar (Navigation Rail)
          NavigationRail(
            backgroundColor: AppColors.secondaryBackground,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Image.asset('assets/images/logo_text.png', width: 40, errorBuilder: (c,e,s) => const Icon(Icons.shield, color: AppColors.accentGreen)),
            ),
            selectedIconTheme: const IconThemeData(color: AppColors.accentGreen),
            unselectedIconTheme: const IconThemeData(color: AppColors.textGrey),
            selectedLabelTextStyle: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.textGrey),
            destinations: _destinations.map((dest) {
              return NavigationRailDestination(
                icon: Icon(dest['icon']),
                label: Text(dest['label']),
              );
            }).toList(),
          ),
          
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.cardBorder),
          
          // Main Content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
