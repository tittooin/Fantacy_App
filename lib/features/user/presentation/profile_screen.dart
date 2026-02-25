import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axevora11/features/user/domain/user_entity.dart';
import 'package:axevora11/features/user/data/user_repository.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/core/utils/share_utils.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  String get _currentUid => ref.watch(authUserIdProvider) ?? '';
  bool get _isMe => widget.userId == _currentUid;
  bool get _isAdmin => ref.watch(authStateProvider).value?.email == 'tittoosss@gmail.com';

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    if (_isMe || _currentUid.isEmpty) return;
    try {
      final isFollowing = await ref.read(userRepositoryProvider).isFollowing(_currentUid, widget.userId);
      if (mounted) setState(() => _isFollowing = isFollowing);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (_isLoadingFollow || _currentUid.isEmpty) return;
    setState(() => _isLoadingFollow = true);
    
    try {
      if (_isFollowing) {
        await ref.read(userRepositoryProvider).unfollowUser(currentUid: _currentUid, targetUid: widget.userId);
      } else {
        await ref.read(userRepositoryProvider).followUser(currentUid: _currentUid, targetUid: widget.userId);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingFollow = false);
    }
  }

  void _showEditProfileDialog(UserEntity user) {
    final nameController = TextEditingController(text: user.displayName);
    final bioController = TextEditingController(text: user.bio);
    final photoController = TextEditingController(text: user.photoUrl);
    final phoneController = TextEditingController(text: user.phoneNumber);
    String? selectedState = user.selectedState;

    final List<String> indianStates = [
      "Andaman & Nicobar Islands", "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", 
      "Chandigarh", "Chhattisgarh", "Dadra & Nagar Haveli", "Daman & Diu", "Delhi", "Goa", 
      "Gujarat", "Haryana", "Himachal Pradesh", "Jammu & Kashmir", "Jharkhand", "Karnataka", 
      "Kerala", "Ladakh", "Lakshadweep", "Madhya Pradesh", "Maharashtra", "Manipur", 
      "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Puducherry", "Punjab", "Rajasthan", 
      "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
    ];

    final restrictedStates = {"Andhra Pradesh", "Assam", "Nagaland", "Odisha", "Sikkim", "Telangana"};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Profile"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(controller: nameController, decoration: const InputDecoration(labelText: "Display Name")),
                   const SizedBox(height: 12),
                   TextField(controller: bioController, decoration: const InputDecoration(labelText: "Bio")),
                   const SizedBox(height: 12),
                   TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Mobile Number")),
                   const SizedBox(height: 12),
                   TextField(controller: photoController, decoration: const InputDecoration(labelText: "Photo URL")),
                   const SizedBox(height: 12),
                   DropdownButtonFormField<String>(
                     value: selectedState,
                     decoration: const InputDecoration(labelText: "Select State"),
                     items: indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                     onChanged: (val) => setState(() => selectedState = val),
                   ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (selectedState == null) return;
                  Navigator.pop(ctx);
                  await ref.read(userRepositoryProvider).updateProfile(
                    uid: _currentUid, 
                    displayName: nameController.text,
                    bio: bioController.text,
                    photoUrl: photoController.text,
                    phoneNumber: phoneController.text,
                  );
                  final isRestricted = restrictedStates.contains(selectedState);
                  await ref.read(userRepositoryProvider).updateUserState(_currentUid, selectedState!, isRestricted);
                },
                child: const Text("Save"),
              )
            ],
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userByUidProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 0,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () => ShareUtils.shareApp(context: context),
          ),
          PopupMenuButton<String>(
               icon: const Icon(Icons.settings, color: Colors.white),
               onSelected: (value) async {
                 if (value == 'logout') {
                   await ref.read(authRepositoryProvider).signOut();
                   if (mounted) context.go('/login');
                 }
               },
               itemBuilder: (ctx) => [
                 const PopupMenuItem(value: 'logout', child: Text("Logout")),
               ],
             )
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("User not found"));
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(user),
                _buildStatsRow(user),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Match History will appear here", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildProfileHeader(UserEntity user) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.indigo,
      width: double.infinity,
      child: Column(
        children: [
           CircleAvatar(
             radius: 50,
             backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty ? NetworkImage(user.photoUrl!) : null,
             child: user.photoUrl == null || user.photoUrl!.isEmpty ? const Icon(Icons.person, size: 50) : null,
           ),
           const SizedBox(height: 16),
           Text(user.displayName ?? "User", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
           const SizedBox(height: 16),
           if (_isMe) ...[
             ElevatedButton(onPressed: () => _showEditProfileDialog(user), child: const Text("Edit Profile")),
             if (_isAdmin)
               Padding(
                 padding: const EdgeInsets.only(top: 12.0),
                 child: ElevatedButton.icon(
                   onPressed: () => context.push('/admin/dashboard'),
                   icon: const Icon(Icons.admin_panel_settings, size: 18),
                   label: const Text("ADMIN PANEL"),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.redAccent,
                     foregroundColor: Colors.white,
                     shape: const StadiumBorder(),
                   ),
                 ),
               ),
           ] else
             ElevatedButton(onPressed: _toggleFollow, child: Text(_isFollowing ? "Following" : "Follow")),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserEntity user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Followers", user.followersCount.toString()),
          _buildStatItem("Following", user.followingCount.toString()),
          _buildStatItem("Contests", user.contestsPlayed.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
