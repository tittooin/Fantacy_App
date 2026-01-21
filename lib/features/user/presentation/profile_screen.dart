import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axevora11/features/user/domain/user_entity.dart';
import 'package:axevora11/features/user/data/user_repository.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:axevora11/core/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  bool get _isMe => widget.userId == _currentUid;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    if (_isMe) return;
    final isFollowing = await ref.read(userRepositoryProvider).isFollowing(_currentUid, widget.userId);
    if (mounted) setState(() => _isFollowing = isFollowing);
  }

  Future<void> _toggleFollow() async {
    if (_isLoadingFollow) return;
    setState(() => _isLoadingFollow = true);
    
    try {
      if (_isFollowing) {
        await ref.read(userRepositoryProvider).unfollowUser(currentUid: _currentUid, targetUid: widget.userId);
      } else {
        await ref.read(userRepositoryProvider).followUser(currentUid: _currentUid, targetUid: widget.userId);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoadingFollow = false);
    }
  }

  void _showEditProfileDialog(UserEntity user) {
    final nameController = TextEditingController(text: user.displayName);
    final bioController = TextEditingController(text: user.bio);
    final photoController = TextEditingController(text: user.photoUrl);
    String? selectedState = user.selectedState;

    final List<String> indianStates = [
      "Andaman & Nicobar Islands", "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", 
      "Chandigarh", "Chhattisgarh", "Dadra & Nagar Haveli", "Daman & Diu", "Delhi", "Goa", 
      "Gujarat", "Haryana", "Himachal Pradesh", "Jammu & Kashmir", "Jharkhand", "Karnataka", 
      "Kerala", "Ladakh", "Lakshadweep", "Madhya Pradesh", "Maharashtra", "Manipur", 
      "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Puducherry", "Punjab", "Rajasthan", 
      "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
    ];

    // Restricted States Logic
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
                   TextField(controller: bioController, decoration: const InputDecoration(labelText: "Bio", hintText: "Tell us about yourself")),
                   const SizedBox(height: 12),
                   TextField(controller: photoController, decoration: const InputDecoration(labelText: "Photo URL", hintText: "https://example.com/me.jpg")),
                   const SizedBox(height: 12),
                   DropdownButtonFormField<String>(
                     value: selectedState,
                     decoration: const InputDecoration(labelText: "Select State (Required for Compliance)"),
                     items: indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                     onChanged: (val) => setState(() => selectedState = val),
                   ),
                   if (selectedState != null && restrictedStates.contains(selectedState))
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(
                         "Note: Cash contests are not allowed in $selectedState.",
                         style: const TextStyle(color: Colors.red, fontSize: 12),
                       ),
                     ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (selectedState == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a state")));
                    return;
                  }
                  
                  Navigator.pop(ctx);
                  
                  // Update Profile Info
                  await ref.read(userRepositoryProvider).updateProfile(
                    uid: _currentUid, 
                    displayName: nameController.text,
                    bio: bioController.text,
                    photoUrl: photoController.text,
                  );

                  // Update State Compliance
                  final isRestricted = restrictedStates.contains(selectedState);
                  await ref.read(userRepositoryProvider).updateUserState(_currentUid, selectedState!, isRestricted);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated")));
                  }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 0,
        backgroundColor: Colors.indigo,
        actions: [
           IconButton(
             icon: const Icon(Icons.help_outline),
             tooltip: "Help & Support",
             onPressed: () {
               showDialog(
                 context: context, 
                 builder: (ctx) => AlertDialog(
                   title: const Text("Contact Support"),
                   content: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       ListTile(
                         leading: const Icon(Icons.email, color: Colors.indigo),
                         title: const Text("Email Us"),
                         subtitle: const Text("admin@axevora.com"),
                         onTap: () => Navigator.pop(ctx),
                       ),
                       ListTile(
                         leading: const Icon(Icons.chat, color: Colors.green),
                         title: const Text("WhatsApp & Telegram"),
                         subtitle: const Text("Support coming soon"),
                         onTap: () => Navigator.pop(ctx),
                       )
                     ],
                   ),
                   actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))]
                 )
               );
             },
           ),
           if (_isMe) 
             PopupMenuButton<String>(
               icon: const Icon(Icons.settings),
               onSelected: (value) async {
                 if (value == 'logout') {
                   final confirm = await showDialog<bool>(
                     context: context, 
                     builder: (ctx) => AlertDialog(
                       title: const Text("Logout?"),
                       content: const Text("Are you sure you want to logout?"),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                         ElevatedButton(
                           onPressed: () => Navigator.pop(ctx, true), 
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                           child: const Text("Logout")
                         )
                       ],
                     )
                   );

                   if (confirm == true) {
                      await ref.read(authRepositoryProvider).signOut();
                      if (mounted) context.go('/login');
                   }
                 }
               },
               itemBuilder: (BuildContext context) {
                 return [
                   const PopupMenuItem<String>(
                     value: 'logout',
                     child: Row(
                       children: [
                         Icon(Icons.logout, color: Colors.redAccent, size: 20),
                         SizedBox(width: 8),
                         Text("Logout", style: TextStyle(color: Colors.redAccent)),
                       ],
                     ),
                   ),
                 ];
               },
             )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
           if (snapshot.hasError) return Center(child: Text("Error loading profile"));
           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

           if (!snapshot.hasData || !snapshot.data!.exists) {
             return const Center(child: Text("User not found"));
           }

           final userData = snapshot.data!.data() as Map<String, dynamic>;
           final user = UserEntity.fromJson(userData);

           return SingleChildScrollView(
             child: Column(
               children: [
                 _buildProfileHeader(user),
                 _buildStatsRow(user),
                 const Divider(),
                 _buildContentTabs(),
               ],
             ),
           );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserEntity user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
           CircleAvatar(
             radius: 50,
             backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty 
                ? NetworkImage(user.photoUrl!) 
                : null,
             backgroundColor: Colors.white24,
             child: user.photoUrl == null || user.photoUrl!.isEmpty 
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
           ),
           const SizedBox(height: 16),
           Text(
             user.displayName ?? "Unknown User",
             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
           ),
           if (user.bio != null && user.bio!.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: Text(user.bio!, style: const TextStyle(color: Colors.white70)),
             ),
           const SizedBox(height: 16),
           
           if (_isMe)
             ElevatedButton.icon(
               onPressed: () => _showEditProfileDialog(user),
               icon: const Icon(Icons.edit, size: 16),
               label: const Text("Edit Profile"),
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.white,
                 foregroundColor: Colors.indigo,
                 shape: const StadiumBorder()
               )
             )
           else 
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 ElevatedButton(
                   onPressed: _toggleFollow,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: _isFollowing ? Colors.transparent : Colors.white,
                     foregroundColor: _isFollowing ? Colors.white : Colors.indigo,
                     elevation: _isFollowing ? 0 : 2,
                     shape: const StadiumBorder(),
                     side: _isFollowing ? const BorderSide(color: Colors.white) : null
                   ),
                   child: Text(_isFollowing ? "Following" : "Follow"),
                 ),
                 const SizedBox(width: 12),
                 OutlinedButton(
                   onPressed: (){ 
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat coming soon!")));
                   },
                   style: OutlinedButton.styleFrom(
                     foregroundColor: Colors.white,
                     side: const BorderSide(color: Colors.white70),
                     shape: const StadiumBorder()
                   ),
                   child: const Text("Chat"),
                 )
               ],
             )
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserEntity user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Followers", user.followersCount.toString()),
          _buildStatItem("Following", user.followingCount.toString()),
          _buildStatItem("Contests", user.contestsPlayed.toString()),
          _buildStatItem("Won", user.contestsWon.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildContentTabs() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text("Match History will appear here (Phase 9)", style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
