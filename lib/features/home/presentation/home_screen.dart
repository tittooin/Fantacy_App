import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
      drawer: const Drawer(), // Placeholder for hamburger menu
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
                      context.push('/room/${match['id']}', extra: match);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Join Match Rooms", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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

  Widget _buildEventsList(List<Map<String, dynamic>> matches) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 4, // 4 Example categories
        itemBuilder: (context, index) {
          final categories = ["Cricket", "Football", "Gaming", "Music"];
          final titles = ["IND vs PAK", "MUN vs CHE", "BGMI Finals", "Live Concert"];
          final icons = [Icons.sports_cricket, Icons.sports_soccer, Icons.videogame_asset, Icons.music_note];
          final status = [ "• LIVE", "UPCOMING", "UPCOMING", "COMING SOON"];
          final statusColor = [AppColors.accentRed, AppColors.skyBlue, AppColors.skyBlue, AppColors.textLight];

          return Container(
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
                    color: AppColors.glassWhite,
                    child: Icon(icons[index], size: 40, color: AppColors.skyBlue.withOpacity(0.5)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBadge(status[index], statusColor[index]),
                      const SizedBox(height: 8),
                      Text(
                        categories[index],
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        titles[index],
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivateRoomsSection() {
    return Column(
      children: [
        _buildSectionHeader("Your Private Rooms", onSeeAll: () {}),
        _buildPrivateRoomItem("Friends Lounge", "IND vs PAK", "6 Members", false),
        _buildPrivateRoomItem("Team Warriors", "Private", "11 Members", true),
      ],
    );
  }

  Widget _buildPrivateRoomItem(String title, String subtitle, String members, bool isLocked) {
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
            onPressed: () {},
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: AppColors.glassWhite),
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, "Home", true),
              _buildNavItem(Icons.calendar_month_rounded, "Events", false),
              _buildNavItem(Icons.groups_rounded, "Rooms", false),
              _buildNavItem(Icons.chat_bubble_rounded, "Chat", false),
              _buildNavItem(Icons.person_rounded, "Profile", false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? AppColors.skyBlue : AppColors.textLight, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isSelected ? AppColors.skyBlue : AppColors.textLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
