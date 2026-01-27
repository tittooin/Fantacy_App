import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/admin/data/audit_service.dart';
import 'package:intl/intl.dart';

class AdminWalletScreen extends ConsumerStatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  ConsumerState<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

import 'package:axevora11/features/wallet/data/wallet_repository.dart';

class _AdminWalletScreenState extends ConsumerState<AdminWalletScreen> {
  bool _isLoading = false;

  Future<void> _approveWrapper(String docId, String userId) async {
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Approve & Pay", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter Transaction ID / Voucher Code:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                hintText: "e.g. UPI-1234567890",
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
               if (noteController.text.isEmpty) return;
               Navigator.pop(ctx);
               _executeAction(docId, userId, true, note: noteController.text);
            }, 
            child: const Text("Confirm Payment")
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
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? "Approved & Paid" : "Rejected & Refunded")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Withdrawal Requests", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.read(walletRepositoryProvider).getPendingWithdrawals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No Pending Requests", style: TextStyle(color: Colors.white54)));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              
              final amount = (data['amount'] ?? 0).toDouble();
              final userId = data['userId'] ?? '';
              final method = data['method'] ?? 'Unknown';
              final details = data['details'] ?? 'No details';
              final date = data['requestDate'] != null 
                  ? DateFormat('dd MMM, hh:mm a').format((data['requestDate'] as Timestamp).toDate()) 
                  : 'Just now';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(method.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                         Text("₹ $amount", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Text("To: $details", style: const TextStyle(color: Colors.white, fontSize: 16)),
                     Text("User ID: $userId", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                     const SizedBox(height: 4),
                     Text("Date: $date", style: const TextStyle(color: Colors.white30, fontSize: 12)),
                     
                     const Divider(color: Colors.white10, height: 24),
                     
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         TextButton(
                           onPressed: _isLoading ? null : () => _showRejectDialog(context, docId, userId, amount),
                           style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                           child: const Text("REJECT"),
                         ),
                         const SizedBox(width: 12),
                         ElevatedButton.icon(
                           onPressed: _isLoading ? null : () => _approveWrapper(docId, userId),
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                           icon: const Icon(Icons.check, size: 16),
                           label: const Text("PAY NOW"),
                         ),
                       ],
                     )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String docId, String userId, double amount) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Reject Withdrawal", style: TextStyle(color: Colors.white)),
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
            child: const Text("Confirm Reject"),
          )
        ],
      )
    );
  }
}
