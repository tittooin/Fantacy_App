import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:intl/intl.dart';
import 'package:axevora11/core/widgets/loading_skeleton.dart';

import 'package:axevora11/features/user/presentation/providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userEntityProvider);
    final walletBalance = userAsync.value?.walletBalance ?? 0.0;

    final mobileContent = Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=33"),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome Back,", style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text(userAsync.value?.displayName ?? "User", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push('/wallet'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text("₹ ${walletBalance.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          )
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Banner / Carousel Placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(Icons.sports_cricket, size: 150, color: Colors.white.withOpacity(0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                          child: const Text("MEGA CONTEST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        const Text("IPL 2026 is Here!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text("Join the biggest fantasy league now.", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // TABS
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.indigo,
                tabs: [
                  Tab(text: "Upcoming"),
                  Tab(text: "Completed"),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildMatchList(showCompleted: false),
                  _buildMatchList(showCompleted: true),
                ],
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: Removed (Handled by ShellRoute)
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          // Desktop / Tablet View
          return Scaffold(
            backgroundColor: Colors.grey.shade900,
            body: Center(
              child: Container(
                width: 450,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                   boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ]
                ),
                child: mobileContent,
              ),
            ),
          );
        }
        // Mobile View
        return mobileContent;
      },
    );
  }

  Widget _buildMatchList({required bool showCompleted}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const MatchCardSkeleton(),
            );
        }

        final docs = snapshot.data?.docs ?? [];
        // FILTER LOGIC
        final matches = docs.map((d) {
           try {
             return CricketMatchModel.fromMap(d.data() as Map<String, dynamic>);
           } catch (e) {
             return null;
           }
        }).where((m) => m != null).where((m) {
           if (showCompleted) {
             return m!.status == 'Completed';
           } else {
             return m!.status == 'Upcoming' || m.status == 'Live';
           }
        }).toList();
        
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_cricket_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(showCompleted ? "No Completed Matches" : "No Upcoming Matches", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
             return MatchCard(match: matches[index]!);
          },
        );
      },
    );
  }

class MatchCard extends StatelessWidget {
  final CricketMatchModel match;
  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/match/${match.id}', extra: match),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header: Series Name & Live Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match.seriesName,
                        style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (match.status == 'Live')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.white),
                            SizedBox(width: 4),
                            Text("LIVE", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else if (match.status == 'Completed')
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 10, color: Colors.white70),
                            SizedBox(width: 4),
                            Text("COMPLETED", style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                            SizedBox(width: 4),
                            Text("Lineups Out", style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 16),
                
                // Content: Team 1 vs Team 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTeam(match.team1ShortName, match.team1Img, true),
                    
                    Column(
                      children: [
                        const Text("VS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 4),
                        if (match.status == 'Upcoming')
                           Text(
                            _formatDate(match.startDate), 
                            style: const TextStyle(fontSize: 10, color: Colors.orangeAccent, fontWeight: FontWeight.bold)
                          ),
                         if (match.status == 'Live')
                           const Text("In Progress", style: TextStyle(color: Colors.white60, fontSize: 10)),
                         if (match.status == 'Completed')
                            const Text("Winner Declared", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold))

                      ],
                    ),

                    _buildTeam(match.team2ShortName, match.team2Img, false),
                  ],
                ),
                
                const Padding(
                   padding: EdgeInsets.symmetric(vertical: 12),
                   child: Divider(color: Colors.white10),
                ),

                // Footer: Mega Contest Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                         const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                         const SizedBox(width: 6),
                         Text("MEGA ₹1 Crore", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade200, fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                         const Icon(Icons.av_timer, size: 14, color: Colors.white54),
                         const SizedBox(width: 4),
                         Text("Quick Join", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    // Basic formatting for NOW (Replace with intl later if needed)
    return "Starts soon"; 
  }

  Widget _buildTeam(String name, String img, bool isLeft) {
    // Layout: Left Team [Img Name], Right Team [Name Img]
    final children = [
      Container(
        decoration: BoxDecoration(
           shape: BoxShape.circle,
           border: Border.all(color: Colors.white24, width: 2),
           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
        ),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withOpacity(0.1),
          backgroundImage: (img.isNotEmpty) ? NetworkImage(img) : null,
          child: (img.isEmpty) ? const Icon(Icons.sports_cricket, color: Colors.white70) : null,
        ),
      ),
      const SizedBox(width: 12),
      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
    ];

    return Row(
      children: isLeft ? children : children.reversed.toList(),
    );
  }
}
