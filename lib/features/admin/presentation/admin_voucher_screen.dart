
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pending = [];
  List<dynamic> _history = [];
  bool _isLoading = true;
  
  // Worker URL
  final String _workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_workerUrl/api/admin/voucher/list'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _pending = data['pending'] ?? [];
            _history = data['history'] ?? [];
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processRequest(String reqId, String action, String? code) async {
    try {
      final response = await http.post(
        Uri.parse('$_workerUrl/api/admin/voucher/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requestId': reqId,
          'action': action,
          'code': code
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request ${action.toUpperCase()}D")));
           _fetchRequests(); // Refresh
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Action Failed')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showApproveDialog(Map<String, dynamic> req) {
    final codeController = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text("Approve ${req['brand']} Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User: ${req['user_id']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text("Credits: ${req['credits']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: "Paste Voucher Code", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isEmpty) return;
              Navigator.pop(ctx);
              _processRequest(req['id'], 'approve', codeController.text);
            }, 
            child: const Text("Approve & Send")
          )
        ],
      )
    );
  }

  void _showRejectDialog(Map<String, dynamic> req) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Request?"),
        content: const Text("Credits will be refunded to the user's wallet automatically."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _processRequest(req['id'], 'reject', null);
            }, 
            child: const Text("Reject & Refund")
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voucher Requests"),
        backgroundColor: Colors.blueGrey.shade900,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Pending"), Tab(text: "History")],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_pending, isPending: true),
              _buildList(_history, isPending: false),
            ],
          ),
    );
  }

  Widget _buildList(List<dynamic> list, {required bool isPending}) {
    if (list.isEmpty) return const Center(child: Text("No requests found"));

    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final item = list[index];
        final date = DateTime.fromMillisecondsSinceEpoch(item['created_at']);
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text("${item['brand']} Voucher - ${item['credits']} Credits"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User: ${item['user_id']}", style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                Text("Requested: ${date.toString().split('.')[0]}"),
                if (!isPending) 
                  Text(
                    "Status: ${item['status'].toString().toUpperCase()}", 
                    style: TextStyle(
                      color: item['status']=='approved' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold
                    )
                  ),
                if (item['voucher_code'] != null)
                   SelectableText("Code: ${item['voucher_code']}", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: isPending 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green), 
                      onPressed: () => _showApproveDialog(item)
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red), 
                      onPressed: () => _showRejectDialog(item)
                    ),
                  ],
                )
              : null,
          ),
        );
      },
    );
  }
}
