import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/wallet/data/wallet_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:axevora11/features/wallet/presentation/providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("DEBUG Wallet: App Resumed, Refreshing Balance...");
      ref.read(walletBalanceProvider.notifier).refresh();
    }
  }

  Future<void> _initiateAddCash(String amountStr, dynamic user) async {
    final amount = double.tryParse(amountStr);
    if (amount == null || amount < 1) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Amount")));
       return;
    }

    setState(() => _isProcessing = true);
    Navigator.pop(context); // Close BottomSheet
    
    final userId = (user as dynamic).uid;
    if (userId == null) return;

    // CALL BACKEND WORKER
    final result = await ref.read(walletRepositoryProvider).createDepositOrder(userId, amount);
    
    if (result['success'] == true && result['paymentLink'] != null) {
        final url = result['paymentLink'];
        if (await canLaunchUrl(Uri.parse(url))) {
           await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Payment Page Opened. Balance will update automatically."), backgroundColor: Colors.blue)
             );
           }
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch payment link"), backgroundColor: Colors.red));
        }
    } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${result['error']}"), backgroundColor: Colors.red));
    }
    
    if (mounted) setState(() => _isProcessing = false);
  }
  
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);
    final walletBalance = ref.watch(walletBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              ref.read(walletBalanceProvider.notifier).refresh();
            }
          )
        ],
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
            
            // Use Live D1 Balance from Provider
            final double displayBalance = walletBalance; 

            return Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: kToolbarHeight + 20),
                    // 1. Total Balance Card
                    _buildTotalBalanceCard(context, displayBalance),

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
                                label: const Text("BUY CREDITS"),
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
                                  // DIRECT NAVIGATION TO REDEEM SCREEN - BYPASS OLD KYC
                                  context.push('/redeem');
                                },
                                icon: const Icon(Icons.redeem),
                                label: const Text("REDEEM"),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    side: const BorderSide(
                                        color: Colors.white54)),
                              ),
                            ),
                          ],
                        ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    
                    // 4. Transactions List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: const Text("Recent Transactions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: _buildLiveTransactionList(dynamicUser.uid)),
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
          const Text("TOTAL CREDITS (Live)", style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 8),
          Text("${totalBalance.toStringAsFixed(0)}", style: const TextStyle(color: Colors.amber, fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("1 Rs = 1 Credit", style: TextStyle(color: Colors.white30, fontSize: 10)),
        ],
      ),
    );
  }

  void _showAddCashModal(BuildContext context, dynamic user) {
    final TextEditingController amountController = TextEditingController();
    bool isChecked = false; // Self-declaration state

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder( // Use StatefulBuilder to update Checkbox
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Buy Credits", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // Amount Input
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
                
                // Quick Add Chips
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
                const SizedBox(height: 24),

                // COMPLIANCE CHECKBOX - CRITICAL FOR AVOIDING BANS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.white70),
                    child: CheckboxListTile(
                      value: isChecked,
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        "I certify that I am 18+ years old and NOT a resident of Assam, Odisha, Telangana, Nagaland, Sikkim, or Andhra Pradesh.",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text("Playing from banned states is illegal.", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                      ),
                      onChanged: (val) {
                        setModalState(() => isChecked = val ?? false);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                // Pay Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isChecked 
                      ? () => _initiateAddCash(amountController.text, user)
                      : null, // Disabled until checked
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isChecked ? Colors.green : Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("PAY & GET CREDITS")
                  ),
                )
              ],
            ),
          ),
        ),
      )
    );
  }

  // Optimized Transaction List (Future instead of Stream)
  Widget _buildLiveTransactionList(String userId) {
      return FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(walletRepositoryProvider).getTransactions(userId),
          builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Error loading transactions", style: TextStyle(color: Colors.white54)),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        onPressed: () {
                          setState(() {}); // Retry
                        },
                      )
                    ],
                  )
                );
              }
              
              final docs = snapshot.data ?? [];
              if (docs.isEmpty) return const Center(child: Text("No transactions yet", style: TextStyle(color: Colors.white54)));

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // Toggling state triggers FutureBuilder re-fetch
                },
                child: ListView.builder(
                    itemCount: docs.length,
                    padding: EdgeInsets.zero,
                    // RefreshIndicator needs scrollable even if list is short
                    physics: const AlwaysScrollableScrollPhysics(), 
                    itemBuilder: (context, index) {
                        final data = docs[index];
                        final type = data['type'] ?? 'unknown';
                        final amount = data['amount'] ?? 0;
                        final isCredit = type == 'deposit' || type == 'winnings'; 
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCredit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            child: Icon(
                              isCredit ? Icons.arrow_downward : Icons.arrow_upward, 
                              color: isCredit ? Colors.green : Colors.red, size: 16
                            ),
                          ),
                          title: Text(type.toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(data['status']?.toString().toUpperCase() ?? 'PENDING', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          trailing: Text(
                            "${isCredit ? '+' : '-'} ${amount.toString()}",
                            style: TextStyle(color: isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        );
                    }
                ),
              );
          }
      );
  }

  Widget _quickAddChip(TextEditingController controller, String amount) {
    return ActionChip(
      label: Text("₹$amount"),
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      onPressed: () {
        controller.text = amount;
      },
      side: BorderSide.none,
    );
  }
}
