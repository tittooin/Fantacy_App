import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/features/cricket_api/data/providers/match_provider.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:axevora11/core/utils/share_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedRoomTypeIndex = 0; // 0 for Global, 1 for Private
  int _selectedMatchTab = 0; // 0 for Live, 1 for Upcoming

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);
    final matchesAsync = ref.watch(matchListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(userAsync.value?.photoUrl),
      drawer: _buildDrawer(context, userAsync.value),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (allMatches) {
          final liveMatches = allMatches.where((m) => m['status'] == 'Live' || m['status'] == 'In Progress').toList();
          final featuredMatch = liveMatches.isNotEmpty ? liveMatches.first : (allMatches.isNotEmpty ? allMatches.first : null);

          return RefreshIndicator(
            onRefresh: () => ref.read(matchListProvider.notifier).fetchMatches(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  const SizedBox(height: 32),

                  // 4. Match Tabs (Live | Upcoming)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildMatchTabItem("LIVE / IN-PROGRESS", 0),
                        const SizedBox(width: 16),
                        _buildMatchTabItem("UPCOMING", 1),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildEventsList(allMatches),

                  const SizedBox(height: 32),

                  // 5. Your Private Rooms Section
                  _buildPrivateRoomsSection(),

                  const SizedBox(height: 100), // Bottom padding for nav
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final user = userAsync.value;
          if (user == null) {
            context.push('/login');
            return;
          }
          // Navigate to match selection for room creation
          if (matchesAsync.value?.isNotEmpty == true) {
            final featured = matchesAsync.value!.first;
            context.push('/match/${featured['id']}', extra: featured);
          }
        },
        backgroundColor: AppColors.skyBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Create Room', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String? photoUrl) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "AXEVORA",
                style: GoogleFonts.oswald(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "LABS",
                style: GoogleFonts.oswald(
                  color: AppColors.skyBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            "Social Interaction Platform",
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: AppColors.skyBlue),
          onPressed: () => ShareUtils.shareApp(context: context),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Stay tuned! 🔔 Personalized alerts and real-time updates are coming soon in the next major release."),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.skyBlue,
                  )
                );
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle),
                child: const Text("0", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: GestureDetector(
            onTap: () {
              final uid = ref.read(authUserIdProvider);
              if (uid != null) context.push('/profile/$uid');
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.glassWhite,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? const Icon(Icons.person, size: 20, color: AppColors.textLight) : null,
            ),
          ),
        ),
      ],
    );
  }

  /// ── HAMBURGER DRAWER ──────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, dynamic user) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ─── Profile Header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0EB0E2), Color(0xFF0887AC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 28)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'Social Member',
                    style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // ─── Browse Categories ──────────────────────────────────
                    _drawerSectionHeader("Browse Categories"),
                    _drawerItem(
                      icon: Icons.sports_cricket_rounded,
                      label: "Cricket",
                      badge: "LIVE",
                      badgeColor: AppColors.accentRed,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/home');
                      },
                    ),
                    _drawerItem(
                      icon: Icons.waving_hand_rounded,
                      label: "Casual Interaction",
                      badge: "Soon",
                      badgeColor: Colors.grey,
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      icon: Icons.people_alt_rounded,
                      label: "Mingle",
                      badge: "Soon",
                      badgeColor: Colors.grey,
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      icon: Icons.handshake_rounded,
                      label: "Friendship Hub",
                      badge: "Soon",
                      badgeColor: Colors.grey,
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      icon: Icons.computer_rounded,
                      label: "Tech Labs",
                      badge: "Soon",
                      badgeColor: Colors.grey,
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      icon: Icons.luggage_rounded,
                      label: "Traveling Chat",
                      badge: "Soon",
                      badgeColor: Colors.grey,
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      icon: Icons.favorite_border_rounded,
                      label: "Dating",
                      badge: "Soon",
                      badgeColor: Colors.grey,
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      icon: Icons.volunteer_activism_rounded,
                      label: "Lovers Point",
                      badge: "Soon",
                      badgeColor: Colors.grey,
                      onTap: () => Navigator.pop(context),
                    ),

                    const Divider(height: 24, indent: 20, endIndent: 20),

                    // ─── My Social Activity ────────────────────────────────
                    _drawerSectionHeader("My Rooms"),
                    _drawerItem(
                      icon: Icons.forum_rounded,
                      label: "My Joined Lounges",
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/my-matches');
                      },
                    ),
                    _drawerItem(
                      icon: Icons.public_rounded,
                      label: "Global Discussion (Cricket)",
                      onTap: () {
                        Navigator.pop(context);
                        final allMatches = ref.read(matchListProvider).value ?? [];
                        Map<String, dynamic>? liveMatch;
                        try {
                          liveMatch = allMatches.firstWhere(
                            (m) => m['status'] == 'Live' || m['status'] == 'In Progress',
                          );
                        } catch (_) {
                          liveMatch = allMatches.isNotEmpty ? allMatches.first : null;
                        }
                        if (liveMatch != null && liveMatch['id'] != null) {
                          context.push('/room/${liveMatch['id']}', extra: liveMatch);
                        }
                      },
                    ),

                    const Divider(height: 24, indent: 20, endIndent: 20),

                    // ─── Account & Profile ─────────────────────────────────
                    _drawerSectionHeader("Account"),
                    _drawerItem(
                      icon: Icons.person_outline_rounded,
                      label: "My Profile",
                      onTap: () {
                        Navigator.pop(context);
                        if (user?.uid != null) {
                          context.push('/profile/${user.uid}');
                        }
                      },
                    ),
                    _drawerItem(
                      icon: Icons.download_rounded,
                      label: "Download Android APK",
                      onTap: () {
                        Navigator.pop(context);
                        launchUrl(
                          Uri.parse("https://axevoralabs.com/downloads/axevoralabs.apk"),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),

                    const Divider(height: 24, indent: 20, endIndent: 20),

                    // ─── Legal & Info ──────────────────────────────────────
                    _drawerSectionHeader("Legal & Info"),
                    _drawerItem(
                      icon: Icons.shield_outlined,
                      label: "Privacy Policy",
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/privacy-policy');
                      },
                    ),
                    _drawerItem(
                      icon: Icons.description_outlined,
                      label: "Terms & Conditions",
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/terms-and-conditions');
                      },
                    ),
                    _drawerItem(
                      icon: Icons.groups_outlined,
                      label: "Community Guidelines",
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/social-safety');
                      },
                    ),
                    _drawerItem(
                      icon: Icons.help_outline_rounded,
                      label: "FAQ",
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/faq');
                      },
                    ),
                    _drawerItem(
                      icon: Icons.mail_outline_rounded,
                      label: "Contact Us",
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/contact');
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ─── Footer disclaimer ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.lightBlueBackground,
                border: Border(top: BorderSide(color: AppColors.skyBlue.withOpacity(0.15))),
              ),
              child: Text(
                "Social interaction only.\nNo betting or cash rewards.",
                style: GoogleFonts.inter(
                  color: AppColors.textLight,
                  fontSize: 11,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppColors.textLight,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.skyBlue, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.skyBlue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    color: badgeColor ?? AppColors.skyBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }





  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text("See All", style: GoogleFonts.inter(color: AppColors.skyBlue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildMatchTabItem(String label, int index) {
    final isSelected = _selectedMatchTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMatchTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.skyBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.skyBlue : Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isSelected ? AppColors.skyBlue : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Map<String, dynamic>> allMatches) {
    // Filter based on selected tab
    final displayMatches = allMatches.where((m) {
      final status = (m['status'] ?? '').toString().toLowerCase();
      final isLive = status == 'live' || status == 'in progress';
      
      if (_selectedMatchTab == 0) {
        return isLive;
      } else {
        return status == 'upcoming' || (!isLive && status != 'completed' && status != 'finished');
      }
    }).toList();

    // Sort: Soonest first
    displayMatches.sort((a, b) {
      final aStart = int.tryParse(a['startDate']?.toString() ?? '0') ?? 0;
      final bStart = int.tryParse(b['startDate']?.toString() ?? '0') ?? 0;
      return aStart.compareTo(bStart);
    });

    final finalMatches = displayMatches.take(15).toList();

    if (finalMatches.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_cricket_outlined, size: 40, color: AppColors.textLight.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                _selectedMatchTab == 0 ? "No matches live currently" : "No upcoming matches found",
                style: GoogleFonts.inter(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20),
        scrollDirection: Axis.horizontal,
        itemCount: finalMatches.length,
        itemBuilder: (context, index) {
          final match = finalMatches[index];
          final matchId = match['id']?.toString() ?? 'match_$index';
          
          // Use normalized team names from match_provider (team1ShortName, team2ShortName)
          final team1 = (match['team1ShortName'] ?? match['teamA'] ?? 'TBA').toString();
          final team2 = (match['team2ShortName'] ?? match['teamB'] ?? 'TBA').toString();
          
          final status = (match['status'] ?? 'Upcoming').toString();
          final isLive = status.toLowerCase() == 'live' || status.toLowerCase() == 'in progress';
          final series = (match['seriesName'] ?? 'Cricket Series').toString();
          final flagA = match['teamAImg'] ?? '';
          final flagB = match['teamBImg'] ?? '';

          return GestureDetector(
            onTap: () {
              context.push('/match/$matchId', extra: match);
            },
            child: Container(
              width: 170, // Increased width slightly
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassWhite),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLive 
                            ? [AppColors.accentRed.withOpacity(0.1), AppColors.accentRed.withOpacity(0.02)]
                            : [AppColors.skyBlue.withOpacity(0.05), AppColors.skyBlue.withOpacity(0.01)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(child: Text(team1, style: GoogleFonts.oswald(fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text("vs", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ),
                                  Flexible(child: Text(team2, style: GoogleFonts.oswald(fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isLive ? AppColors.accentRed : AppColors.skyBlue).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isLive ? '• LIVE' : 'UPCOMING',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isLive ? AppColors.accentRed : AppColors.skyBlue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$team1 vs $team2",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          series,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isLive && match['score'] != null && match['score'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.skyBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
                            ),
                            child: Text(
                              match['score'].toString(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.skyBlue,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildPrivateRoomsSection() {
    final user = ref.read(userEntityProvider).value;
    if (user == null) {
      // Guest: show CTA to login
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social Lounges', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.lightBlueBackground, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                const Icon(Icons.lock_outline_rounded, color: AppColors.skyBlue, size: 32),
                const SizedBox(height: 8),
                Text('Login to participate in private social lounges', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textDark)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue, foregroundColor: Colors.white),
                  child: const Text('Sign In'),
                ),
              ]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSectionHeader(
          "Active Social Lounges",
          onSeeAll: () {
            // Already in shell, /my-matches is the list view
            context.go('/my-matches');
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_rooms')
              .where('members', arrayContains: user.uid)
              .orderBy('updatedAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.glassWhite)),
                  child: Column(children: [
                    const Icon(Icons.forum_outlined, color: AppColors.glassWhite, size: 32),
                    const SizedBox(height: 8),
                    Text("You haven't joined any rooms yet.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textLight)),
                    const SizedBox(height: 8),
                    Text('Tap a match above to enter the Global Room!', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
                  ]),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['roomName'] as String? ?? 'Social Lounge';
                final matchTitle = data['matchTitle'] as String? ?? 'Match';
                final members = (data['members'] as List?)?.length ?? 0;
                final isLocked = data['isPrivate'] == true;
                return _buildPrivateRoomItem(
                  title, matchTitle, '$members Members', isLocked, doc.id,
                  data: data,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrivateRoomItem(String title, String subtitle, String members, bool isLocked, String matchId, {Map<String, dynamic>? data}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassWhite),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightBlueBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLocked ? Icons.lock_person_rounded : Icons.forum_rounded,
              color: AppColors.skyBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textDark)),
                Text("$subtitle • $members", style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.push('/match/$matchId');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocked ? AppColors.glassWhite : AppColors.skyBlue,
              foregroundColor: isLocked ? AppColors.textLight : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              children: [
                if (!isLocked) const Icon(Icons.check_circle, size: 14, color: Colors.white),
                if (!isLocked) const SizedBox(width: 4),
                Text(isLocked ? "Locked" : "Enter", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return const SizedBox.shrink();
  }
}
