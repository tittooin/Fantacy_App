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
    {'label': 'Dashboard', 'icon': Icons.dashboard_rounded, 'route': '/admin/dashboard'},
    {'label': 'Matches', 'icon': Icons.sports_cricket_rounded, 'route': '/admin/matches'},
    {'label': 'Contests', 'icon': Icons.emoji_events_rounded, 'route': '/admin/contests'},
    {'label': 'Users', 'icon': Icons.people_alt_rounded, 'route': '/admin/users'},
    {'label': 'Payouts', 'icon': Icons.payments_rounded, 'route': '/admin/wallet'},
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
      backgroundColor: const Color(0xFF0A1929), // Dark Navy Background (User Request)
      body: Row(
        children: [
          // Sidebar (Fixed 250px)
          Container(
            width: 250,
            color: const Color(0xFF0D2235), // Slightly lighter Dark Navy
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.lightBlueAccent, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Text("AXEVORA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
                    ],
                  ),
                ),
                Divider(color: Colors.lightBlueAccent.withOpacity(0.1)),
                
                // Navigation Items
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _destinations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _destinations[index];
                      final isSelected = _selectedIndex == index;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListTile(
                          leading: Icon(item['icon'], color: isSelected ? Colors.lightBlueAccent : Colors.grey[400], size: 20),
                          title: Text(item['label'], style: TextStyle(color: isSelected ? Colors.lightBlueAccent : Colors.grey[400], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          tileColor: isSelected ? Colors.lightBlueAccent.withOpacity(0.1) : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onTap: () => _onDestinationSelected(index),
                        ),
                      );
                    },
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 12, backgroundColor: Colors.green, child: Icon(Icons.check, size: 12, color: Colors.white)),
                      const SizedBox(width: 12),
                      Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text("System Online", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                           Text("v1.0.4 • Stable", style: TextStyle(color: Colors.grey[500], fontSize: 10))
                         ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: Container(
              color: const Color(0xFF0A1929), // Content background matches base
              child: widget.child
            ),
          ),
        ],
      ),
    );
  }
}
