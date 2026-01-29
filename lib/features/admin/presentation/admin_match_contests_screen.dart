import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/domain/contest_model.dart';

class AdminMatchContestsScreen extends ConsumerStatefulWidget {
  final String matchId;
  final CricketMatchModel? match;

  const AdminMatchContestsScreen({super.key, required this.matchId, this.match});

  @override
  ConsumerState<AdminMatchContestsScreen> createState() => _AdminMatchContestsScreenState();
}

class _AdminMatchContestsScreenState extends ConsumerState<AdminMatchContestsScreen> {
  bool _isLoading = true;
  List<ContestModel> _contests = [];

  @override
  void initState() {
    super.initState();
    _fetchContests();
  }

  Future<void> _fetchContests() async {
    setState(() => _isLoading = true);
    try {
      final qs = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('contests')
          .get();
      
      final list = qs.docs.map((d) => ContestModel.fromJson(d.data())).toList();
      if(mounted) setState(() => _contests = list);
    } catch (e) {
      debugPrint("Error loading contests: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteContest(String contestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('contests')
          .doc(contestId)
          .delete();
      _fetchContests(); // Refresh
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contest Deleted")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.match != null 
            ? "${widget.match!.team1ShortName} vs ${widget.match!.team2ShortName} Contests" 
            : "Match Contests"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchContests),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (widget.match != null) {
            await context.push('/admin/matches/create-contest', extra: widget.match);
            _fetchContests(); // Refresh on return
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match data missing. Cannot create contest.")));
          }
        },
        label: const Text("Create Contest"),
        icon: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _contests.isEmpty 
           ? const Center(child: Text("No Contests Created Yet."))
           : ListView.builder(
               padding: const EdgeInsets.all(16),
               itemCount: _contests.length,
               itemBuilder: (context, index) {
                 final contest = _contests[index];
                 return Card(
                   margin: const EdgeInsets.only(bottom: 12),
                   child: ListTile(
                     title: Text("${contest.category} (₹${contest.entryFee})"),
                     subtitle: Text("Spots: ${contest.filledSpots}/${contest.totalSpots} | Pool: ₹${contest.prizePool}"),
                     trailing: IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: () => _deleteContest(contest.id),
                     ),
                   ),
                 );
               },
             ),
    );
  }
}
