import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/league_model.dart';
import 'package:axevora11/core/constants/app_colors.dart';

class LeagueManagementScreen extends StatefulWidget {
  const LeagueManagementScreen({super.key});

  @override
  State<LeagueManagementScreen> createState() => _LeagueManagementScreenState();
}

class _LeagueManagementScreenState extends State<LeagueManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("League Manager"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('leagues').orderBy('priority', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text("No Leagues Found", style: TextStyle(color: Colors.grey)),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: _seedDefaultLeagues, 
                     child: const Text("Seed Defaults (IPL, ICC)")
                   )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final league = LeagueModel.fromMap(doc.data() as Map<String, dynamic>);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: league.active ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      league.active ? Icons.check_circle : Icons.cancel,
                      color: league.active ? Colors.green : Colors.red
                    ),
                  ),
                  title: Text(league.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${league.type} • Priority: ${league.priority}"),
                  trailing: Switch(
                    value: league.active,
                    activeColor: Colors.green,
                    onChanged: (val) => _toggleLeague(doc.reference, val),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLeagueDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _toggleLeague(DocumentReference ref, bool val) async {
    await ref.update({'active': val});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(val ? "League Activated" : "League Deactivated"))
    );
  }

  Future<void> _seedDefaultLeagues() async {
    final batch = _firestore.batch();
    
    final leagues = [
      const LeagueModel(id: 'icc_wc_2026', name: 'ICC World Cup 2026', type: 'ODI', active: true, priority: 100),
      const LeagueModel(id: 't20_wc_2026', name: 'T20 World Cup 2026', type: 'T20', active: true, priority: 90),
      const LeagueModel(id: 'ipl_2026', name: 'IPL 2026', type: 'T20', active: true, priority: 80),
      const LeagueModel(id: 'asia_cup_2026', name: 'Asia Cup', type: 'ODI', active: false, priority: 70),
    ];

    for (var l in leagues) {
      batch.set(_firestore.collection('leagues').doc(l.id), l.toMap());
    }

    await batch.commit();
  }

  void _showAddLeagueDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: "T20");
    final priorityCtrl = TextEditingController(text: "50");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New League"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idCtrl, decoration: const InputDecoration(labelText: "ID (e.g. bbl_2026)")),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name (e.g. Big Bash)")),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: "Type (T20/ODI)")),
            TextField(controller: priorityCtrl, decoration: const InputDecoration(labelText: "Priority"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
              
              final newLeague = LeagueModel(
                id: idCtrl.text.trim(), 
                name: nameCtrl.text.trim(), 
                type: typeCtrl.text.trim(), 
                active: true, 
                priority: int.tryParse(priorityCtrl.text) ?? 50
              );

              await _firestore.collection('leagues').doc(newLeague.id).set(newLeague.toMap());
              Navigator.pop(ctx);
            }, 
            child: const Text("Add")
          )
        ],
      )
    );
  }
}
