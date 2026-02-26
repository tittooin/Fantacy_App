import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
                  // 1. Featured Live Match Card
                  if (featuredMatch != null)
                    _buildFeaturedMatchCard(featuredMatch),

                  const SizedBox(height: 24),

                  // 2. Section Title: Live Matches
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Live Matches",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Room Type Buttons
                  _buildRoomTypeToggle(),

                  const SizedBox(height: 32),

                  // 4. Today's Live Events (Categories)
                  _buildSectionHeader("Today's Live Events", onSeeAll: () {}),
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
        onPressed: () {},
        backgroundColor: AppColors.skyBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Create Room", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
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
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle),
                child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.glassWhite,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 20, color: AppColors.textLight) : null,
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
                    backgroundImage: (user?.photoUrl != null)
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: (user?.photoUrl == null)
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
                        // Navigate to global room of first live match
                        final matches = ref.read(matchListProvider).value;
                        final liveMatch = matches?.firstWhere(
                          (m) => m['status'] == 'Live' || m['status'] == 'In Progress',
                          orElse: () => matches?.isNotEmpty == true ? matches!.first : {},
                        );
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
                          context.push('/profile/${user!.uid}');
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

  Widget _buildFeaturedMatchCard(Map<String, dynamic> match) {
    final teamA = match['team1ShortName'] ?? 'IND';
    final teamB = match['team2ShortName'] ?? 'PAK';
    final score = match['score'] ?? '178/6 (18.2)';
    final isLive = match['status'] == 'Live' || match['status'] == 'In Progress';

    return Container(
      margin: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: CachedNetworkImageProvider("https://img.freepik.com/free-vector/empty-cricket-stadium-background_1284-48419.jpg"),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // Glass Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isLive)
                      _buildBadge("• LIVE", AppColors.accentRed)
                    else
                      _buildBadge("UPCOMING", AppColors.skyBlue),
                    Text(
                      "25,638 Online",
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeaturedTeam(teamA, "https://flagsapi.com/IN/flat/64.png"),
                        Text("vs", style: GoogleFonts.oswald(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
                        _buildFeaturedTeam(teamB, "https://flagsapi.com/PK/flat/64.png"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      score,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/match/${match['id']}/create-room', extra: match);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Join Social Hubs", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFeaturedTeam(String name, String flagUrl) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: flagUrl,
          width: 48,
          height: 32,
          placeholder: (context, url) => const SizedBox(width: 48, height: 32),
        ),
        const SizedBox(height: 4),
        Text(name, style: GoogleFonts.oswald(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRoomTypeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildToggleItem(0, "Global Room", null),
          const SizedBox(width: 12),
          _buildToggleItem(1, "Private Rooms", Icons.lock_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildToggleItem(int index, String label, IconData? icon) {
    final isSelected = _selectedRoomTypeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoomTypeIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.skyBlue : AppColors.glassWhite,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textLight), const SizedBox(width: 6)],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textLight,
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

  Widget _buildEventsList(List<Map<String, dynamic>> allMatches) {
    // Use real matches, cap at 6. Fallback to 1 placeholder if empty.
    final displayMatches = allMatches.isNotEmpty
        ? allMatches.take(6).toList()
        : [<String, dynamic>{'id': 'demo_1', 'team1ShortName': 'IND', 'team2ShortName': 'PAK', 'status': 'Live', 'seriesName': 'Cricket'}];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20),
        scrollDirection: Axis.horizontal,
        itemCount: displayMatches.length,
        itemBuilder: (context, index) {
          final match = displayMatches[index];
          final matchId = match['id']?.toString() ?? 'demo_$index';
          final team1 = match['team1ShortName'] ?? match['teamA'] ?? 'TBA';
          final team2 = match['team2ShortName'] ?? match['teamB'] ?? 'TBA';
          final status = match['status'] ?? 'Upcoming';
          final isLive = status == 'Live' || status == 'In Progress';
          final series = match['seriesName'] ?? match['series_name'] ?? 'Cricket';

          return GestureDetector(
            onTap: () {
              context.push('/match/$matchId/create-room', extra: match);
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassWhite),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      height: 80,
                      width: double.infinity,
                      color: isLive
                          ? AppColors.accentRed.withOpacity(0.08)
                          : AppColors.glassWhite,
                      child: Center(
                        child: Icon(
                          Icons.sports_cricket_rounded,
                          size: 40,
                          color: isLive
                              ? AppColors.accentRed.withOpacity(0.6)
                              : AppColors.skyBlue.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBadge(
                          isLive ? '• LIVE' : status.toUpperCase(),
                          isLive ? AppColors.accentRed : AppColors.skyBlue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          series,
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$team1 vs $team2',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
    return Column(
      children: [
        _buildSectionHeader("Active Social Lounges", onSeeAll: () {
          context.go('/my-matches');
        }),
        _buildPrivateRoomItem("Friends Lounge", "IND vs PAK", "6 Online", false, "match_123"),
        _buildPrivateRoomItem("Cricket Fanatics", "Private", "11 Members", true, "match_456"),
      ],
    );
  }

  Widget _buildPrivateRoomItem(String title, String subtitle, String members, bool isLocked, String matchId) {
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
              context.push('/match/$matchId/create-room');
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
