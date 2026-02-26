import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/core/utils/share_utils.dart';
import 'dart:convert';
import 'package:axevora11/features/rooms/presentation/widgets/scorecard_widget.dart';
import 'package:axevora11/features/rooms/presentation/widgets/commentary_widget.dart';
import 'package:axevora11/features/cricket_api/data/providers/scorecard_provider.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

class GlobalRoomScreen extends ConsumerStatefulWidget {
  final String matchId;
  final Map<String, dynamic>? matchData;

  const GlobalRoomScreen({
    super.key,
    required this.matchId,
    this.matchData,
  });

  @override
  ConsumerState<GlobalRoomScreen> createState() => _GlobalRoomScreenState();
}

class _GlobalRoomScreenState extends ConsumerState<GlobalRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isRecording = false;
  bool _isVoiceChatEnabled = false;
  bool _showEmojiPicker = false;

  String get _chatPath => 'global_rooms/${widget.matchId}/messages';

  @override
  void dispose() {
    _textController.dispose();
    _chatScrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _applyFormatting(String prefix, String suffix) {
    final text = _textController.text;
    final selection = _textController.selection;
    if (selection.start == -1) return;
    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length + suffix.length),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userEntityProvider).value;
    if (user == null) {
      // Guest — redirect to login
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

      // Scroll to bottom after send
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
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);
    final isLoggedIn = userAsync.value != null;

    return PopScope(
      onPopInvoked: (_) => setState(() => _showEmojiPicker = false),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildEventSummaryCard(),
            Expanded(child: _buildChatFeed()),
            _buildPrivacyDisclaimer(),
            _buildMessageInputBar(isLoggedIn: isLoggedIn),
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _textController.text = _textController.text + emoji.emoji;
                  },
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: Colors.white,
                      columns: 7,
                      emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
                    ),
                    categoryViewConfig: const CategoryViewConfig(
                      backgroundColor: Colors.white,
                      indicatorColor: AppColors.skyBlue,
                      iconColorSelected: AppColors.skyBlue,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = ref.read(userEntityProvider).value;
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('AXEVORA', style: GoogleFonts.oswald(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(width: 4),
              Text('LABS', style: GoogleFonts.oswald(color: AppColors.skyBlue, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('GLOBAL ROOM • Live', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.home_rounded, color: AppColors.skyBlue),
          onPressed: () => context.go('/home'),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: AppColors.skyBlue),
          onPressed: () => ShareUtils.shareMatchRoom(context: context, matchId: widget.matchId, matchTitle: widget.matchData?['title'] ?? 'Live Match'),
        ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push('/profile/${user.uid}'),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.glassWhite,
                backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) ? NetworkImage(user.photoUrl!) : null,
                child: (user.photoUrl == null || user.photoUrl!.isEmpty) ? const Icon(Icons.person, size: 16, color: AppColors.skyBlue) : null,
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.login_rounded, color: AppColors.skyBlue),
            onPressed: () => context.push('/login'),
          ),
      ],
    );
  }

  Widget _buildEventSummaryCard() {
    final title = widget.matchData?['title'] ?? widget.matchData?['matchDesc'] ?? 'Live Match';
    final score = widget.matchData?['score'] ?? '';

    return Consumer(builder: (context, ref, _) {
      final scorecardAsync = ref.watch(scorecardProvider(widget.matchId));

      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.skyBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: AppColors.skyBlue.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            iconColor: AppColors.skyBlue,
            collapsedIconColor: AppColors.skyBlue,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.oswald(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('LIVE SCORECARD', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (score.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.skyBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(score, style: GoogleFonts.inter(color: AppColors.skyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            children: [
              Container(
                height: 400, // Fixed height for expansion
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.offWhite))),
                child: DefaultTabController(
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
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildChatFeed() {
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
          return Center(child: Text('Error loading messages', style: GoogleFonts.inter(color: AppColors.textLight)));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.glassWhite, size: 48),
                const SizedBox(height: 12),
                Text('No messages yet.\nBe the first to say something!', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14)),
              ],
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMe = data['uid'] == currentUid;
            return _buildChatMessage(data, isMe);
          },
        );
      },
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> m, bool isMe) {
    final senderName = m['senderName'] as String? ?? 'Member';
    final message = m['message'] as String? ?? '';
    final isVoice = m['isVoice'] == true;
    final photoUrl = m['photoUrl'] as String? ?? '';
    final timestamp = (m['timestamp'] as Timestamp?)?.toDate();
    final timeStr = timestamp != null ? '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.glassWhite,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty ? Text(senderName[0].toUpperCase()) : null,
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(senderName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    Text(timeStr, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isVoice ? AppColors.lightBlueBackground : (isMe ? AppColors.skyBlue : AppColors.offWhite),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
                    ),
                  ),
                  child: isVoice
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.play_circle_fill_rounded, color: AppColors.skyBlue),
                          const SizedBox(width: 8),
                          Text('Voice Note (Live)', style: GoogleFonts.inter(color: AppColors.skyBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                        ])
                      : Text(message, style: GoogleFonts.inter(color: isMe ? Colors.white : AppColors.textDark, fontSize: 14)),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.skyBlue.withOpacity(0.1),
              child: const Icon(Icons.person, size: 16, color: AppColors.skyBlue),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.offWhite,
      child: Text(
        'Voice interactions are live and not stored. Social discussion only.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold),
      ),
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
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFormatButton(Icons.format_bold_rounded, () => _applyFormatting('**', '**')),
                  _buildFormatButton(Icons.format_italic_rounded, () => _applyFormatting('_', '_')),
                  _buildFormatButton(Icons.format_underlined_rounded, () => _applyFormatting('__', '__')),
                ],
              ),
            ),
          Row(
            children: [
              if (isLoggedIn)
                IconButton(
                  icon: Icon(_showEmojiPicker ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined, color: AppColors.skyBlue),
                  onPressed: () {
                    setState(() => _showEmojiPicker = !_showEmojiPicker);
                    if (_showEmojiPicker) {
                      FocusScope.of(context).unfocus();
                    } else {
                      _inputFocusNode.requestFocus();
                    }
                  },
                ),
              Expanded(
                child: isLoggedIn
                    ? Container(
                        constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.glassWhite),
                        ),
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
              if (isLoggedIn) ...[
                GestureDetector(
                  onLongPressStart: (_) => setState(() => _isRecording = true),
                  onLongPressEnd: (_) async {
                    setState(() => _isRecording = false);
                    final user = ref.read(userEntityProvider).value;
                    if (user != null) {
                      // Send Mock Voice Note for interaction feedback
                      await FirebaseFirestore.instance.collection(_chatPath).add({
                        'uid': user.uid,
                        'senderName': user.displayName ?? 'Member',
                        'photoUrl': user.photoUrl ?? '',
                        'message': 'Voice Note (Live)',
                        'timestamp': FieldValue.serverTimestamp(),
                        'isVoice': true,
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.accentRed : AppColors.glassWhite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_isRecording ? Icons.mic : Icons.mic_none_rounded, color: _isRecording ? Colors.white : AppColors.skyBlue),
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch.adaptive(
                  value: _isVoiceChatEnabled,
                  activeColor: AppColors.skyBlue,
                  onChanged: (v) => setState(() => _isVoiceChatEnabled = v),
                ),
                Text(
                  _isVoiceChatEnabled ? 'Live Voice Discussion Active' : 'Enable Live Voice Discussion',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _isVoiceChatEnabled ? AppColors.skyBlue : AppColors.textLight),
                ),
                if (_isVoiceChatEnabled) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.record_voice_over_rounded, size: 16, color: AppColors.skyBlue),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textLight, size: 20),
        onPressed: onTap,
        style: IconButton.styleFrom(backgroundColor: AppColors.offWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    );
  }
}
