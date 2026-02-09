
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({Key? key}) : super(key: key);

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  String _selectedBrand = 'Amazon';
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];
  double _winningBalance = 0.0;
  double _depositBalance = 0.0;
  
  // Worker URL (Ideally from a central config/constants file)
  final String _workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _fetchHistory();
  }

  Future<void> _fetchBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final response = await http.get(Uri.parse('$_workerUrl/api/wallet/balance?userId=${user.uid}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['balance'] != null) {
            setState(() {
                _winningBalance = (data['balance']['winnings'] ?? 0).toDouble();
                _depositBalance = (data['balance']['deposit'] ?? 0).toDouble();
            });
        }
      }
    } catch (e) {
      print("Error fetching balance: $e");
    }
  }

  Future<void> _fetchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.get(Uri.parse('$_workerUrl/api/voucher/my?userId=${user.uid}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['history'] != null) {
          setState(() {
            _history = List<Map<String, dynamic>>.from(data['history']);
          });
        }
      }
    } catch (e) {
      print("Error fetching history: $e");
    }
  }

  Future<void> _submitRequest() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 50) { // Min 50 limit
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum redeem amount is 50 Credits')));
      return;
    }
    if (amount > _winningBalance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient Winning Balance')));
      return;
    }

    setState(() { _isLoading = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_workerUrl/api/voucher/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': user.uid,
          'brand': _selectedBrand,
          'credits': amount
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Submitted Successfull!')));
        _amountController.clear();
        _fetchBalance(); // Refresh Balance
        _fetchHistory(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Request Failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Redeem Rewards"),
        backgroundColor: Colors.indigo,
        actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBalance)
        ],
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade500]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Redeemable (Winnings)", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                    Text("Play Credits (Deposit)", style: TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                        Text(
                          "${_winningBalance.toStringAsFixed(0)}", 
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                        ),
                        Text(
                          "${_depositBalance.toStringAsFixed(0)}", 
                          style: const TextStyle(color: Colors.white54, fontSize: 14)
                        ),
                    ]
                )
              ],
            ),
          ),

          // Request Form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Request New Voucher", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedBrand,
                      decoration: const InputDecoration(labelText: "Select Brand", border: OutlineInputBorder()),
                      items: ['Amazon', 'Flipkart', 'Myntra', 'Zomato'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() => _selectedBrand = v!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Enter Credits (Min 50)", border: OutlineInputBorder(), suffixText: "Credits"),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : _submitRequest,
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Text("Redeem Now", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft, child: Text("Request History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo))),
          ),
          const SizedBox(height: 10),

          // History List
          Expanded(
            child: _history.isEmpty 
              ? const Center(child: Text("No requests yet", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _history.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final status = item['status'] ?? 'pending';
                    final date = DateTime.fromMillisecondsSinceEpoch(item['created_at']);
                    final isApproved = status == 'approved';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isApproved ? Colors.green.shade100 : (status=='rejected' ? Colors.red.shade100 : Colors.orange.shade100),
                          child: Icon(
                            isApproved ? Icons.check : (status=='rejected' ? Icons.close : Icons.hourglass_bottom),
                            color: isApproved ? Colors.green : (status=='rejected' ? Colors.red : Colors.orange),
                          ),
                        ),
                        title: Text("${item['brand']} Voucher"), // User Input.
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${item['credits']} Credits â€¢ ${date.day}/${date.month}/${date.year}"),
                            if (isApproved && item['voucher_code'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SelectableText(
                                  "Code: ${item['voucher_code']}", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)
                                ),
                              ),
                             if (status == 'pending')
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text("Will arrive in 12-24 Hrs", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                          ],
                        ),
                        trailing: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: isApproved ? Colors.green : (status=='rejected' ? Colors.red : Colors.orange),
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
