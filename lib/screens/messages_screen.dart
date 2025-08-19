import 'package:flutter/material.dart';

import '../models/chat_models.dart';
import '../services/local_chat_service.dart';
import '../services/remote_chat_service.dart';
import '../services/firestore_friend_service.dart';
import '../services/firestore_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  ChatUser? _selectedUser;
  final LocalChatService _chatService = LocalChatService();
  final RemoteChatService _remoteService = RemoteChatService();
  final FirestoreFriendService _friendService = FirestoreFriendService();
  final TextEditingController _searchController = TextEditingController();
  bool _isTyping = false;
  bool _otherTyping = false;
  Set<String> _requestedUserIds = {};

  // Color palette matching ReLeaf design
  static const Color primaryWhite = Color(0xFFFAFAFA);
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color leafGreen = Color(0xFF66BB6A);
  static const Color receivedBubble = Color(0xFFEFF7EE); // subtle green tint for incoming

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Remove any call to pendingRequestsStream
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

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
    );
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
    );
  }

  Widget _buildUserListItem(ChatUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(user.avatar),
              backgroundColor: lightGray,
            ),
            if (user.isOnline)
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: darkGray,
                ),
              ),
            ),
            if (user.unreadCount > 0)
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.lastMessage,
              style: TextStyle(
                color: darkGray.withOpacity(0.7),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (user.badges.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: user.badges.take(2).map((badge) => _buildBadge(badge)).toList(),
                    ),
                  ),
                Text(
                  _getTimeAgo(user.lastMessageTime),
                  style: TextStyle(
                    color: darkGray.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedUser = user;
          });
          _chatService.markChatAsRead(user.id);
          _remoteService.otherUserTypingStream(user.id).listen((isTyping) {
            if (!mounted) return;
            setState(() => _otherTyping = isTyping);
          });
          // Scroll to bottom when opening chat
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

  Widget _buildFriendRequestTile(Map<String, dynamic> r, {bool highlighted = false}) {
    final String fromUserId = (r['from'] as String? ?? '').trim();
    return Card(
      color: highlighted ? Colors.yellow[50] : Colors.white,
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _friendService.userStream(fromUserId),
        builder: (context, snap) {
          final userDoc = snap.data;
          final String username = (userDoc?['username'] as String?) ?? 'Someone';
          final String avatarUrl = (userDoc?['avatarUrl'] as String?) ?? '';
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              backgroundColor: lightGray,
              child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            title: Text(username, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('sent you a friend request'),
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _friendService.acceptFriendRequest(fromUserId),
                  child: const Text('Accept'),
                ),
                TextButton(
                  onPressed: () => _friendService.declineFriendRequest(fromUserId),
                  child: const Text('Decline'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
                senderId: '',
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    if (_selectedUser == null) return;

    final ChatMessage newMessage = ChatMessage(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      senderId: "current_user",
      senderName: "You",
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      isMe: true,
    );

    // Write immediately to local for snappy UX
    _chatService.sendMessage(toUserId: _selectedUser!.id, message: newMessage);
    // Mirror to remote for real-time sync
    _remoteService.sendMessage(toUserId: _selectedUser!.id, message: newMessage);
    _messageController.clear();
    if (_selectedUser != null) {
      _remoteService.setTyping(otherUserId: _selectedUser!.id, isTyping: false);
      _isTyping = false;
    }

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

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search username to add friend',
                    filled: true,
                    fillColor: lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Search'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _friendService.searchUsersByUsername(_searchController.text),
            builder: (context, snapshot) {
              final results = snapshot.data ?? <Map<String, dynamic>>[];
              if ((_searchController.text).trim().isEmpty) {
                return const Center(child: Text('Search for friends by username'));
              }
              if (results.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final u = results[index];
                  final chatUser = _toChatUserFromUserDoc(u);
                  final bool requested = _requestedUserIds.contains(
                      chatUser.id);
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(chatUser.avatar), backgroundColor: lightGray),
                    title: Text(chatUser.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: TextButton(
                      onPressed: requested
                          ? null
                          : () async {
                        await _friendService.sendFriendRequest(chatUser.id);
                        setState(() {
                          _requestedUserIds.add(chatUser.id);
                        });
                      },
                      child: Text(requested ? 'Requested' : 'Add'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _friendService.incomingRequestsStream(),
            builder: (context, snapshot) {
              final requests = snapshot.data ?? <Map<String, dynamic>>[];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final r = requests[index];
                  return _buildFriendRequestTile(r);
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
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _friendService.incomingRequestsStream(),
          builder: (context, requestsSnapshot) {
            final requests = requestsSnapshot.data ?? <Map<String, dynamic>>[];
            final total = friends.length + requests.length;
            if (total == 0) {
              return const Center(child: Text('No chats or requests'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: total,
              itemBuilder: (context, index) {
                if (index < requests.length) {
                  final r = requests[index];
                  return _buildFriendRequestTile(r, highlighted: true);
                } else {
                  final idx = index - requests.length;
                  final f = friends[idx];
                  final String friendUserId = f['userId'] as String;
                  return StreamBuilder<Map<String, dynamic>?>(
                    stream: _friendService.userStream(friendUserId),
                    builder: (context, snap) {
                      final userDoc = snap.data;
                      if (userDoc == null) {
                        return const SizedBox.shrink();
                      }
                      final chatUser = _toChatUserFromUserDoc(userDoc);
                      return _buildUserListItem(chatUser);
                    },
                  );
                }
              },
            );
          },
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
            onPressed: () {
              // Handle chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _selectedUser != null
                  ? _remoteService
                      .messagesStream(_selectedUser!.id)
                      .distinct()
                      .map((remote) {
                        // Merge remote into local for offline persistence
                        _chatService.mergeMessages(_selectedUser!.id, remote);
                        return remote;
                      })
                  : const Stream<List<ChatMessage>>.empty(),
              builder: (context, snapshot) {
                // Fallback to local stream if remote empty or not yet connected
                final List<ChatMessage> messages = snapshot.data ?? <ChatMessage>[];
                // Mark incoming messages as read
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
                // Auto scroll when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_chatScrollController.hasClients) {
                    _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
                  }
                });
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
    if (_selectedUser != null) {
      return _buildChatView();
    }

    return Scaffold(
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
            icon: Icon(Icons.search, color: darkGray),
            onPressed: () {
              // Handle search
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: darkGray),
            onPressed: () {
              // Handle new message
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: softGreen,
          unselectedLabelColor: darkGray.withOpacity(0.6),
          indicatorColor: softGreen,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
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