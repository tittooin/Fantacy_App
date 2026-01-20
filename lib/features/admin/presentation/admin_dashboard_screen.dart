import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Axevora11 Admin",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const Text("Real-time Platform Stats", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                   _buildDynamicStatCard(
                     context, 
                     "Total Users", 
                     FirebaseFirestore.instance.collection('users').snapshots(),
                     Icons.people_alt_rounded,
                     const Color(0xFF4FC3F7),
                   ),
                   _buildDynamicStatCard(
                     context, 
                     "Active Matches", 
                     FirebaseFirestore.instance.collection('matches').where('status', isNotEqualTo: 'Completed').snapshots(),
                     Icons.sports_cricket_rounded,
                     const Color(0xFF00E5FF),
                   ),
                   _buildStatCard(
                     context, 
                     "Match Controls", 
                     "MANAGE", 
                     Icons.settings_suggest_rounded, 
                     color: Colors.orangeAccent,
                     onTap: () => context.push('/admin/match-control'),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicStatCard(BuildContext context, String title, Stream<QuerySnapshot> stream, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : "...";
        return _buildStatCard(context, title, count.toString(), icon, color: color);
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, {Color color = const Color(0xFF00E5FF), VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1E3C), // Deep Navy
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 20),
              FittedBox(
                child: Text(
                  value, 
                  style: const TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title.toUpperCase(), 
                style: const TextStyle(
                  color: Colors.white38, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
