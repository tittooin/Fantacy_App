import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/wallet/data/wallet_repository.dart';
import 'package:axevora11/features/wallet/data/payment_repository.dart'; // Added
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final WalletRepository _walletRepo = WalletRepository();
  bool _isProcessing = false;

  Future<void> _initiateAddCash(String amountStr, dynamic user) async {
    final amount = double.tryParse(amountStr);
    if (amount == null || amount < 1) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Amount")));
       return;
    }

    setState(() => _isProcessing = true);
    Navigator.pop(context); // Close BottomSheet
    
    final orderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";

    // CALL CASHFREE REPOSITORY
    await ref.read(paymentRepositoryProvider).depositCash(
      amount: amount,
      orderId: orderId,
      onSuccess: (id) => _handleSuccess(amount), 
      onFailure: (msg) {
        if(mounted) {
           setState(() => _isProcessing = false);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: $msg"), backgroundColor: Colors.red));
        }
      }
    );
  }
  
  void _showWithdrawModal(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController upiController = TextEditingController();

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Withdraw Winnings", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Amount",
                labelStyle: TextStyle(color: Colors.white54),
                prefixText: "₹ ",
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: upiController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "UPI ID (e.g. 9876543210@upi)",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  final upi = upiController.text;
                  
                  if(amount < 100) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimum withdrawal is ₹100")));
                    return;
                  }
                  if(upi.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter Valid UPI ID")));
                    return;
                  }
                  
                  Navigator.pop(context);
                  setState(() => _isProcessing = true);
                  
                  try {
                    await ref.read(paymentRepositoryProvider).requestWithdrawal(amount: amount, upiId: upi);
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdrawal Requested! Processing..."), backgroundColor: Colors.green));
                  } catch (e) {
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  } finally {
                    if(mounted) setState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("REQUEST WITHDRAWAL", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      )
    );
  }

  Future<void> _handleSuccess(double amount) async {
    final user = ref.read(userEntityProvider).value;
    if (user != null) {
       // Dynamic access to avoid type issues
       final currentBalance = (user as dynamic).walletBalance as double;
       final uid = (user as dynamic).uid as String;
       
       final newBalance = currentBalance + amount;
       
       await FirebaseFirestore.instance.collection('users').doc(uid).update({
         'walletBalance': newBalance,
         'transactions': FieldValue.arrayUnion([{
            'type': 'DEPOSIT',
            'amount': amount,
            'timestamp': DateTime.now().toIso8601String(),
            'desc': 'Cash Added via Cashfree'
         }])
       });

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Success! Added ₹$amount to wallet.")));
       }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Colors.black], // Indigo to Black
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter
          )
        ),
        child: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text("User not found"));
            final dynamicUser = user as dynamic;

            return Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: kToolbarHeight + 20),
                    // 1. Total Balance Card
                    _buildTotalBalanceCard(context, dynamicUser.walletBalance),

                    // 2. Breakdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildBalanceItem("Deposited", dynamicUser.walletBalance - dynamicUser.winningBalance - dynamicUser.bonusBalance, Icons.account_balance_wallet)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildBalanceItem("Winnings", dynamicUser.winningBalance, Icons.emoji_events, isHighlight: true)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildBalanceItem("Bonus", dynamicUser.bonusBalance, Icons.card_giftcard)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "* Only 'Winnings' amount is withdrawable.",
                            style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // 3. Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                        if (!kIsWeb)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showAddCashModal(context, dynamicUser);
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text("ADD CASH"),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showWithdrawModal(context);
                                    },
                                    icon: const Icon(Icons.download),
                                    label: const Text("WITHDRAW"),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        side: const BorderSide(
                                            color: Colors.white54)),
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.amber.withOpacity(0.3))),
                              child: Column(
                                children: [
                                  const Icon(Icons.android,
                                      color: Colors.amber, size: 32),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Payments are available on Android App only.",
                                    style: TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () async {
                                      const url = "https://github.com/tittooin/Fantacy_App/releases/latest/download/app-release.apk";
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Could not launch download link")));
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black),
                                    child: const Text("DOWNLOAD ANDROID APP"),
                                  )
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    
                    // 4. Transactions List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: const Text("Recent Transactions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    _buildTransactionList(dynamicUser),
                  ],
                ),
                if (_isProcessing)
                   Container(
                     color: Colors.black54,
                     child: const Center(child: CircularProgressIndicator(color: Colors.green)),
                   )
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, double totalBalance) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF283593), // Darker Indigo
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
        gradient: const LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF283593)])
      ),
      child: Column(
        children: [
          const Text("TOTAL BALANCE", style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 8),
          Text("₹${totalBalance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isHighlight ? Border.all(color: Colors.amber.withOpacity(0.5)) : null
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: isHighlight ? Colors.amber : Colors.white70),
          const SizedBox(height: 8),
          Text("₹${amount.toStringAsFixed(0)}", style: TextStyle(color: isHighlight ? Colors.amber : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  void _showAddCashModal(BuildContext context, dynamic user) {
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Cash", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 24),
                decoration: const InputDecoration(
                  prefixText: "₹ ",
                  prefixStyle: TextStyle(color: Colors.white, fontSize: 24),
                  hintText: "Enter Amount",
                  hintStyle: TextStyle(color: Colors.white30),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Quick Add", style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _quickAddChip(amountController, "100"),
                  _quickAddChip(amountController, "500"),
                  _quickAddChip(amountController, "1000"),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                     _initiateAddCash(amountController.text, user);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("PROCEED TO PAY")
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  Widget _buildTransactionList(dynamic user) {
     final List transactions = (user.transactions as List?) ?? [];
     if (transactions.isEmpty) {
       return const Padding(
         padding: EdgeInsets.all(32.0),
         child: Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.white54))),
       );
     }
     
     // Show last 10
     final reversed = transactions.reversed.take(10).toList();

     return ListView.builder(
       shrinkWrap: true,
       physics: const NeverScrollableScrollPhysics(),
       padding: EdgeInsets.zero,
       itemCount: reversed.length,
       itemBuilder: (context, index) {
         final txn = reversed[index] as Map<String, dynamic>;
         final isCredit = txn['type'] == 'DEPOSIT' || txn['type'] == 'WINNINGS';
         final amount = txn['amount'] ?? 0;
         final date = DateTime.tryParse(txn['timestamp'] ?? '') ?? DateTime.now();
         
         return ListTile(
           leading: CircleAvatar(
             backgroundColor: isCredit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
             child: Icon(
               isCredit ? Icons.arrow_downward : Icons.arrow_upward, 
               color: isCredit ? Colors.green : Colors.red, size: 16
             ),
           ),
           title: Text(txn['desc'] ?? 'Transaction', style: const TextStyle(color: Colors.white, fontSize: 14)),
           subtitle: Text("${date.day}/${date.month} ${date.hour}:${date.minute}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
           trailing: Text(
             "${isCredit ? '+' : '-'} ₹$amount",
             style: TextStyle(color: isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
           ),
         );
       },
     );
  }

  Widget _quickAddChip(TextEditingController controller, String amount) {
    return ActionChip(
      label: Text("₹$amount"),
      backgroundColor: Colors.white10,
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () {
        controller.text = amount;
      },
      side: BorderSide.none,
    );
  }
}
