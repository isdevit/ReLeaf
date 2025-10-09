import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../widgets/photo_upload_dialog.dart';
import 'dart:io';
import '../screens/post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showFloatingButton = true;
  final FirestoreService _firestoreService = FirestoreService();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _currentUserId;

  // Color palette matching ReLeaf design
  static const Color primaryWhite = Color(0xFFFAFAFA);
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color leafGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadPosts();
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && _showFloatingButton) {
      setState(() {
        _showFloatingButton = false;
      });
    } else if (_scrollController.offset <= 100 && !_showFloatingButton) {
      setState(() {
        _showFloatingButton = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final posts = await _firestoreService.getAllPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load posts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  Widget _buildTaskTypeIcon(String taskType) {
    IconData icon;
    Color color;

    switch (taskType.toLowerCase()) {
      case 'wellness':
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case 'eco':
        icon = Icons.eco;
        color = softGreen;
        break;
      case 'mindfulness':
        icon = Icons.self_improvement;
        color = Colors.purple;
        break;
      case 'fitness':
        icon = Icons.fitness_center;
        color = Colors.orange;
        break;
      default:
        icon = Icons.task_alt;
        color = accentGreen;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildBadge(String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [softGreen, accentGreen],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badge,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: post.postId),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: post.userAvatarUrl.isNotEmpty
                        ? NetworkImage(post.userAvatarUrl)
                        : const AssetImage(
                        'assets/images/avatar.png') as ImageProvider,
                    backgroundColor: lightGray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: darkGray,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (post.tags.isNotEmpty)
                              _buildTaskTypeIcon(post.tags.first),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeAgo(post.timestamp),
                          style: TextStyle(
                            color: darkGray.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: darkGray.withOpacity(0.6),
                    ),
                    onPressed: () {
                      // Show post options
                    },
                  ),
                ],
              ),
            ),

            // Task title
            if (post.relatedTaskId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  post.relatedTaskId!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                ),
              ),

            // Centered Post image
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
                    post.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: lightGray,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: darkGray.withOpacity(0.5),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: lightGray,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                softGreen),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Post description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.caption,
                style: TextStyle(
                  color: darkGray.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            // Tags
            if (post.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.tags.map((tag) => _buildBadge(tag)).toList(),
                ),
              ),

            // Post actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: post.likedBy.contains(_currentUserId ?? '') ? Icons
                        .favorite : Icons.favorite_border,
                    color: post.likedBy.contains(_currentUserId ?? '') ? Colors
                        .red : darkGray.withOpacity(0.6),
                    count: post.likes,
                    onTap: () {
                      _handleLike(post);
                    },
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    color: darkGray.withOpacity(0.6),
                    count: post.comments.length,
                    onTap: () {
                      // Handle comment
                    },
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    color: darkGray.withOpacity(0.6),
                    onTap: () {
                      _handleShare(post);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.bookmark_border,
                        color: darkGray.withOpacity(0.6)),
                    onPressed: () {
                      // Handle bookmark
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    int? count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: darkGray.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
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

  Future<void> _handleLike(PostModel post) async {
    try {
      if (post.likedBy.contains(_currentUserId)) {
        await _firestoreService.unlikePost(post.postId, _currentUserId!);
      } else {
        await _firestoreService.likePost(post.postId, _currentUserId!);
      }
      // Refresh posts to update like status
      await _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreatePostDialog(BuildContext context) {
    // Navigate to home screen to create a post
    Navigator.of(context).pushNamed('/home');
  }

  void _handleShare(PostModel post) {
    // For now, just show a snackbar. You can implement actual sharing later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing post: ${post.caption}'),
        backgroundColor: softGreen,
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(softGreen),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: darkGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your progress!',
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

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: softGreen,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index]);
        },
      ),
    );
  }

  Widget _buildTrendingTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: softGreen),
          SizedBox(height: 16),
          Text(
            'Trending Posts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: darkGray,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Discover what\'s popular in the community',
            style: TextStyle(
              color: darkGray,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Community',
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
            icon: Icon(Icons.notifications_outlined, color: darkGray),
            onPressed: () {
              // Handle notifications
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
            Tab(icon: Icon(Icons.home), text: 'Feed'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          _buildTrendingTab(),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _showFloatingButton ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: () {
            _showCreatePostDialog(context);
          },
          backgroundColor: softGreen,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text(
            'Share Progress',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}