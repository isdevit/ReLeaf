import 'dart:convert';

enum MessageType { text, image, system }
enum MessageStatus { sent, delivered, read }

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

class ChatUser {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final List<String> badges;

  ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.badges = const [],
  });

  ChatUser copyWith({
    String? id,
    String? name,
    String? avatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    List<String>? badges,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'badges': badges,
    };
  }

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      avatar: map['avatar'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
        (map['lastMessageTime'] ?? DateTime.now().millisecondsSinceEpoch) as int,
      ),
      unreadCount: (map['unreadCount'] ?? 0) as int,
      isOnline: (map['isOnline'] ?? false) as bool,
      badges: List<String>.from(map['badges'] ?? const <String>[]),
    );
  }

  String toJson() => json.encode(toMap());
  factory ChatUser.fromJson(String source) => ChatUser.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final MessageType type;
  final MessageStatus status;
  final int? deliveredAtMs;
  final int? readAtMs;
  final String? mediaUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.deliveredAtMs,
    this.readAtMs,
    this.mediaUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isMe': isMe,
      'type': _messageTypeToString(type),
      'status': _messageStatusToString(status),
      'deliveredAtMs': deliveredAtMs,
      'readAtMs': readAtMs,
      'mediaUrl': mediaUrl,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch) as int),
      isMe: (map['isMe'] ?? false) as bool,
      type: _messageTypeFromString(map['type'] ?? 'text'),
      status: _messageStatusFromString(map['status'] ?? 'sent'),
      deliveredAtMs: map['deliveredAtMs'] as int?,
      readAtMs: map['readAtMs'] as int?,
      mediaUrl: map['mediaUrl'] as String?,
    );
  }

  String toJson() => json.encode(toMap());
  factory ChatMessage.fromJson(String source) => ChatMessage.fromMap(json.decode(source) as Map<String, dynamic>);
}


