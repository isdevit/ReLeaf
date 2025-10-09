import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_models.dart';
import '../services/local_chat_service.dart';
import '../services/remote_chat_service.dart';
import '../services/firestore_friend_service.dart';
import '../services/firestore_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
=======
import 'package:cloud_firestore/cloud_firestore.dart';

// Data models for messaging
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
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.type = MessageType.text,
  });
}

enum MessageType { text, image, system }
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  ChatUser? _selectedUser;
<<<<<<< HEAD
  final LocalChatService _chatService = LocalChatService();
  final RemoteChatService _remoteService = RemoteChatService();
  final FirestoreFriendService _friendService = FirestoreFriendService();
  bool _isTyping = false;
  bool _otherTyping = false;
  Set<String> _requestedUserIds = {};
=======
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c

  // Color palette matching ReLeaf design
  static const Color primaryWhite = Color(0xFFFAFAFA);
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color receivedBubble = Color(0xFFEFF7EE);

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  ChatUser _toChatUserFromUserDoc(Map<String, dynamic> userDoc) {
    return ChatUser(
      id: userDoc['id'] as String,
      name: userDoc['username'] as String? ?? '',
      avatar: userDoc['avatarUrl'] as String? ?? '',
      lastMessage: userDoc['lastMessage'] as String? ?? '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch((userDoc['lastMessageTime'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      unreadCount: 0,
      isOnline: userDoc['isOnline'] as bool? ?? false,
      badges: const [],
=======
  // Firestore streams
  Stream<List<ChatUser>> getChatUsersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatUser(
          id: doc.id,
          name: data['username'] ?? '',
          avatar: data['avatarUrl'] ?? '',
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: (data['lastMessageTime'] != null && data['lastMessageTime'] is Timestamp)
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : DateTime.now(),
          unreadCount: data['unreadCount'] ?? 0,
          isOnline: data['isOnline'] ?? false,
          badges: List<String>.from(data['badges'] ?? []),
        );
      }).toList();
    });
  }

  Stream<List<ChatMessage>> getMessagesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(_getChatId(userId))
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? '',
          content: data['content'] ?? '',
          timestamp: (data['timestamp'] != null && data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          isMe: data['senderId'] == 'current_user', // Replace with actual current user id
          type: MessageType.text,
        );
      }).toList();
    });
  }

  String _getChatId(String otherUserId) {
    final currentUserId = 'current_user'; // Replace with actual current user id
    return currentUserId.compareTo(otherUserId) < 0
        ? '${currentUserId}_$otherUserId'
        : '${otherUserId}_$currentUserId';
  }

  Widget _buildBadge(String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [softGreen, accentGreen],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        badge,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c
    );
  }

<<<<<<< HEAD
=======


