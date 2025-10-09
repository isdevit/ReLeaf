import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_models.dart';

class LocalChatService {
  LocalChatService._internal();
  static final LocalChatService _instance = LocalChatService._internal();
  factory LocalChatService() => _instance;

  static const String _usersKey = 'chat_users';
  static const String _messagesKeyPrefix = 'chat_messages_';

  final StreamController<List<ChatUser>> _usersController = StreamController<List<ChatUser>>.broadcast();
  final Map<String, StreamController<List<ChatMessage>>> _messagesControllers = <String, StreamController<List<ChatMessage>>>{};

  List<ChatUser> _usersCache = <ChatUser>[];
  final Map<String, List<ChatMessage>> _messagesCache = <String, List<ChatMessage>>{};

  Future<void> initializeWithSeedUsers(List<ChatUser> seedUsers) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasUsers = prefs.containsKey(_usersKey);
    if (!hasUsers) {
      await prefs.setStringList(_usersKey, seedUsers.map((u) => u.toJson()).toList());
    }
    await _loadUsersFromPrefs();
  }

  Future<void> _loadUsersFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_usersKey) ?? <String>[];
    _usersCache = raw.map((e) => ChatUser.fromJson(e)).toList();
    _usersController.add(_usersCache);
  }

  Stream<List<ChatUser>> usersStream() {
    // Push current cache on listen
    scheduleMicrotask(() => _usersController.add(_usersCache));
    return _usersController.stream;
  }

  Future<List<ChatUser>> getUsersOnce() async {
    if (_usersCache.isEmpty) {
      await _loadUsersFromPrefs();
    }
    return _usersCache;
  }

  String _chatKeyForUser(String userId) => '$_messagesKeyPrefix$userId';

  Future<List<ChatMessage>> _loadMessagesForUser(String userId) async {
    if (_messagesCache.containsKey(userId)) {
      return _messagesCache[userId]!;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_chatKeyForUser(userId)) ?? <String>[];
    final List<ChatMessage> messages = raw.map((e) => ChatMessage.fromJson(e)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _messagesCache[userId] = messages;
    return messages;
  }

  Stream<List<ChatMessage>> messagesStream(String userId) {
    if (!_messagesControllers.containsKey(userId)) {
      _messagesControllers[userId] = StreamController<List<ChatMessage>>.broadcast();
      // Lazy load initial
      _loadMessagesForUser(userId).then((value) => _messagesControllers[userId]!.add(value));
    }
    return _messagesControllers[userId]!.stream;
  }

  Future<void> sendMessage({
    required String toUserId,
    required ChatMessage message,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<ChatMessage> current = await _loadMessagesForUser(toUserId);
    current.add(message);
    current.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await prefs.setStringList(
      _chatKeyForUser(toUserId),
      current.map((m) => m.toJson()).toList(),
    );
    _messagesCache[toUserId] = current;
    _messagesControllers[toUserId]?.add(List<ChatMessage>.from(current));

    // Update user last message
    final int index = _usersCache.indexWhere((u) => u.id == toUserId);
    if (index != -1) {
      final ChatUser updated = _usersCache[index].copyWith(
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        unreadCount: message.isMe ? _usersCache[index].unreadCount : _usersCache[index].unreadCount + 1,
      );
      _usersCache[index] = updated;
      await prefs.setStringList(_usersKey, _usersCache.map((u) => u.toJson()).toList());
      _usersController.add(List<ChatUser>.from(_usersCache));
    }
  }

  Future<void> markChatAsRead(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int index = _usersCache.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _usersCache[index] = _usersCache[index].copyWith(unreadCount: 0);
      await prefs.setStringList(_usersKey, _usersCache.map((u) => u.toJson()).toList());
      _usersController.add(List<ChatUser>.from(_usersCache));
    }
  }

  // Merge remote messages into local cache and persist; keeps order stable
  Future<void> mergeMessages(String userId, List<ChatMessage> remoteMessages) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<ChatMessage> local = await _loadMessagesForUser(userId);
    final Map<String, ChatMessage> byId = <String, ChatMessage>{
      for (final m in local) m.id: m,
    };
    int newUnreadFromRemote = 0;
    for (final m in remoteMessages) {
      if (!byId.containsKey(m.id) && !m.isMe) {
        newUnreadFromRemote += 1;
      }
      byId[m.id] = m;
    }
    final List<ChatMessage> merged = byId.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    await prefs.setStringList(
      _chatKeyForUser(userId),
      merged.map((m) => m.toJson()).toList(),
    );
    _messagesCache[userId] = merged;
    _messagesControllers[userId]?.add(List<ChatMessage>.from(merged));

    if (merged.isNotEmpty) {
      // Update user summary
      final int index = _usersCache.indexWhere((u) => u.id == userId);
      if (index != -1) {
        final ChatMessage last = merged.last;
        final ChatUser updated = _usersCache[index].copyWith(
          lastMessage: last.content,
          lastMessageTime: last.timestamp,
          unreadCount: _usersCache[index].unreadCount + newUnreadFromRemote,
        );
        _usersCache[index] = updated;
        await prefs.setStringList(_usersKey, _usersCache.map((u) => u.toJson()).toList());
        _usersController.add(List<ChatUser>.from(_usersCache));
      }
    }
  }
}


