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

class _AdminWalletScreenState extends ConsumerState<AdminWalletScreen> {
  bool _isLoading = false;

  // STRICT: Only handle withdrawals. No credits.
  // Payout mechanism should ideally call a Cloud Function or Backend API.
  // For now, we simulate the approval which would trigger the payout logic.

  Future<void> _processWithdrawal(String txnId, String userId, double amount, bool approve, {String? reason}) async {
    setState(() => _isLoading = true);
    
    try {
      final action = approve ? 'APPROVE_WITHDRAWAL' : 'REJECT_WITHDRAWAL';
      
      // 1. Audit Log (Crucial)
      await auditProvider.logAction(
        action: action, 
        matchId: 'WALLET_OPS', 
        details: {'userId': userId, 'amount': amount, 'txnId': txnId, 'reason': reason ?? ''}
      );

      // 2. Update Transaction Status in Firestore
      // Note: In a real Cashfree setup, APPROVE would call Payout API.
      // Here we update status, and a Cloud Function would listen to 'APPROVED' to trigger payout.
      
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'transactions': FieldValue.arrayRemove([
           // We'd need the exact object to remove, or better, we manage a separate 'withdrawals' collection.
           // Assuming 'withdrawals' collection for admin safety as per strict rules.
        ])
      });
      
      // Simulating update on a dedicated 'withdrawals' collection which is safer availabilitywise
      // But given existing structure, let's assume we update a 'withdrawal_requests' collection
      await FirebaseFirestore.instance.collection('withdrawal_requests').doc(txnId).update({
        'status': approve ? 'APPROVED' : 'REJECTED',
        'processedAt': DateTime.now().toIso8601String(),
        'adminNote': reason ?? (approve ? 'Processed via Admin' : 'Rejected'),
      });

      if (!approve) {
        // If rejected, Refund the amount to user wallet
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'winningBalance': FieldValue.increment(amount), // Refund to winnings? Or deposit? usually winnings.
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Withdrawal ${approve ? 'Approved' : 'Rejected'}")));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet & Payouts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('withdrawal_requests')
            .where('status', isEqualTo: 'PENDING') // Only show pending
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No Pending Withdrawals"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final txnId = docs[index].id;
              final amount = (data['amount'] ?? 0).toDouble();
              final userId = data['userId'] ?? '';
              final method = data['method'] ?? 'Bank'; // UPI/Bank

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text("₹ $amount", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                           Chip(label: Text(method), backgroundColor: Colors.blue.shade50)
                         ],
                       ),
                       const SizedBox(height: 8),
                       Text("User ID: $userId", style: const TextStyle(color: Colors.grey)),
                       Text("Requested: ${data['timestamp'] ?? 'Unknown'}", style: const TextStyle(fontSize: 12)),
                       
                       const Divider(height: 24),
                       
                       Row(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                           OutlinedButton(
                             onPressed: _isLoading ? null : () => _showRejectDialog(context, txnId, userId, amount),
                             style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                             child: const Text("Reject"),
                           ),
                           const SizedBox(width: 12),
                           ElevatedButton(
                             onPressed: _isLoading ? null : () => _processWithdrawal(txnId, userId, amount, true),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                             child: const Text("Approve & Pay"),
                           ),
                         ],
                       )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String txnId, String userId, double amount) {
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
            labelText: "Reason for Rejection",
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processWithdrawal(txnId, userId, amount, false, reason: reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirm Reject"),
          )
        ],
      )
    );
  }
}