>>>>>>> 8a4d85730ba1b3c725a4b24d0d653b3f03532524
  Widget _buildUserCard(ChatUser user, {bool isSearchResult = false, VoidCallback? onAddTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: user.avatar.isNotEmpty
                      ? NetworkImage(user.avatar)
                      : const AssetImage('assets/images/avatar.png') as ImageProvider,
                  backgroundColor: lightGray,
                ),
                if (user.isOnline && !isSearchResult)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: darkGray,
                        ),
                      ),
                      const Spacer(),
                      if (!isSearchResult && user.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: softGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (!isSearchResult)
                    Text(
                      user.lastMessage,
                      style: TextStyle(
                        color: darkGray.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSearchResult ? 'Tap to add friend' : _getTimeAgo(user.lastMessageTime),
                        style: TextStyle(
                          color: darkGray.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (isSearchResult)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _requestedUserIds.contains(user.id)
                                  ? [Colors.grey, Colors.grey]
                                  : [softGreen, accentGreen],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _requestedUserIds.contains(user.id) ? 'Requested' : 'Add Friend',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
<<<<<<< HEAD
=======
        onTap: () {
          setState(() {
            _selectedUser = user;
          });
        },
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(_selectedUser?.avatar ?? ""),
              backgroundColor: lightGray,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe ? softGreen : receivedBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.image && (message.mediaUrl ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.mediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.black12,
                            height: 160,
                            width: 220,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: message.isMe ? Colors.white : darkGray,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getTimeAgo(message.timestamp),
                        style: TextStyle(
                          color: message.isMe ? Colors.white.withOpacity(0.8) : darkGray.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 6),
                        if (message.status == MessageStatus.sent)
                          Icon(Icons.check, size: 14, color: Colors.white.withOpacity(0.85))
                        else if (message.status == MessageStatus.delivered)
                          Icon(Icons.done_all, size: 14, color: Colors.white.withOpacity(0.85))
                        else if (message.status == MessageStatus.read)
                            const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
=======


>>>>>>> 8a4d85730ba1b3c725a4b24d0d653b3f03532524
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.grey),
            onPressed: () async {
              if (_selectedUser == null) return;
              final ImagePicker picker = ImagePicker();
              final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (picked == null) return;
              final file = File(picked.path);
              final storage = FirestoreService();
              final String path = 'chat_images/${_selectedUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
              String url;
              try {
                url = await storage.uploadImage(file, path);
              } catch (_) {
                return;
              }
              final ChatMessage imageMsg = ChatMessage(
                id: "msg_${DateTime.now().millisecondsSinceEpoch}",
                senderId: _currentUserId ?? '',
                senderName: '',
                content: '',
                timestamp: DateTime.now(),
                isMe: true,
                type: MessageType.image,
                mediaUrl: url,
              );
              _chatService.sendMessage(toUserId: _selectedUser!.id, message: imageMsg);
              _remoteService.sendMessage(toUserId: _selectedUser!.id, message: imageMsg);
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintStyle: TextStyle(color: darkGray.withOpacity(0.6)),
                ),
                maxLines: null,
                onChanged: (v) {
                  final bool nowTyping = v.trim().isNotEmpty;
                  if (nowTyping != _isTyping && _selectedUser != null) {
                    _isTyping = nowTyping;
                    _remoteService.setTyping(otherUserId: _selectedUser!.id, isTyping: _isTyping);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [softGreen, accentGreen],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    if (_selectedUser == null) return;

    final ChatMessage newMessage = ChatMessage(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      senderId: _currentUserId ?? '',
      senderName: "You",
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      isMe: true,
    );

    _chatService.sendMessage(toUserId: _selectedUser!.id, message: newMessage);
    _remoteService.sendMessage(toUserId: _selectedUser!.id, message: newMessage);
    _messageController.clear();
    if (_selectedUser != null) {
      _remoteService.setTyping(otherUserId: _selectedUser!.id, isTyping: false);
      _isTyping = false;
    }
=======
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedUser == null) return;

    final currentUserId = 'current_user'; // Replace with actual current user id
    final currentUserName = 'You'; // Replace with actual current user name
    final chatId = _getChatId(_selectedUser!.id);
    final messageData = {
      'senderId': currentUserId,
      'senderName': currentUserName,
      'content': _messageController.text.trim(),
      'timestamp': DateTime.now(),
    };

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    _messageController.clear();
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

<<<<<<< HEAD
  Widget _buildFriendRequestTile(Map<String, dynamic> r) {
    final String fromUserId = (r['from'] as String? ?? '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _friendService.userStream(fromUserId),
        builder: (context, snap) {
          final userDoc = snap.data;
          final String username = (userDoc?['username'] as String?) ?? 'Someone';
          final String avatarUrl = (userDoc?['avatarUrl'] as String?) ?? '';
          
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  backgroundColor: lightGray,
                  child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wants to be your friend',
                        style: TextStyle(
                          color: darkGray.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _friendService.acceptFriendRequest(fromUserId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: softGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Accept',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                                                         child: ElevatedButton(
                               onPressed: () async {
                                 await _friendService.declineFriendRequest(fromUserId);
                               },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: darkGray,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Decline',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search username to add friend',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: darkGray.withOpacity(0.6)),
                hintStyle: TextStyle(color: darkGray.withOpacity(0.6)),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
        ),
        // Search Results
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _friendService.searchUsersByUsername(_searchController.text),
            builder: (context, snapshot) {
              final results = snapshot.data ?? <Map<String, dynamic>>[];
              if ((_searchController.text).trim().isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: darkGray.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Search for friends',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter a username to find and add friends',
                        style: TextStyle(
                          color: darkGray.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search, size: 64, color: darkGray.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different username',
                        style: TextStyle(
                          color: darkGray.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final u = results[index];
                  final chatUser = _toChatUserFromUserDoc(u);
                  return GestureDetector(
                    onTap: !_requestedUserIds.contains(chatUser.id) ? () async {
                      await _friendService.sendFriendRequest(chatUser.id);
                      setState(() {
                        _requestedUserIds.add(chatUser.id);
                      });
                    } : null,
                    child: _buildUserCard(chatUser, isSearchResult: true),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.friendsStream(),
      builder: (context, friendsSnapshot) {
        final friends = friendsSnapshot.data ?? <Map<String, dynamic>>[];
<<<<<<< HEAD
        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: darkGray.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation with your friends',
                  style: TextStyle(
                    color: darkGray.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final f = friends[index];
            final String friendUserId = f['userId'] as String;
            return StreamBuilder<Map<String, dynamic>?>(
              stream: _friendService.userStream(friendUserId),
              builder: (context, snap) {
                final userDoc = snap.data;
                if (userDoc == null) {
                  return const SizedBox.shrink();
=======
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _friendService.incomingRequestsStream(),
          builder: (context, requestsSnapshot) {
            final requests = requestsSnapshot.data ?? <Map<String, dynamic>>[];
            final total = friends.length + requests.length;
            
            if (total == 0) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: darkGray.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No chats yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation with your friends',
                      style: TextStyle(
                        color: darkGray.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: total,
              itemBuilder: (context, index) {
                if (index < requests.length) {
                  final r = requests[index];
                  return _buildFriendRequestTile(r);
                } else {
                  final f = friends[index - requests.length];
                  final String friendUserId = f['userId'] as String;
                  return StreamBuilder<Map<String, dynamic>?>(
                    stream: _friendService.userStream(friendUserId),
                    builder: (context, snap) {
                      final userDoc = snap.data;
                      if (userDoc == null) {
                        return const SizedBox.shrink();
                      }
                      final chatUser = _toChatUserFromUserDoc(userDoc);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedUser = chatUser;
                          });
                          _chatService.markChatAsRead(chatUser.id);
                          _remoteService.otherUserTypingStream(chatUser.id).listen((isTyping) {
                            if (!mounted) return;
                            setState(() => _otherTyping = isTyping);
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_chatScrollController.hasClients) {
                              _chatScrollController.animateTo(
                                _chatScrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        },
                        child: _buildUserCard(chatUser),
                      );
                    },
                  );
>>>>>>> 8a4d85730ba1b3c725a4b24d0d653b3f03532524
                }
                final chatUser = _toChatUserFromUserDoc(userDoc);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUser = chatUser;
                    });
                    _chatService.markChatAsRead(chatUser.id);
                    _remoteService.otherUserTypingStream(chatUser.id).listen((isTyping) {
                      if (!mounted) return;
                      setState(() => _otherTyping = isTyping);
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_chatScrollController.hasClients) {
                        _chatScrollController.animateTo(
                          _chatScrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                  child: _buildUserCard(chatUser),
                );
              },
            );
          },
=======
  Widget _buildUsersTab() {
    return StreamBuilder<List<ChatUser>>(
      stream: getChatUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: () async {},
          color: softGreen,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserListItem(users[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildChatsTab() {
    return StreamBuilder<List<ChatUser>>(
      stream: getChatUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final chats = (snapshot.data ?? []).where((user) => user.lastMessage.isNotEmpty).toList();
        return RefreshIndicator(
          onRefresh: () async {},
          color: softGreen,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              return _buildUserListItem(chats[index]);
            },
          ),
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c
        );
      },
    );
  }

  Widget _buildChatView() {
    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkGray),
          onPressed: () {
            setState(() {
              _selectedUser = null;
            });
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(_selectedUser?.avatar ?? ""),
              backgroundColor: lightGray,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedUser?.name ?? "",
                    style: const TextStyle(
                      color: darkGray,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _selectedUser?.isOnline == true ? "Online" : "Offline",
                    style: TextStyle(
                      color: _selectedUser?.isOnline == true ? Colors.green : darkGray.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  if (_otherTyping)
                    const Text(
                      "Typing...",
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: darkGray),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
<<<<<<< HEAD
              stream: _selectedUser != null
                  ? _remoteService
                  .messagesStream(_selectedUser!.id)
                  .distinct()
                  .map((remote) {
                // Fix the isMe property based on current user
                final correctedMessages = remote.map((message) {
                  return ChatMessage(
                    id: message.id,
                    senderId: message.senderId,
                    senderName: message.senderName,
                    content: message.content,
                    timestamp: message.timestamp,
                    isMe: message.senderId == _currentUserId,
                    status: message.status,
                    type: message.type,
                    mediaUrl: message.mediaUrl,
                  );
                }).toList();
                _chatService.mergeMessages(_selectedUser!.id, correctedMessages);
                return correctedMessages;
              })
                  : const Stream<List<ChatMessage>>.empty(),
              builder: (context, snapshot) {
                final List<ChatMessage> messages = snapshot.data ?? <ChatMessage>[];
                if (_selectedUser != null) {
                  for (final m in messages) {
                    if (!m.isMe && (m.status != MessageStatus.read)) {
                      _remoteService.updateMessageStatus(
                        otherUserId: _selectedUser!.id,
                        messageId: m.id,
                        status: MessageStatus.read,
                      );
                    }
                  }
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_chatScrollController.hasClients) {
                    _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
                  }
                });
=======
              stream: _selectedUser != null ? getMessagesStream(_selectedUser!.id) : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c
                return ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _selectedUser != null
        ? _buildChatView()
        : Scaffold(
      backgroundColor: primaryWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [softGreen, accentGreen],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
<<<<<<< HEAD
            icon: Icon(Icons.notifications_outlined, color: darkGray),
=======
            icon: Icon(Icons.search, color: darkGray),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.add, color: darkGray),
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: softGreen,
          unselectedLabelColor: darkGray.withOpacity(0.6),
          indicatorColor: softGreen,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Add Friends'),
            Tab(icon: Icon(Icons.chat), text: 'Chats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildChatsTab(),
        ],
      ),
    );
  }
}