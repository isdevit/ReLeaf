import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_models.dart';

class RemoteChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _currentUserId() => _auth.currentUser?.uid ?? 'current_user';
  String _currentUserName() => _auth.currentUser?.displayName ?? 'You';

  String _chatIdFor(String otherUserId) {
    final String me = _currentUserId();
    return me.compareTo(otherUserId) < 0 ? '${me}_$otherUserId' : '${otherUserId}_$me';
  }

  Stream<List<ChatMessage>> messagesStream(String otherUserId) {
    final String chatId = _chatIdFor(otherUserId);
    final String me = _currentUserId();
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: (data['senderId'] ?? '') as String,
          senderName: (data['senderName'] ?? '') as String,
          content: (data['content'] ?? '') as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(((data['timestamp'] ?? 0) as int)),
          isMe: (data['senderId'] ?? '') == me,
          type: (data['type'] ?? 'text') == 'image' ? MessageType.image : ((data['type'] ?? 'text') == 'system' ? MessageType.system : MessageType.text),
          status: data['status'] != null ? _messageStatusFromString(data['status']) : MessageStatus.sent,
          deliveredAtMs: data['deliveredAtMs'] as int?,
          readAtMs: data['readAtMs'] as int?,
          mediaUrl: data['mediaUrl'] as String?,
        );
      }).toList();
    });
  }

  Future<void> sendMessage({
    required String toUserId,
    required ChatMessage message,
  }) async {
    final String chatId = _chatIdFor(toUserId);
    // Ensure minimal fields; store timestamp as millis for portability
    final Map<String, dynamic> map = {
      'senderId': message.senderId.isEmpty ? _currentUserId() : message.senderId,
      'senderName': message.senderName.isEmpty ? _currentUserName() : message.senderName,
      'content': message.content,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'type': message.type == MessageType.image ? 'image' : (message.type == MessageType.system ? 'system' : 'text'),
      'status': _messageStatusToString(message.status),
      'deliveredAtMs': message.deliveredAtMs,
      'readAtMs': message.readAtMs,
      'mediaUrl': message.mediaUrl,
    };
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(map, SetOptions(merge: false));

    // Optional: update a chat summary document for efficient listings
    await _db.collection('chat_summaries').doc(chatId).set({
      'lastMessage': message.content,
      'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      'updatedBy': _currentUserId(),
      'participants': [
        _currentUserId(),
        toUserId,
      ],
    }, SetOptions(merge: true));
  }

  Future<void> updateMessageStatus({
    required String otherUserId,
    required String messageId,
    required MessageStatus status,
  }) async {
    final String chatId = _chatIdFor(otherUserId);
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'status': _messageStatusToString(status),
      if (status == MessageStatus.delivered) 'deliveredAtMs': DateTime.now().millisecondsSinceEpoch,
      if (status == MessageStatus.read) 'readAtMs': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> setTyping({required String otherUserId, required bool isTyping}) async {
    final String chatId = _chatIdFor(otherUserId);
    await _db.collection('chat_typing').doc(chatId).set({
      _currentUserId(): isTyping,
    }, SetOptions(merge: true));
  }

  Stream<bool> otherUserTypingStream(String otherUserId) {
    final String chatId = _chatIdFor(otherUserId);
    final String me = _currentUserId();
    return _db.collection('chat_typing').doc(chatId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      // If the map has my key, the other user's key is the remaining participant. We cannot infer it reliably here,
      // so we check any key that is not me.
      for (final entry in data.entries) {
        if (entry.key != me) {
          return (entry.value as bool?) ?? false;
        }
      }
      return false;
    });
  }
}
MessageType _messageTypeFromString(String value) {
  switch (value) {
    case 'image':
      return MessageType.image;
    case 'system':
      return MessageType.system;
    case 'text':
    default:
      return MessageType.text;
  }
}

String _messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.image:
      return 'image';
    case MessageType.system:
      return 'system';
    case MessageType.text:
    default:
      return 'text';
  }
}

MessageStatus _messageStatusFromString(String value) {
  switch (value) {
    case 'delivered':
      return MessageStatus.delivered;
    case 'read':
      return MessageStatus.read;
    case 'sent':
    default:
      return MessageStatus.sent;
  }
}

String _messageStatusToString(MessageStatus status) {
  switch (status) {
    case MessageStatus.delivered:
      return 'delivered';
    case MessageStatus.read:
      return 'read';
    case MessageStatus.sent:
    default:
      return 'sent';
  }
}


