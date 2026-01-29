import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';

class CreatePrivateContestScreen extends ConsumerStatefulWidget {
  final CricketMatchModel match;

  const CreatePrivateContestScreen({super.key, required this.match});

  @override
  ConsumerState<CreatePrivateContestScreen> createState() => _CreatePrivateContestScreenState();
}

class _CreatePrivateContestScreenState extends ConsumerState<CreatePrivateContestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _entryFeeController = TextEditingController();
  final TextEditingController _maxTeamsController = TextEditingController();
  
  double _estimatedPrize = 0;
  bool _isLoading = false;

  void _calculatePrize() {
    final entry = double.tryParse(_entryFeeController.text) ?? 0;
    final spots = double.tryParse(_maxTeamsController.text) ?? 0;
    // Platform Fee 10%
    setState(() {
      _estimatedPrize = (entry * spots) * 0.9;
    });
  }

  Future<void> _createContest() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = ref.read(authRepositoryProvider).currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final contestId = const Uuid().v4();
      final inviteCode = "PC${contestId.substring(0, 6).toUpperCase()}";
      
      final contestData = {
        'id': contestId,
        'category': 'Private',
        'subCategory': _nameController.text.isEmpty ? 'Private League' : _nameController.text,
        'entryFee': int.parse(_entryFeeController.text),
        'totalSpots': int.parse(_maxTeamsController.text),
        'filledSpots': 0,
        'totalPrize': _estimatedPrize,
        'firstPrize': _estimatedPrize, // Winner Takes All (Simplified) or Custom
        'winnerCount': 1,
        'winningBreakdown': [
           {'rankStart': 1, 'rankEnd': 1, 'amount': _estimatedPrize}
        ],
        'matchId': widget.match.id.toString(),
        'isPrivate': true,
        'inviteCode': inviteCode,
        'createdBy': userId,
        'status': 'Open'
      };

      // Save to shared contests collection (or match specific)
      // Per our schema: matches/{matchId}/contests/{contestId}
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.match.id.toString())
          .collection('contests')
          .doc(contestId)
          .set(contestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Private Contest Created!")));
        // Navigate to Invite Screen or Contest Detail
        context.pop(); // Go back to match home
        // Ideally show invite code dialog
        _showInviteDialog(inviteCode);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInviteDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Contest Created!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text("Share this code with friends:"),
             const SizedBox(height: 16),
             SelectableText(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Create Private Contest"), backgroundColor: const Color(0xFF0B1E3C), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Give your contest a name", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: "e.g. Friends Forever", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Entry Fee", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _entryFeeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: "10", prefixText: "₹ ", border: OutlineInputBorder()),
                          onChanged: (_) => _calculatePrize(),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            if (double.tryParse(v) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Max Spots", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _maxTeamsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: "2", border: OutlineInputBorder()),
                          onChanged: (_) => _calculatePrize(),
                          validator: (v) {
                             if (v == null || v.isEmpty) return "Required";
                             int? val = int.tryParse(v);
                             if (val == null || val < 2) return "Min 2 spots";
                             return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Prize Calculation Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Prize Pool", style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text("₹ ${_estimatedPrize.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const Divider(),
                    const Text("Platform Fee: 10% (Included)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createContest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("CREATE CONTEST", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
