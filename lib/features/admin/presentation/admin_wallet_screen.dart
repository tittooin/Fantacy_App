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
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text("Payout Requests", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                     SizedBox(height: 4),
                     Text("Manage withdrawals & rewards.", style: TextStyle(color: Colors.white54)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showIssueCreditDialog(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text("Issue Reward Credit"),
                )
              ],
            ),
            
            const SizedBox(height: 24),

            // Header Container
             Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text("USER ID", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("AMOUNT", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text("DETAILS", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text("ACTIONS", textAlign: TextAlign.end, style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
                stream: ref.read(walletRepositoryProvider).getPendingWithdrawals(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                  if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No Pending Payouts", style: TextStyle(color: Colors.white54))));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                            Expanded(flex: 2, child: SelectableText(userId, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace'))),
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
          ],
        ),
      ),
    );
  }

  // --- ISSUE REWARD CREDIT DIALOG ---
  void _showIssueCreditDialog(BuildContext context) {
    final emailController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool searching = false;
    String? foundUserId;
    String? foundUserName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2C3E50),
            title: const Text("Issue Reward Credit 🎁", style: TextStyle(color: Colors.amber)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text("Credits are non-withdrawable.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                   const SizedBox(height: 16),
                   TextField(
                     controller: emailController,
                     style: const TextStyle(color: Colors.white),
                     decoration: InputDecoration(
                       labelText: "User Email",
                       labelStyle: const TextStyle(color: Colors.white70),
                       fillColor: Colors.black26, filled: true,
                       suffixIcon: IconButton(
                         icon: searching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search, color: Colors.amber),
                         onPressed: () async {
                           if(emailController.text.isEmpty) return;
                           setState(() => searching = true);
                           // Simple Search Logic
                           try {
                             final snap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: emailController.text.trim()).limit(1).get();
                             if(snap.docs.isNotEmpty) {
                               foundUserId = snap.docs.first.id;
                               foundUserName = snap.docs.first.data()['name'] ?? "User";
                             } else {
                               foundUserId = null;
                             }
                           } catch(e) {
                             debugPrint("Search Error: $e");
                           }
                           if(mounted) setState(() => searching = false);
                         },
                       )
                     ),
                   ),
                   if (foundUserId != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Found: $foundUserName ($foundUserId)", style: const TextStyle(color: Colors.greenAccent)),
                      ),
                   if (!searching && foundUserId == null && emailController.text.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("User not found", style: TextStyle(color: Colors.redAccent)),
                      ),

                   const SizedBox(height: 12),
                   TextField(
                     controller: amountController,
                     keyboardType: TextInputType.number,
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(labelText: "Amount (₹)", filled: true, fillColor: Colors.black26, labelStyle: TextStyle(color: Colors.white70)),
                   ),
                   const SizedBox(height: 12),
                   TextField(
                     controller: noteController,
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(labelText: "Reason / Note", filled: true, fillColor: Colors.black26, labelStyle: TextStyle(color: Colors.white70)),
                   ),
                ],
              ),
            ),
            actions: [
               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
               ElevatedButton(
                 onPressed: (foundUserId == null || _isLoading) ? null : () async {
                    Navigator.pop(ctx);
                    await _processRewardCredit(foundUserId!, double.tryParse(amountController.text) ?? 0, noteController.text);
                 },
                 child: const Text("Issue Credit")
               )
            ],
          );
        }
      )
    );
  }

  Future<void> _processRewardCredit(String userId, double amount, String note) async {
    if (amount <= 0) return;
    setState(() => _isLoading = true);
    try {
      // 1. Add Transaction
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('transactions').add({
        'amount': amount,
        'type': 'reward_credit', // SPECIAL TYPE
        'description': note.isEmpty ? "Admin Reward" : note,
        'timestamp': FieldValue.serverTimestamp(),
        'isCredit': true,
        'status': 'success',
        'isWithdrawable': false, // NON-WITHDRAWABLE
      });

      // 2. Update Wallet (Total Balance)
      // Note: We might want to track 'bonus' separatedly in future, but for now it adds to balance.
      // But Payout Logic must filter it? 
      // Current system: User sees Total Balance. Payout Logic checks 'deposit' + 'winnings'.
      // 'reward_credit' is logically 'winnings' or 'bonus'.
      // Let's treat it as 'bonus' usage.
      
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
        'bonusBalance': FieldValue.increment(amount), // Assuming bonusBalance field exists or we create it
      });
      
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reward Credit Issued Successfully!"), backgroundColor: Colors.green));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false); 
    }
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
            const Text("Enter Transaction Ref:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(filled: true, fillColor: Colors.black26, hintText: "Ref ID"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
               Navigator.pop(ctx);
               _executeAction(docId, userId, true, note: noteController.text);
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
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? "Paid" : "Rejected")));
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
          decoration: const InputDecoration(labelText: "Reason", filled: true, fillColor: Colors.black26),
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
