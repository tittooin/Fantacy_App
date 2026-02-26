import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/core/utils/share_utils.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'dart:convert';
import 'package:axevora11/features/rooms/presentation/widgets/scorecard_widget.dart';
import 'package:axevora11/features/rooms/presentation/widgets/commentary_widget.dart';
import 'package:axevora11/features/cricket_api/data/providers/scorecard_provider.dart';
import 'package:axevora11/features/rooms/presentation/widgets/leaderboard_widget.dart';
import 'package:axevora11/features/rooms/data/providers/room_leaderboard_provider.dart';

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

class _PrivateRoomScreenState extends ConsumerState<PrivateRoomScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  late TabController _tabController;

  bool _isRecording = false;
  bool _isVoiceChatEnabled = false;
  bool _isMuted = true;

  String get _chatPath => 'private_rooms/${widget.matchId}/messages';
  String get _membersPath => 'private_rooms/${widget.matchId}/members';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    _chatScrollController.dispose();
    _inputFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── HOST ONLY ──────────────────────────────────────────────────────────────
  void _showModerationMenu(String userName, String userId) {
    if (!widget.isHost) return; // Members cannot trigger this
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.skyBlue.withOpacity(0.2),
                child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                    style: const TextStyle(color: AppColors.skyBlue)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Member', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 24),
            _buildModOption(Icons.mic_off_rounded, 'Mute Member', Colors.white, () => Navigator.pop(ctx)),
            _buildModOption(Icons.person_remove_rounded, 'Remove from Room', AppColors.accentRed, () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection(_membersPath).doc(userId).delete();
            }),
            _buildModOption(Icons.report_problem_rounded, 'Report (Host Only)', Colors.orange, () => Navigator.pop(ctx)),
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

  // ── SEND MESSAGE ──────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userEntityProvider).value;
    if (user == null) {
      context.push('/login');
      return;
    }

    _textController.clear();
    try {
      await FirebaseFirestore.instance.collection(_chatPath).add({
        'uid': user.uid,
        'senderName': user.displayName ?? 'Member',
        'photoUrl': user.photoUrl ?? '',
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isVoice': false,
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);
    final isLoggedIn = userAsync.value != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStadiumSummaryCard(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatSection(isLoggedIn: isLoggedIn),
                _buildMembersSection(),
                _buildStatsSection(),
                _buildRulesSection(),
              ],
            ),
          ),
          if (_tabController.index == 0) _buildMessageInputBar(isLoggedIn: isLoggedIn),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.offWhite)),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'CHAT'),
          Tab(text: 'MEMBERS'),
          Tab(text: 'STATS'),
          Tab(text: 'RULES'),
        ],
        labelColor: AppColors.skyBlue,
        unselectedLabelColor: AppColors.textLight,
        indicatorColor: AppColors.skyBlue,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Consumer(builder: (context, ref, _) {
      final scorecardAsync = ref.watch(scorecardProvider(widget.matchId));
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: const [Tab(text: 'SCORECARD'), Tab(text: 'FEED')],
              labelColor: AppColors.skyBlue,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.skyBlue,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  scorecardAsync.when(
                    data: (data) => data != null ? ScorecardWidget(scorecardData: data) : const Center(child: Text('No data')),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                  scorecardAsync.when(
                    data: (data) {
                      final commentary = data?['scorecard']?['commentary'];
                      List list = [];
                      if (commentary != null) {
                        try {
                          if (commentary is String) {
                            list = jsonDecode(commentary);
                          } else {
                            list = commentary as List;
                          }
                        } catch (e) {
                          print("Commentary Parse Error: $e");
                        }
                      }
                      return CommentaryWidget(commentaryList: list);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar() {
    final roomName = widget.matchData?['roomName'] as String? ?? 'Private Room';
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('AXEVORA', style: GoogleFonts.oswald(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Text('LABS', style: GoogleFonts.oswald(color: AppColors.skyBlue, fontSize: 18, fontWeight: FontWeight.w900)),
          ]),
          Text(
            '$roomName • ${widget.isHost ? "Host" : "Member"}',
            style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        TextButton.icon(
          onPressed: () => context.push('/team-selection', extra: {'matchId': widget.matchId}),
          icon: const Icon(Icons.stars_rounded, color: AppColors.skyBlue, size: 18),
          label: Text('SET TEAM', style: GoogleFonts.oswald(color: AppColors.skyBlue, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStadiumSummaryCard() {
    final title = widget.matchData?['title'] ?? widget.matchData?['matchDesc'] ?? 'Live Match';
    final score = widget.matchData?['score'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.all(16),
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF0EB0E2), Color(0xFF0887AC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.accentRed, borderRadius: BorderRadius.circular(20)),
            child: Text('● LIVE', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.oswald(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (score.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(score, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          ],
        ]),
      ),
    );
  }

  Widget _buildChatSection({required bool isLoggedIn}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(_chatPath)
          .orderBy('timestamp', descending: false)
          .limitToLast(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.skyBlue));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: AppColors.textLight)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.forum_outlined, color: AppColors.glassWhite, size: 48),
              const SizedBox(height: 12),
              Text('No messages yet.\nStart the conversation!', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14)),
            ]),
          );
        }
        final currentUid = ref.read(userEntityProvider).value?.uid;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients && _chatScrollController.position.maxScrollExtent > 0) {
            _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
          }
        });
        return ListView.builder(
          controller: _chatScrollController,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildChatMessage(data, isMe: data['uid'] == currentUid);
          },
        );
      },
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> m, {required bool isMe}) {
    final senderName = m['senderName'] as String? ?? 'Member';
    final message = m['message'] as String? ?? '';
    final isVoice = m['isVoice'] == true;
    final photoUrl = m['photoUrl'] as String? ?? '';
    final uid = m['uid'] as String? ?? '';
    final timestamp = (m['timestamp'] as Timestamp?)?.toDate();
    final timeStr = timestamp != null ? '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            // Only host can trigger moderation — for members, tap does nothing
            onTap: widget.isHost && !isMe ? () => _showModerationMenu(senderName, uid) : null,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.offWhite,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty ? Text(senderName[0].toUpperCase()) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(senderName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(width: 8),
                  Text(timeStr, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                ]),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isVoice ? AppColors.lightBlueBackground : AppColors.offWhite,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: isVoice
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.play_circle_fill_rounded, color: AppColors.skyBlue),
                          const SizedBox(width: 8),
                          Text('Voice Note (Live)', style: GoogleFonts.inter(color: AppColors.skyBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                        ])
                      : Text(message, style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Consumer(builder: (context, ref, _) {
      final leaderboardAsync = ref.watch(roomLeaderboardProvider(widget.matchId));
      return Column(
        children: [
          // Mandatory Disclaimer — always visible above rankings
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCC00), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF856404), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⚠️ Rankings are for informational/discussion purposes only. No rewards are associated.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF856404),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: leaderboardAsync.when(
              data: (list) => LeaderboardWidget(leaderboard: list),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.skyBlue)),
              error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.inter(color: AppColors.textLight))),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRulesSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Room Rules', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _ruleItem('Be respectful to all members.'),
          _ruleItem('Friendly discussions only. No spam.'),
          _ruleItem('No sharing personal contact information.'),
          _ruleItem('Host decisions are final.'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.accentRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.accentRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This is a private room for friendly discussion only. No betting, gambling, or monetary activity is supported.',
                  style: GoogleFonts.inter(color: AppColors.accentRed, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14))),
      ]),
    );
  }

  Widget _buildMessageInputBar({required bool isLoggedIn}) {
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
              if (isLoggedIn)
                IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.skyBlue), onPressed: () {}),
              Expanded(
                child: isLoggedIn
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(24)),
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              _sendMessage();
                            }
                          },
                          child: TextField(
                            controller: _textController,
                            focusNode: _inputFocusNode,
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(24)),
                          alignment: Alignment.centerLeft,
                          child: Text('Login to join the conversation...', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14)),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              if (isLoggedIn)
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
                backgroundColor: isLoggedIn ? AppColors.skyBlue : AppColors.glassWhite,
                child: IconButton(
                  icon: Icon(Icons.send_rounded, color: isLoggedIn ? Colors.white : AppColors.textLight, size: 20),
                  onPressed: isLoggedIn ? _sendMessage : () => context.push('/login'),
                ),
              ),
            ],
          ),
          if (isLoggedIn) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Switch.adaptive(
                value: _isVoiceChatEnabled,
                activeColor: AppColors.skyBlue,
                onChanged: (v) => setState(() => _isVoiceChatEnabled = v),
              ),
              Text(
                _isVoiceChatEnabled ? 'Live Voice Active' : 'Start Live Voice Chat',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _isVoiceChatEnabled ? AppColors.skyBlue : AppColors.textLight),
              ),
              if (_isVoiceChatEnabled) ...[
                const SizedBox(width: 16),
                // Mic toggle — only available when voice chat is active
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: _isMuted ? AppColors.accentRed : Colors.green),
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                ),
              ],
            ]),
          ],
        ],
      ),
    );
  }
}
