import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:axevora11/features/wallet/data/wallet_repository.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ref.read(walletRepositoryProvider).getAllUsers();

      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
    } else {
      setState(() {
        _filteredUsers = _users.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management (D1)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search Users",
                hintText: "Name or Email",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _filterUsers,
            ),
            const SizedBox(height: 16),
            
            // User Table
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty 
                  ? const Center(child: Text("No users found."))
                  : DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 800,
                      columns: const [
                        DataColumn2(label: Text('Name'), size: ColumnSize.L),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Deposit')),
                        DataColumn(label: Text('Winnings')),
                        DataColumn(label: Text('Joined')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredUsers.map((user) {
                        final joinedAt = user['joined_at'];
                        final joined = joinedAt != null 
                             ? DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(joinedAt)) 
                             : 'N/A';
                             
                        final deposit = user['deposit_credits'] ?? 0;
                        final winnings = user['winning_credits'] ?? 0;

                        return DataRow(cells: [
                          DataCell(Text(user['name'] ?? 'User')),
                          DataCell(Text(user['email'] ?? '-')),
                          DataCell(Text("₹$deposit")),
                          DataCell(Text("₹$winnings")),
                          DataCell(Text(joined)),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit User feature coming soon.")));
                            },
                          )),
                        ]);
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
