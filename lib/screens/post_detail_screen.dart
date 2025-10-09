import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  PostModel? _post;
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  bool _postingComment = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
    });
    final posts = await _firestoreService.getAllPosts();
    final filteredPosts = posts
        .where((p) => p.postId == widget.postId)
        .toList();
    setState(() {
      _post = filteredPosts.isNotEmpty ? filteredPosts[0] : null;
      _isLoading = false;
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text
        .trim()
        .isEmpty || _postingComment || _post == null) return;
    setState(() {
      _postingComment = true;
    });
    final currentUser = await _firestoreService.getUserData(_post!.userId);
    final username = currentUser['username'] ?? 'User';
    final comment = Comment(
      userId: _post!.userId,
      username: username,
      text: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );
    await _firestoreService.addComment(_post!.postId, comment);
    _commentController.clear();
    await _loadPost();
    setState(() {
      _postingComment = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
          ? const Center(child: Text('Post not found'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: _post!.userAvatarUrl.isNotEmpty
                            ? NetworkImage(_post!.userAvatarUrl)
                            : const AssetImage(
                            'assets/images/avatar.png') as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_post!.username, style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(_getTimeAgo(_post!.timestamp),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  if (_post!.relatedTaskId != null) ...[
                    const SizedBox(height: 10),
                    Text(_post!.relatedTaskId!, style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18)),
                  ],
                ],
              ),
            ),
            // Centered post image
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _post!.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_post!.caption, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text('Comments',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            ...(_post!.comments.isEmpty
                ? [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No comments yet.'),
              ),
            ]
                : _post!.comments.map((c) =>
                ListTile(
                  leading: CircleAvatar(child: Text(c.username.isNotEmpty
                      ? c.username[0].toUpperCase()
                      : '?')),
                  title: Text(c.username),
                  subtitle: Text(c.text),
                  trailing: Text(_getTimeAgo(c.timestamp),
                      style: const TextStyle(fontSize: 11)),
                ))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                          hintText: 'Add a comment...'),
                    ),
                  ),
                  _postingComment
                      ? const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                      : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
