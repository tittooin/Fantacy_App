import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyMatchesScreen extends ConsumerWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedContests = ref.watch(userContestProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Joined Matches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: joinedContests.isEmpty 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text("No joined contests found in D1.", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: joinedContests.length,
            itemBuilder: (context, index) {
              final contest = joinedContests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => context.push('/contest/${contest.contestId}', extra: {
                    'contestId': contest.contestId,
                    'matchId': contest.matchId,
                  }),
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(contest.contestName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Team: ${contest.teamName}", style: const TextStyle(fontSize: 13)),
                      Text("Entry: ${contest.entryFee.toStringAsFixed(0)} Coins", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
    );
  }
}
