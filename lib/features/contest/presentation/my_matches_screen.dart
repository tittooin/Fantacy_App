import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/features/contest/presentation/providers/user_contest_provider.dart';

import 'package:axevora11/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class MyMatchesScreen extends ConsumerWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedContests = ref.watch(userContestProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "My Joined Lounges",
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: joinedContests.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 80, color: AppColors.skyBlue.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  "No active lounges found.",
                  style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text("Explore Live Matches", style: TextStyle(color: AppColors.skyBlue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: joinedContests.length,
            itemBuilder: (context, index) {
              final lounge = joinedContests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.glassWhite),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListTile(
                  onTap: () => context.push('/match/${lounge.matchId}'),
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.groups_rounded, color: AppColors.skyBlue),
                  ),
                  title: Text(
                    lounge.contestName.replaceAll("Contest", "Lounge"), 
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "Member Role • Participant", 
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "LIVE",
                              style: GoogleFonts.inter(
                                fontSize: 9, 
                                fontWeight: FontWeight.bold, 
                                color: AppColors.successGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Join Discussion", 
                            style: GoogleFonts.inter(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: AppColors.skyBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textLight),
                ),
              );
            },
          ),
    );
  }
}
