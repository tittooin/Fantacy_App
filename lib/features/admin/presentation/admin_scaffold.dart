import 'package:axevora11/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


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
  }

  @override
  void dispose() {
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
    // ONE SCAFFOLD RULE: This is the only Scaffold in the admin panel.
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme base
      body: Row(
        children: [
          // Sidebar (Fixed 250px)
          Container(
            width: 250,
            color: const Color(0xFF1E1E1E), // Slightly lighter dark
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.blueAccent, size: 32),
                      const SizedBox(width: 12),
                      const Text("AXEVORA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _destinations.length,
                    itemBuilder: (context, index) {
                      final item = _destinations[index];
                      final isSelected = _selectedIndex == index;
                      return ListTile(
                        leading: Icon(item['icon'], color: isSelected ? Colors.blueAccent : Colors.white54),
                        title: Text(item['label'], style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white70)),
                        selected: isSelected,
                        selectedTileColor: Colors.blueAccent.withOpacity(0.1),
                        onTap: () => _onDestinationSelected(index),
                      );
                    },
                  ),
                ),
                
                // Footer
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("v1.0.3 Admin", style: TextStyle(color: Colors.white24, fontSize: 10)),
                ),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.black, // Content background
              child: widget.child
            ),
          ),
        ],
      ),
    );
  }
}
