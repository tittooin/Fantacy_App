import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/core/utils/share_utils.dart';

class PrivateRoomScreen extends ConsumerStatefulWidget {
  final String matchId;
  final Map<String, dynamic>? matchData;
  final bool isHost;

  const PrivateRoomScreen({
    super.key,
    required this.matchId,
    this.matchData,
    this.isHost = false,
  });

  @override
  ConsumerState<PrivateRoomScreen> createState() => _PrivateRoomScreenState();
}

class _PrivateRoomScreenState extends ConsumerState<PrivateRoomScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  late TabController _tabController;
  
  bool _isRecording = false;
  bool _isVoiceChatEnabled = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _chatScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showModerationMenu(String userName, String userId) {
    if (!widget.isHost) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.skyBlue.withOpacity(0.2),
                  child: Text(userName[0], style: const TextStyle(color: AppColors.skyBlue)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Member", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildModOption(Icons.mic_off_rounded, "Mute Member", Colors.white, () => Navigator.pop(context)),
            _buildModOption(Icons.person_remove_rounded, "Remove from Room", AppColors.accentRed, () => Navigator.pop(context)),
            _buildModOption(Icons.report_problem_rounded, "Report (Host Only)", Colors.orange, () => Navigator.pop(context)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. Stadium Summary Card
          _buildStadiumSummaryCard(),

          // 2. Tabs
          _buildTabBar(),

          // 3. Main Content (Chat / Members / Rules)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatSection(),
                _buildMembersSection(),
                _buildRulesSection(),
              ],
            ),
          ),

          // 4. Input Area
          if (_tabController.index == 0) _buildMessageInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: const Icon(Icons.lock_outline_rounded, color: AppColors.skyBlue, size: 20),
      title: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("AXEVORA", style: GoogleFonts.oswald(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text("LABS", style: GoogleFonts.oswald(color: AppColors.skyBlue, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          Text(
            "Friends Lounge (Private Room)",
            style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        _buildMemberAvatars(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMemberAvatars() {
    return SizedBox(
      width: 80,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned(right: 0, child: _avatarCircle("A")),
          Positioned(right: 15, child: _avatarCircle("B")),
          Positioned(right: 30, child: _avatarCircle("C")),
          Positioned(
            right: 45,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
              child: Text("+3", style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarCircle(String char) {
    return GestureDetector(
      onTap: () => _showModerationMenu("Member $char", "id_$char"),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), shape: BoxShape.circle),
        child: CircleAvatar(radius: 12, backgroundColor: AppColors.skyBlue.withOpacity(0.2), child: Text(char, style: const TextStyle(fontSize: 10, color: AppColors.skyBlue))),
      ),
    );
  }

  Widget _buildStadiumSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=1000&auto=format&fit=crop"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.accentRed, borderRadius: BorderRadius.circular(20)),
            child: Text("● LIVE", style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.matchData?['title'] ?? "INDIA vs PAKISTAN",
            style: GoogleFonts.oswald(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "India 178/6 (18.2) | Target 182",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.skyBlue,
      unselectedLabelColor: AppColors.textLight,
      indicatorColor: AppColors.skyBlue,
      onTap: (index) => setState(() {}),
      tabs: const [
        Tab(text: "Stats"),
        Tab(text: "Members"),
        Tab(text: "Rules"),
      ],
    );
  }

  Widget _buildChatSection() {
    final mockMessages = [
      {"user": "Abhi", "msg": "Hardik is on fire!! 🇮🇳🔥", "time": "2:45 PM"},
      {"user": "Priya", "msg": "This game is so close! Pakistan needs 45 in 3 overs.", "time": "2:47 PM"},
      {"user": "Samira", "msg": "Join the voice chat guys!", "time": "2:50 PM"},
      {"user": "Vaibhav", "msg": "Voice Note (Live) 🎙️", "isVoice": "true", "time": "2:52 PM"},
    ];

    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: mockMessages.length,
      itemBuilder: (context, index) {
        final m = mockMessages[index];
        return _buildChatMessage(m);
      },
    );
  }

  Widget _buildChatMessage(Map<String, String> m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showModerationMenu(m['user']!, "id_123"),
            child: CircleAvatar(radius: 18, backgroundColor: AppColors.offWhite, child: Text(m['user']![0])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(m['user']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(width: 8),
                    Text(m['time']!, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: m['isVoice'] == "true" ? AppColors.lightBlueBackground : AppColors.offWhite,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: m['isVoice'] == "true"
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_fill_rounded, color: AppColors.skyBlue),
                            const SizedBox(width: 8),
                            Text("Voice Note (Live)", style: GoogleFonts.inter(color: AppColors.skyBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Text(m['msg']!, style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _memberTile("Pankaj (Host)", isHost: true),
        _memberTile("Abhi"),
        _memberTile("Samira"),
        _memberTile("Vaibhav"),
        _memberTile("Priya"),
      ],
    );
  }

  Widget _memberTile(String name, {bool isHost = false}) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: AppColors.offWhite, child: Text(name[0])),
      title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      subtitle: Text(isHost ? "Room Owner" : "Friend"),
      trailing: isHost 
          ? const Icon(Icons.star_rounded, color: Colors.amber)
          : (widget.isHost ? IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () => _showModerationMenu(name, "id")) : null),
    );
  }

  Widget _buildRulesSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Room Rules", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _ruleItem("Be respectful to all members."),
          _ruleItem("Friendly discussions only."),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.accentRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.accentRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "This is a private room for friendly discussion only. No betting, gambling, or monetary activity is supported.",
                    style: GoogleFonts.inter(color: AppColors.accentRed, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMessageInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.skyBlue), onPressed: () {}),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onLongPressStart: (_) => setState(() => _isRecording = true),
                onLongPressEnd: (_) => setState(() => _isRecording = false),
                child: CircleAvatar(
                  backgroundColor: _isRecording ? AppColors.accentRed : AppColors.glassWhite,
                  child: Icon(_isRecording ? Icons.mic : Icons.mic_none_rounded, color: _isRecording ? Colors.white : AppColors.skyBlue),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.skyBlue,
                child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: () {}),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Switch.adaptive(
                value: _isVoiceChatEnabled,
                onChanged: (v) => setState(() => _isVoiceChatEnabled = v),
              ),
              Text(
                _isVoiceChatEnabled ? "Live Voice Active" : "Start Live Voice Chat",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _isVoiceChatEnabled ? AppColors.skyBlue : AppColors.textLight),
              ),
              if (_isVoiceChatEnabled) ...[
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: _isMuted ? AppColors.accentRed : Colors.green),
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }
}
