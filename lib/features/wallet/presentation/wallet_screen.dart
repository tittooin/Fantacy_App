import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/wallet/data/wallet_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isProcessing = false;

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
  
<<<<<<< HEAD
  void _showWithdrawModal(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdrawal via Voucher coming soon!")));
=======
  void _showWithdrawModal(BuildContext context, dynamic user) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    String selectedMethod = 'UPI';
    final List<String> methods = ['UPI', 'Bank Transfer', 'Amazon Pay Gift Card', 'Flipkart Gift Card', 'Google Play Code'];

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Withdraw Funds", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Manual Payout (Processed within 24 Hours)", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 20),
                
                // Amount Field
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Amount (Min ₹100)",
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixText: "₹ ",
                    prefixStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Method Dropdown
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Payout Method",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                  items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setModalState(() => selectedMethod = val!),
                ),
                const SizedBox(height: 16),

                // Details Field
                TextField(
                  controller: detailsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: selectedMethod == 'UPI' ? "Enter UPI ID" : 
                               selectedMethod == 'Bank Transfer' ? "Acc No, IFSC, Name" : "Enter Email Address for Voucher",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                    hintText: selectedMethod == 'UPI' ? "e.g. 9876543210@upi" : "e.g. user@gmail.com",
                    hintStyle: const TextStyle(color: Colors.white30),
                  ),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                       final double? amount = double.tryParse(amountController.text);
                       if (amount == null || amount < 100) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Min withdrawal is ₹100")));
                         return;
                       }
                       if (detailsController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter details")));
                          return;
                       }

                       Navigator.pop(context);
                       
                       try {
                         // Call Repository
                         await ref.read(walletRepositoryProvider).requestWithdrawal(
                           userId: user.uid,
                           amount: amount,
                           method: selectedMethod,
                           details: detailsController.text,
                           currentBalance: (user.walletBalance as num).toDouble(),
                         );
                         
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdrawal Request Submitted!"), backgroundColor: Colors.green));
                       } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
                       }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("REQUEST WITHDRAWAL")
                  ),
                )
              ],
            ),
          ),
        ),
      )
    );
>>>>>>> dev-update
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the User Stream here. If Webhook updates DB, this Stream should trigger rebuild.
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
            
            // Safe Access to Fields
            final double balance = (dynamicUser.walletBalance is num) ? (dynamicUser.walletBalance as num).toDouble() : 0.0;
            // Unused variables removed for build stability

            return Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: kToolbarHeight + 20),
                    // 1. Total Balance Card
                    _buildTotalBalanceCard(context, balance),

                    // 2. Breakdown (Optional, if we have these fields)
                    /*
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                         children: [
                            Expanded(child: _buildBalanceItem("Coins", balance, Icons.monetization_on, isHighlight: true)),
                         ],
                      ),
                    ),
                    */

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
                                label: const Text("ADD COINS"),
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
<<<<<<< HEAD
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showWithdrawModal(context);
=======
                                child: OutlinedButton.icon(
                                onPressed: () {
                                  // KYC CHECK
                                  String kycStatus = 'unverified';
                                  try { kycStatus = dynamicUser.kycStatus ?? 'unverified'; } catch (_) {}
                                  
                                  if (kycStatus == 'verified') {
                                     _showWithdrawModal(context, dynamicUser);
                                  } else {
                                     showDialog(
                                       context: context, 
                                       builder: (ctx) => AlertDialog(
                                         backgroundColor: Colors.grey[900],
                                         title: Text(kycStatus == 'pending' ? "Verification Pending" : "Identity Verification Required", style: const TextStyle(color: Colors.white)),
                                         content: Text(
                                           kycStatus == 'pending' 
                                            ? "Your KYC documents are under review. You can withdraw once approved."
                                            : "To ensure safety, please verify your identity to withdraw funds.",
                                           style: const TextStyle(color: Colors.white70)
                                         ),
                                         actions: [
                                           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                           if (kycStatus != 'pending')
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  context.push('/kyc');
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text("VERIFY NOW")
                                              )
                                         ],
                                       )
                                     );
                                  }
>>>>>>> dev-update
                                },
                                icon: const Icon(Icons.redeem),
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
          const Text("TOTAL COINS", style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 8),
          Text("${totalBalance.toStringAsFixed(0)}", style: const TextStyle(color: Colors.amber, fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("1 Coin = ₹1", style: TextStyle(color: Colors.white30, fontSize: 10)),
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
<<<<<<< HEAD
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Buy Coins", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                  child: const Text("PAY & GET COINS")
=======
      builder: (context) => StatefulBuilder( // Use StatefulBuilder to update Checkbox
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add Cash", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
>>>>>>> dev-update
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
                    child: const Text("PAY & GET COINS")
                  ),
                )
              ],
            ),
          ),
        ),
      )
    );
  }

<<<<<<< HEAD
  // New Transaction List using Stream from Repository
  Widget _buildLiveTransactionList(String userId) {
      return StreamBuilder<QuerySnapshot>(
          stream: ref.read(walletRepositoryProvider).listenToTransactions(userId),
          builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error loading transactions"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("No transactions yet", style: TextStyle(color: Colors.white54)));

              return ListView.builder(
                  itemCount: docs.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final type = data['type'] ?? 'unknown';
                      final amount = data['amount'] ?? 0;
                      final isCredit = type == 'deposit' || type == 'winnings'; // Adjust keys as per worker
                      
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
=======
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
>>>>>>> dev-update
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
