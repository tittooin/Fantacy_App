import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:axevora11/features/chat/domain/chat_message_model.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({required this.messages, this.isLoading = false, this.error});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading, String? error}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final chatMessagesProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, roomId) {
  return ChatNotifier(roomId, ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final String roomId;
  final Ref ref;
  final Dio _dio = Dio();
  final String _workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';
  
  Timer? _pollingTimer;
  int _lastUpdateMs = 0;

  ChatNotifier(this.roomId, this.ref) : super(ChatState(messages: [], isLoading: true)) {
    _initPolling();
  }

  void _initPolling() {
    _fetchMessages();
    // Poll every 5 seconds for fast real-time feel using low-cost D1
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchMessages();
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await _dio.get('$_workerUrl/api/chat/sync?roomId=$roomId&after=$_lastUpdateMs');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rawMessages = response.data['messages'] ?? [];
        if (rawMessages.isEmpty) {
            if (state.isLoading) state = state.copyWith(isLoading: false);
            return;
        }

        final newMessages = rawMessages.map((m) {
          return ChatMessage(
            id: m['id']?.toString() ?? '',
            senderId: m['user_id']?.toString() ?? '',
            senderName: m['user_name']?.toString() ?? 'Player',
            senderPhoto: m['user_photo']?.toString() ?? '',
            text: m['content']?.toString() ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch(int.tryParse(m['created_at'].toString()) ?? 0),
          );
        }).toList();

        // Update latest timestamp cursor
        final latestTime = newMessages.map((m) => m.timestamp.millisecondsSinceEpoch).reduce((a, b) => a > b ? a : b);
        if (latestTime > _lastUpdateMs) {
          _lastUpdateMs = latestTime;
        }

        // Merge and sort
        final Map<String, ChatMessage> merged = {
          for (var m in state.messages) m.id: m,
          for (var m in newMessages) m.id: m,
        };

        final finalMessages = merged.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Descending for Chat

        state = state.copyWith(messages: finalMessages, isLoading: false);
      }
    } catch (e) {
      debugPrint("❌ Chat Polling Error: $e");
      if (state.isLoading) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Exposed for Send method
  Future<void> sendMessage(String text, {Map<String, dynamic>? scoreSnip}) async {
    final userAsync = ref.read(userEntityProvider);
    final user = userAsync.value;
    if (user == null) return;

    // Optimistic UI update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessage(
      id: tempId,
      senderId: user.uid,
      senderName: user.displayName ?? 'Player',
      senderPhoto: user.photoUrl ?? '',
      text: text,
      timestamp: DateTime.now(),
      scoreSnip: scoreSnip,
    );

    final updatedMessages = [tempMsg, ...state.messages];
    state = state.copyWith(messages: updatedMessages);

    try {
      final response = await _dio.post('$_workerUrl/api/chat/send', data: {
        'roomId': roomId,
        'userId': user.uid,
        'content': text,
        'messageType': 'text',
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
         // Force instant fetch after successful send instead of waiting for 5s 
         _fetchMessages();
      }
    } catch (e) {
      debugPrint("❌ Chat Send Error: $e");
      // Could remove optimistic message on failure
      state = state.copyWith(messages: state.messages.where((m) => m.id != tempId).toList());
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final chatServiceProvider = Provider((ref) => ChatService(ref));

class ChatService {
  final Ref _ref;

  ChatService(this._ref);

  Future<void> sendMessage(String roomId, String text, {Map<String, dynamic>? scoreSnip}) async {
     // Forward to the specific room's provider
     _ref.read(chatMessagesProvider(roomId).notifier).sendMessage(text, scoreSnip: scoreSnip);
  }
}
