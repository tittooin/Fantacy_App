import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/admin/data/audit_service.dart';
import 'package:intl/intl.dart';
import 'package:axevora11/features/wallet/data/wallet_repository.dart';

class AdminWalletScreen extends ConsumerStatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  ConsumerState<AdminWalletScreen> createState() => _AdminWalletScreenState();
}



class _AdminWalletScreenState extends ConsumerState<AdminWalletScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Payout Requests", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Approve or Reject withdrawal requests.", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),

            // Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text("USER ID", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("AMOUNT", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text("DETAILS", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text("ACTIONS", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, textAlign: TextAlign.end))),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ref.read(walletRepositoryProvider).getPendingWithdrawals(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text("No Pending Payouts", style: TextStyle(color: Colors.white54)));

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final amount = (data['amount'] ?? 0).toDouble();
                      final userId = data['userId'] ?? 'Unknown';
                      final method = data['method'] ?? 'Unknown';
                      final details = data['details'] ?? '--';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2A38),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10)
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(userId, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace'))),
                            Expanded(flex: 2, child: Text("₹ $amount", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(method.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(details, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            )),
                            Expanded(flex: 3, child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent),
                                  tooltip: "Reject",
                                  onPressed: _isLoading ? null : () => _showRejectDialog(context, docId, userId, amount),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : () => _approveWrapper(docId, userId),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text("Approve"),
                                )
                              ],
                            )),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveWrapper(String docId, String userId) async {
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text("Approve Payout", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter Transaction Ref / Voucher Code:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                hintText: "Ref ID (Optional)",
                hintStyle: TextStyle(color: Colors.white24),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
               Navigator.pop(ctx);
               _executeAction(docId, userId, true, note: noteController.text.isEmpty ? "Approved" : noteController.text);
            }, 
            child: const Text("Mark as Paid")
          )
        ],
      )
    );
  }

  Future<void> _executeAction(String docId, String userId, bool approve, {String? note, double? refreshAmount}) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      
      if (approve) {
        await repo.approveWithdrawal(docId, userId, note ?? 'Approved');
      } else {
        await repo.rejectWithdrawal(docId, userId, refreshAmount ?? 0.0, note ?? 'Rejected');
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? "Processed: Paid" : "Processed: Rejected")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(BuildContext context, String docId, String userId, double amount) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text("Reject Payout", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Reason",
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.black26,
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeAction(docId, userId, false, note: reasonController.text, refreshAmount: amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject & Refund"),
          )
        ],
      )
    );
  }
}
