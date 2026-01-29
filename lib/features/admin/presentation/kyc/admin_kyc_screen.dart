import 'package:axevora11/features/kyc/data/kyc_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminKYCScreen extends ConsumerStatefulWidget {
  const AdminKYCScreen({super.key});

  @override
  ConsumerState<AdminKYCScreen> createState() => _AdminKYCScreenState();
}

class _AdminKYCScreenState extends ConsumerState<AdminKYCScreen> {
  bool _isLoading = false;

  Future<void> _actionKYC(String userId, bool approve, {String? reason}) async {
    setState(() => _isLoading = true);
    try {
      if (approve) {
        await ref.read(kycRepositoryProvider).approveKYC(userId);
      } else {
        await ref.read(kycRepositoryProvider).rejectKYC(userId, reason ?? 'Rejected by Admin');
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? "Approved" : "Rejected")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(String userId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Reject KYC", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Reason (e.g. Blurred Image)", 
            hintStyle: TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black12
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(ctx);
               _actionKYC(userId, false, reason: reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("KYC Requests"),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.read(kycRepositoryProvider).getPendingKYCRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No Pending Requests", style: TextStyle(color: Colors.white54)));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final userId = data['userId'];
              
              return ExpansionTile(
                title: Text(data['fullName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("PAN: ${data['panNumber']} • DOB: ${data['dob']}", style: const TextStyle(color: Colors.white70)),
                children: [
                   Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text("Documents:", style: TextStyle(color: Colors.white54)),
                         const SizedBox(height: 10),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceAround,
                           children: [
                             _DocThumb(url: data['panUrl'], label: "PAN"),
                             _DocThumb(url: data['aadhaarFrontUrl'], label: "Aadhaar Front"),
                             _DocThumb(url: data['aadhaarBackUrl'], label: "Aadhaar Back"),
                           ],
                         ),
                         const SizedBox(height: 20),
                         if (_isLoading)
                           const Center(child: CircularProgressIndicator())
                         else
                           Row(
                             mainAxisAlignment: MainAxisAlignment.end,
                             children: [
                               OutlinedButton(
                                 onPressed: () => _showRejectDialog(userId), 
                                 style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                 child: const Text("Reject")
                               ),
                               const SizedBox(width: 16),
                               ElevatedButton(
                                 onPressed: () => _actionKYC(userId, true),
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green), 
                                 child: const Text("Approve")
                               ),
                             ],
                           )
                       ],
                     ),
                   )
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DocThumb extends StatelessWidget {
  final String? url;
  final String label;
  const _DocThumb({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (url != null) launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
      },
      child: Column(
        children: [
          Container(
            height: 80, width: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              color: Colors.grey[800],
              image: url != null ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover) : null
            ),
            child: url == null ? const Icon(Icons.broken_image, color: Colors.white54) : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10))
        ],
      ),
    );
  }
}
