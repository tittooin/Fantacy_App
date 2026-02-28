import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/data/providers/leaderboard_provider.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_contest_model.dart';

class AdminPayoutLeaderboardScreen extends ConsumerStatefulWidget {
  final String contestId;
  final String matchId;
  final CricketRoomModel? contest;

  const AdminPayoutLeaderboardScreen({
    super.key, 
    required this.contestId, 
    required this.matchId,
    this.contest,
  });

  @override
  ConsumerState<AdminPayoutLeaderboardScreen> createState() => _AdminPayoutLeaderboardScreenState();
}

class _AdminPayoutLeaderboardScreenState extends ConsumerState<AdminPayoutLeaderboardScreen> {
  bool _isProcessing = false;

  Future<void> _handlePayout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Final Payout"),
        content: const Text("Are you sure you want to distribute prizes based on THESE rankings?\n\nThis will credit user wallets and cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("EXECUTE PAYOUT")
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        // We trigger the payout for the specific match. 
        // Note: Currently distributePrizes is per-match, matching user requirement.
        final result = await ref.read(rapidApiServiceProvider).distributePrizes(widget.matchId);
        
        if (mounted) {
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Payout Successful! Wallets updated."), backgroundColor: Colors.green)
            );
            Navigator.pop(context); // Go back after success
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("❌ Failed: ${result['error']}"), backgroundColor: Colors.red)
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red)
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(widget.contestId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payout Review"),
        backgroundColor: Colors.orange[800],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Review rankings below. Prizes will be distributed according to the Winning Breakdown defined for this contest.",
                    style: TextStyle(color: Colors.orange[900], fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: leaderboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(child: Text("No entries found for this contest."));
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final data = entries[index];
                    final rank = data['rank'] ?? (index + 1);
                    final name = data['displayName'] ?? data['teamName'] ?? 'User';
                    final points = (data['points'] ?? 0).toDouble();

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text("#$rank"),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: ${data['userId']?.toString().substring(0, 8)}..."),
                      trailing: Text(
                        "${points.toStringAsFixed(1)} pts",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _handlePayout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("DISTRIBUTE PRIZES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
