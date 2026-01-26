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
  List<CricketMatchModel> _matches = [];
  String _log = "";
  bool _isLoading = false;
  bool _isImporting = false;

  String getTeamImage(String imageId) {
    if (imageId.isNotEmpty && imageId.length > 3) {
      return 'https://free-cricbuzz-cricket-api1.p.rapidapi.com/img/v1/i1/c$imageId/i.jpg';
    }
    return "https://via.placeholder.com/40";
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Saved, Live, Recent, Upcoming
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             TabBar(
              isScrollable: true,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.blueAccent,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: "Saved Matches"),
                Tab(text: "Live"),
                Tab(text: "Recent"),
                Tab(text: "Upcoming"),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSavedMatchesTab(),
                  _buildFetchTab("Live"),
                  _buildFetchTab("Recent"),
                  _buildFetchTab("Upcoming"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generic Fetch Tab
  Widget _buildFetchTab(String type) {
     return Column(
        children: [
           // Fetch Controller
           Container(
             padding: const EdgeInsets.all(16),
             color: Colors.white.withOpacity(0.05),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("$type Matches", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     Text(
                       type == 'Live' ? "Direct from RapidAPI (Admin Sync)" : (type == 'Recent' ? "Completed matches" : "Future fixtures"), 
                       style: const TextStyle(color: Colors.white54, fontSize: 12)
                     ),
                   ],
                 ),
                 ElevatedButton.icon(
                   onPressed: _isLoading ? null : () => _fetchData(type),
                   icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                   label: Text(_isLoading ? "Loading..." : "Refresh $type"),
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                 )
               ],
             ),
           ),
           
           // List
           // List
           Expanded(
             child: Builder(
               builder: (context) {
                 final validMatches = _matches.where((m) {
                    final t1 = m.team1Name.trim();
                    final t2 = m.team2Name.trim();
                    return t1.isNotEmpty && t2.isNotEmpty && 
                           t1 != 'Team 1' && t2 != 'Team 2' && 
                           t1 != '0' && t2 != '0' &&
                           t1.toLowerCase() != 'unknown' && t2.toLowerCase() != 'unknown';
                 }).toList();

                 if (validMatches.isEmpty) {
                   return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_cricket, size: 48, color: Colors.white10),
                        const SizedBox(height: 16),
                        Text("No valid $type matches found.", style: const TextStyle(color: Colors.white38)),
                      ],
                    )
                   );
                 }

                 return ListView.separated(
                   padding: const EdgeInsets.all(16),
                   itemCount: validMatches.length,
                   separatorBuilder: (c, i) => const SizedBox(height: 12),
                   itemBuilder: (context, index) {
                      return _buildMatchCard(validMatches[index]);
                   },
               );
               }
             ),
           )
        ],
     );
  }

  // Refactored Fetch Logic
  Future<void> _fetchData(String type) async {
    setState(() { _isLoading = true; _matches = []; });
    try {
      final service = ref.read(rapidApiServiceProvider);
      List<CricketMatchModel> results = [];
      
      if (type == 'Recent') {
         results = await service.fetchFixtures();
      } else if (type == 'Live') {
         // Fix: User wants to IMPORT, so we must Fetch Fresh from API (Sync), not just read DB.
         results = await service.fetchFixtures(); 
      } else {
         results = await service.fetchFixtures();
      }

      setState(() {
        _matches = results;
        _log = "Fetched ${results.length} $type matches";
      });
    } catch (e) {
       debugPrint("Error: $e");
    } finally {
       setState(() => _isLoading = false);
    }
  }

  Widget _buildMatchCard(CricketMatchModel match) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: ListTile(
          leading: Image.network(
             match.team1Img.length > 3 ? "https://free-cricbuzz-cricket-api1.p.rapidapi.com/img/v1/i1/c${match.team1Img}/i.jpg" : "https://via.placeholder.com/40",
             width: 40, height: 40, fit: BoxFit.cover,
             errorBuilder: (c,e,s) => const Icon(Icons.sports_cricket, color: Colors.white70),
          ),
          title: Text("${match.team1ShortName} vs ${match.team2ShortName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("${match.matchDesc} • ${match.venue}\n${match.status}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          trailing: ElevatedButton(
             onPressed: () => _importMatch(match),
             child: const Text("Import"),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
          ),
        ),
      );
  }

  Future<void> _importMatch(CricketMatchModel match) async {
      // ... [Keep Existing Import Logic] ...
      setState(() => _isImporting = true);
      try {
        await ref.read(matchRepositoryProvider).addMatch(match);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Imported!"), backgroundColor: Colors.green));
      } catch(e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      } finally {
        setState(() => _isImporting = false);
      }
  }

  Widget _buildSavedMatchesTab() {
     return StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instance.collection('matches').snapshots(),
       builder: (context, snapshot) {
         if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
         if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

         final allDocs = snapshot.data?.docs ?? [];
         final docs = allDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['isArchived'] != true;
         }).toList();

         if (docs.isEmpty) return const Center(child: Text("No active saved matches found."));

         return ListView.builder(
           itemCount: docs.length,
           itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final match = CricketMatchModel.fromMap(data);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListTile(
                      onTap: () => context.go('/admin/matches/create-contest', extra: match),
                      leading: ClipOval(
                        child: Container(
                          width: 40, height: 40, color: Colors.white10,
                          child: Image.network(
                            getTeamImage(match.team1Img), fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.sports_cricket, color: Colors.white),
                          ),
                        ),
                      ),
                      title: Text("${match.team1ShortName} vs ${match.team2ShortName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("${match.seriesName}\n${DateFormat('MMM dd, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(match.startDate))} • ${match.status}", style: const TextStyle(color: Colors.white70)), 
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, elevation: 0),
                            onPressed: () => context.go('/admin/matches/create-contest', extra: match),
                            icon: const Icon(Icons.add_circle, size: 16),
                            label: const Text("Create Contest"),
                          ),
                          const SizedBox(width: 8),
                          Builder(builder: (context) {
                             final s = match.status.trim().toLowerCase();
                             if (s == 'completed') {
                               return IconButton(
                                 icon: const Icon(Icons.archive, color: Colors.orangeAccent),
                                 tooltip: "Archive Match",
                                 onPressed: () => _archiveMatch(match),
                               );
                             } else if (s != 'live') {
                               return IconButton(
                                 icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                 tooltip: "Delete Match",
                                 onPressed: () => _deleteMatch(match),
                               );
                             }
                             return const SizedBox.shrink(); 
                          }),
                        ],
                      ),
                    ),
                  );
           },
         );
       },
     );
  }

  Future<void> _archiveMatch(CricketMatchModel match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Archive Match?", style: TextStyle(color: Colors.black)),
        content: Text("This will hide '${match.team1ShortName} vs ${match.team2ShortName}' from this list.", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ARCHIVE", style: TextStyle(color: Colors.orange))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('matches').doc(match.id.toString()).update({'isArchived': true});
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Archived"), backgroundColor: Colors.orange));
        }
      } catch (e) {
        debugPrint("Archive Error: $e");
      }
    }
  }

  Future<void> _deleteMatch(CricketMatchModel match) async {
    if (match.status == 'Live') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Match?", style: TextStyle(color: Colors.red)),
        content: Text("Are you sure you want to delete ${match.team1ShortName} vs ${match.team2ShortName}?", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('matches').doc(match.id.toString()).delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match deleted"), backgroundColor: Colors.green));
      } catch (e) {
        debugPrint("Delete Error: $e");
      }
    }
  }
}
