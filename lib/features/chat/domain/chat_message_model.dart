import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhoto;
  final String text;
  final DateTime timestamp;
  final Map<String, dynamic>? scoreSnip; // For integrated score snips

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhoto,
    required this.text,
    required this.timestamp,
    this.scoreSnip,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown User',
      senderPhoto: map['senderPhoto'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scoreSnip: map['scoreSnip'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'scoreSnip': scoreSnip,
    };
  }
}
