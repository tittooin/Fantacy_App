import 'package:axevora11/features/cricket_api/data/cricket_api_service.dart';
import 'package:axevora11/features/cricket_api/data/match_repository.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      return 'https://cricbuzz-cricket.p.rapidapi.com/img/v1/i1/c$imageId/i.jpg';
    }
    return "https://via.placeholder.com/40";
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
      _log = "Fetching from RapidAPI...";
    });

    try {
      final service = ref.read(cricketApiServiceProvider);
      final matches = await service.fetchUpcomingMatches();
      setState(() {
        _matches = matches;
        _log = "Fetched ${matches.length} matches.";
      });
    } catch (e) {
      setState(() {
        _log = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             TabBar(
              labelColor: Colors.white, // Explicit white for visibility
              unselectedLabelColor: Colors.white54,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.storage), text: "Saved Matches"),
                Tab(icon: Icon(Icons.cloud_download), text: "Import New"),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSavedMatchesTab(),
                  _buildImportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedMatchesTab() {
     // Stream of matches from Firestore (Removed orderBy to avoid Index issues for now)
     return StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instance.collection('matches').snapshots(),
       builder: (context, snapshot) {
         if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
         if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

         final allDocs = snapshot.data?.docs ?? [];
         // Filter out archived matches
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

                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.grey, width: 0.5)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      onTap: () => context.go('/admin/matches/create-contest', extra: match),
                      leading: ClipOval(
                        child: Container(
                          width: 40, height: 40, color: Colors.grey.shade100,
                          child: Image.network(
                            getTeamImage(match.team1Img), fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.sports_cricket, color: Colors.black),
                          ),
                        ),
                      ),
                      title: Text("${match.team1ShortName} vs ${match.team2ShortName}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      subtitle: Text("${match.seriesName} • ${match.status}", style: const TextStyle(color: Colors.black87)), 
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0),
                            onPressed: () => context.go('/admin/matches/create-contest', extra: match),
                            icon: const Icon(Icons.add_circle, size: 16),
                            label: const Text("Create Contest"),
                          ),
                          const SizedBox(width: 8),
                          
                          // ROBUST LOGIC
                          Builder(builder: (context) {
                             final s = match.status.trim().toLowerCase();
                             if (s == 'completed') {
                               return IconButton(
                                 icon: const Icon(Icons.archive, color: Colors.orange),
                                 tooltip: "Archive Match",
                                 onPressed: () => _archiveMatch(match),
                               );
                             } else if (s != 'live') {
                               return IconButton(
                                 icon: const Icon(Icons.delete_outline, color: Colors.red),
                                 tooltip: "Delete Match",
                                 onPressed: () => _deleteMatch(match),
                               );
                             }
                             // Fallback for LIVE or Weird status
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
    // Safety handled by UI condition, but double check
    if (match.status == 'Live') return;

    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Match?", style: TextStyle(color: Colors.red)),
        content: Text("Are you sure you want to delete ${match.team1ShortName} vs ${match.team2ShortName}?\n\nThis will remove it from the database permanently.", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Use string ID for doc usually, confirm if model.id is int or string driven document.
        // Assuming doc ID is same as match ID (int->string) based on Repo import logic.
        await FirebaseFirestore.instance.collection('matches').doc(match.id.toString()).delete();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Match deleted successfully"), backgroundColor: Colors.green)
           );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Delete Error: $e"), backgroundColor: Colors.red)
           );
        }
      }
    }
  }

  Widget _buildImportTab() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Fetch from RapidAPI",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              if (_matches.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    "${_matches.length} Matches Found",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchMatches,
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_download),
            label: const Text("Fetch Upcoming Matches"),
          ),
          const SizedBox(height: 16),
          if (_log.isNotEmpty && _matches.isEmpty)
             Text(_log, style: const TextStyle(color: Colors.grey)),
             
          const SizedBox(height: 16),
          Expanded(
            child: _matches.isEmpty
                ? const Center(child: Text("Click 'Fetch' to load data from API.", style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipOval(
                            child: Container(
                               width: 40, height: 40,
                               color: Colors.grey.shade200,
                               child: Image.network(
                                 match.team1Img.isNotEmpty && match.team1Img.length > 3 
                                     ? "https://cricbuzz-cricket.p.rapidapi.com/img/v1/i1/c${match.team1Img}/i.jpg"
                                     : "https://via.placeholder.com/40", 
                                 fit: BoxFit.cover,
                                 errorBuilder: (c,e,s) => const Icon(Icons.sports_cricket, color: Colors.black),
                               ),
                            ),
                          ),
                          title: Text("${match.team1ShortName} vs ${match.team2ShortName}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(match.seriesName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text("${match.matchDesc} • ${match.venue}", style: const TextStyle(color: Colors.black54)),
                              Text(
                                DateTime.fromMillisecondsSinceEpoch(match.startDate).toString(),
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: (_isImporting || _isLoading) ? null : () async {
                              setState(() => _isImporting = true);
                              try {
                                await ref.read(matchRepositoryProvider).addMatch(match);
                                
                                if (context.mounted) {
                                  setState(() => _isImporting = false);
                                  // Show Success Dialog
                                  showDialog(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text("Success", style: TextStyle(color: Colors.green)),
                                      content: const Text("Match has been saved to Firestore Database!"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(c);
                                            // Switch to Saved Matches Tab (Index 0)
                                            DefaultTabController.of(context).animateTo(0);
                                          }, 
                                          child: const Text("OK")
                                        )
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint("FIRESTORE IMPORT ERROR: $e");
                                if (context.mounted) {
                                  setState(() => _isImporting = false);
                                  showDialog(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text("Import Failed", style: TextStyle(color: Colors.red)),
                                      content: Text("Could not save match.\n\nError: $e"),
                                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Close"))],
                                    ),
                                  );
                                }
                              }
                            },
                            child: _isImporting 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Text("Import"),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
  }
}
