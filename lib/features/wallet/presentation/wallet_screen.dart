import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/wallet/data/wallet_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:axevora11/features/user/domain/user_entity.dart'; // Dynamic for now to avoid issues

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

    // 1. Web Mock Flow (Always on for now)
    debugPrint("Web Mode: Simulating Payment...");
    await Future.delayed(const Duration(seconds: 2));
    _handleSuccess(amount);
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
            'desc': 'Cash Added'
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
                      child: Row(
                        children: [
                          Expanded(child: _buildBalanceItem("Deposited", dynamicUser.walletBalance - dynamicUser.winningBalance - dynamicUser.bonusBalance, Icons.account_balance_wallet)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildBalanceItem("Winnings", dynamicUser.winningBalance, Icons.emoji_events, isHighlight: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildBalanceItem("Bonus", dynamicUser.bonusBalance, Icons.card_giftcard)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // 3. Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdraw coming soon!")));
                              },
                              icon: const Icon(Icons.download),
                              label: const Text("WITHDRAW"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.white54)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    
                    // 4. Transactions Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Recent Transactions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(onPressed: (){}, child: const Text("View All"))
                        ],
                      ),
                    ),
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
