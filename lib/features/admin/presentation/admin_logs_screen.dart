import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminLogsScreen extends StatelessWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audit Logs & Safety")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admin_logs')
            .orderBy('timestamp', descending: true)
            .limit(100) // Safety limit
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No Logs Found"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final action = data['action'] ?? 'UNKNOWN';
              final matchId = data['matchId'] ?? '-';
              final adminId = data['adminId'] ?? 'System';
              final timestamp = data['timestamp'] as String?;
              final date = timestamp != null ? DateTime.parse(timestamp) : DateTime.now();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActionColor(action).withOpacity(0.2),
                    child: Icon(_getActionIcon(action), color: _getActionColor(action), size: 16),
                  ),
                  title: Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text("ByID: $adminId • Match: $matchId\n${date.toLocal()}", style: const TextStyle(fontSize: 10)),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () => _showDetails(context, data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(data['action'] ?? 'Details', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(data.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.white54)))
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('WITHDRAWAL')) return Colors.orange;
    if (action.contains('ARCHIVE')) return Colors.grey;
    if (action.contains('STATUS')) return Colors.blue;
    if (action.contains('SCORE') || action.contains('SYNC')) return Colors.green;
    return Colors.purple;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('WITHDRAWAL')) return Icons.wallet;
    if (action.contains('ARCHIVE')) return Icons.archive;
    if (action.contains('STATUS')) return Icons.edit;
    if (action.contains('SYNC')) return Icons.sync;
    return Icons.security;
  }
}
