import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/core/utils/share_utils.dart';

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
  bool _isRecording = false;
  bool _isVoiceChatEnabled = false;

  @override
  void dispose() {
    _textController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _applyFormatting(String prefix, String suffix) {
    final text = _textController.text;
    final selection = _textController.selection;
    if (selection.start == -1) return;

    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(selection.start, selection.end, "$prefix$selectedText$suffix");
    
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length + suffix.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. Live Event Summary Card
          _buildEventSummaryCard(),

          // 2. Chat Feed
          Expanded(child: _buildChatFeed()),

          // 3. Privacy Disclaimer
          _buildPrivacyDisclaimer(),

          // 4. Advanced Message Input Bar
          _buildMessageInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                "GLOBAL ROOM • 12.4K Active",
                style: GoogleFonts.inter(
                  color: AppColors.textLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: AppColors.skyBlue),
          onPressed: () {
            ShareUtils.shareMatchRoom(
              matchId: widget.matchId,
              matchTitle: widget.matchData?['title'] ?? "India vs Pakistan",
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=me"),
          ),
        ),
      ],
    );
  }

  Widget _buildEventSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.socialGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.skyBlue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.matchData?['title'] ?? "INDIA vs PAKISTAN",
                style: GoogleFonts.oswald(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "T20 World Cup Group Stage",
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(
              "IND 178/6 (18.2)",
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatFeed() {
    final List<Map<String, String>> mockMessages = [
      {"user": "Abhi", "msg": "Hardik will smash a six in the last over! 🇮🇳💪", "time": "2:54 PM"},
      {"user": "Samira", "msg": "I agree! Pakistan will have a tough chase now. 🇵🇰💚", "time": "2:54 PM"},
      {"user": "Vaibhav", "msg": "What an awesome match! This room is buzzing. 😍🙌", "time": "2:56 PM"},
      {"user": "Sourav", "msg": "Voice Note (Live) 🎙️", "isVoice": "true", "time": "2:57 PM"},
    ];

    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mockMessages.length,
      itemBuilder: (context, index) {
        final m = mockMessages[index];
        final isMe = m['user'] == "Vaibhav";
        return _buildChatMessage(m, isMe);
      },
    );
  }

  Widget _buildChatMessage(Map<String, String> m, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(radius: 16, backgroundColor: AppColors.glassWhite, child: Text(m['user']![0])),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m['user']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    Text(m['time']!, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: m['isVoice'] == "true" ? AppColors.lightBlueBackground : (isMe ? AppColors.skyBlue : AppColors.offWhite),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
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
                    : Text(
                        m['msg']!,
                        style: GoogleFonts.inter(color: isMe ? Colors.white : AppColors.textDark, fontSize: 14),
                      ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(radius: 16, backgroundColor: AppColors.skyBlue.withOpacity(0.1), child: const Text("V", style: TextStyle(color: AppColors.skyBlue))),
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
        "Voice interactions are live and not stored. This room is for social discussion only.",
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold),
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
          // Custom Rich Text Toolbar
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFormatButton(Icons.format_bold_rounded, () => _applyFormatting("**", "**")),
                _buildFormatButton(Icons.format_italic_rounded, () => _applyFormatting("_", "_")),
                _buildFormatButton(Icons.format_underlined_rounded, () => _applyFormatting("__", "__")),
              ],
            ),
          ),
          Row(
            children: [
              // Emoji Button
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.skyBlue),
                onPressed: () {},
              ),
              // Main Input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.glassWhite),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Voice Note Button
              GestureDetector(
                onLongPressStart: (_) => setState(() => _isRecording = true),
                onLongPressEnd: (_) => setState(() => _isRecording = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.accentRed : AppColors.glassWhite,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none_rounded,
                    color: _isRecording ? Colors.white : AppColors.skyBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send Button
              CircleAvatar(
                backgroundColor: AppColors.skyBlue,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    _textController.clear();
                    _chatScrollController.animateTo(
                      _chatScrollController.position.maxScrollExtent + 100,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Live Voice Chat Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Switch.adaptive(
                value: _isVoiceChatEnabled,
                activeColor: AppColors.skyBlue,
                onChanged: (v) => setState(() => _isVoiceChatEnabled = v),
              ),
              Text(
                _isVoiceChatEnabled ? "Live Voice Discussion Active" : "Enable Live Voice Discussion",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _isVoiceChatEnabled ? AppColors.skyBlue : AppColors.textLight),
              ),
              if (_isVoiceChatEnabled) ...[
                const SizedBox(width: 8),
                const Icon(Icons.record_voice_over_rounded, size: 16, color: AppColors.skyBlue),
              ]
            ],
          )
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
        style: IconButton.styleFrom(
          backgroundColor: AppColors.offWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
