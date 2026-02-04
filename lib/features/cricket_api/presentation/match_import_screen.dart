import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/cricket_api/data/match_repository.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MatchImportScreen extends ConsumerStatefulWidget {
  const MatchImportScreen({super.key});

  @override
  ConsumerState<MatchImportScreen> createState() => _MatchImportScreenState();
}

class _MatchImportScreenState extends ConsumerState<MatchImportScreen> {
  late Stream<QuerySnapshot> _matchesStream;

  @override
  void initState() {
    super.initState();
    _matchesStream = FirebaseFirestore.instance
        .collection('matches')
        .orderBy('startDate', descending: true)
        .limit(50) // Limit to save Quota
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Live & Upcoming only (Worker handles filtering)
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          title: const Text("Import New Matches"),
          bottom: const TabBar(
            tabs: [Tab(text: "Live"), Tab(text: "Upcoming")],
            indicatorColor: Colors.blueAccent,
          ),
        ),
        body: const TabBarView(children: [
           _ImportList(type: 'Live'),
           _ImportList(type: 'Upcoming'),
        ]),
      ),
    );
  }
}

class _ImportList extends ConsumerStatefulWidget {
  final String type;
  const _ImportList({required this.type});
  @override
  ConsumerState<_ImportList> createState() => _ImportListState();
}

class _ImportListState extends ConsumerState<_ImportList> {
  List<CricketMatchModel> _list = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });
    try {
      // 1. Fetch from Worker (Already Filtered: Live/Future/Recent)
      final res = await ref.read(rapidApiServiceProvider).fetchFixtures(); 
      
      // 2. Client-Side Tab Filter
      if (mounted) {
         setState(() {
            if (widget.type == 'Live') {
               _list = res.where((m) => m.status == 'Live' || m.status == 'In Progress').toList();
            } else {
               _list = res.where((m) => m.status == 'Upcoming' || m.status == 'Scheduled').toList();
            }
         });
      }
    } catch(e) {
      if(mounted) setState(() => _error = "Error: $e");
    } finally {
      if(mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error, style: const TextStyle(color: Colors.red)), ElevatedButton(onPressed: _fetch, child: const Text("Retry"))]));
    
    if (_list.isEmpty) return const Center(child: Text("No matches found from API.", style: TextStyle(color: Colors.white54)));

    return ListView.separated(
      itemCount: _list.length,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final m = _list[i];
        return Container(
          decoration: BoxDecoration(color: const Color(0xFF1E2A38), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("${m.seriesName}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                     const SizedBox(height: 4),
                     Text("${m.team1ShortName} vs ${m.team2ShortName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(height: 4),
                     Text("${DateFormat('dd MMM, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(m.startDate))} • ${m.status}", style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                   ],
                 ),
               ),
               IconButton(
                 style: IconButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                 icon: const Icon(Icons.people),
                 tooltip: "Manage Squad",
                 onPressed: () {
                    context.push('/admin/matches/${m.id}/manage-squad', extra: m);
                 },
               ),
               const SizedBox(width: 8),
               IconButton(
                 style: IconButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                 icon: const Icon(Icons.download),
                 onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Importing...")));
                    await ref.read(matchRepositoryProvider).addMatch(m);
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Imported!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                 },
               ),
            ],
          ),
        );
      }
    );
  }
}
