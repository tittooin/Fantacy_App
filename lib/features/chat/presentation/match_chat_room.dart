import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/features/chat/data/chat_provider.dart';
import 'package:axevora11/features/chat/domain/chat_message_model.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MatchChatRoom extends ConsumerStatefulWidget {
  final String matchId;

  const MatchChatRoom({super.key, required this.matchId});

  @override
  ConsumerState<MatchChatRoom> createState() => _MatchChatRoomState();
}

class _MatchChatRoomState extends ConsumerState<MatchChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.initState();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatServiceProvider).sendMessage(widget.matchId, text);
    _messageController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.matchId));
    final currentUser = ref.watch(userEntityProvider).value;

    return Column(
      children: [
        // Chat List
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error loading messages: $err")),
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "No messages yet.\nStart the conversation!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.senderId == currentUser?.uid;
                  return _buildMessageBubble(message, isMe);
                },
              );
            },
          ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.vibrantBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: message.senderPhoto.isNotEmpty 
                  ? CachedNetworkImageProvider(message.senderPhoto) 
                  : null,
              child: message.senderPhoto.isEmpty 
                  ? Text(message.senderName[0], style: const TextStyle(fontSize: 12)) 
                  : null,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.senderName,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.vibrantBlue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: message.senderPhoto.isNotEmpty 
                  ? CachedNetworkImageProvider(message.senderPhoto) 
                  : null,
              child: message.senderPhoto.isEmpty 
                  ? Text(message.senderName[0], style: const TextStyle(fontSize: 12)) 
                  : null,
            ),
        ],
      ),
    );
  }
}
