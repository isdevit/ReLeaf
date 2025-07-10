import 'package:flutter/material.dart';
import 'dart:math';

// Data model for posts - ready for Firebase integration
class CommunityPost {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String taskType;
  final String taskTitle;
  final String description;
  final String imageUrl;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final List<String> badges;
  final bool isLiked;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.taskType,
    required this.taskTitle,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.badges,
    this.isLiked = false,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showFloatingButton = true;

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
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
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

  // Dummy data - ready for Firebase backend
  List<CommunityPost> getDummyPosts() {
    return [
      CommunityPost(
        id: "post_001",
        userId: "user_001",
        username: "sarah_green",
        userAvatar: "https://images.unsplash.com/photo-1494790108755-2616b9097baa?w=150",
        taskType: "wellness",
        taskTitle: "Morning Yoga Session",
        description: "Started my day with 20 minutes of yoga in the garden 🧘‍♀️ Feeling so energized and ready for the day! #MorningMotivation #WellnessJourney",
        imageUrl: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 24,
        comments: 8,
        badges: ["7-Day Streak", "Wellness Warrior"],
      ),
      CommunityPost(
        id: "post_002",
        userId: "user_002",
        username: "eco_alex",
        userAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
        taskType: "eco",
        taskTitle: "Zero Waste Lunch",
        description: "Packed my lunch in reusable containers today! Small steps towards a more sustainable lifestyle 🌱 Who else is joining the zero waste challenge?",
        imageUrl: "https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=400",
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        likes: 31,
        comments: 12,
        badges: ["Eco Warrior", "Sustainability Star"],
      ),
      CommunityPost(
        id: "post_003",
        userId: "user_003",
        username: "mindful_mike",
        userAvatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150",
        taskType: "mindfulness",
        taskTitle: "Nature Meditation",
        description: "Found the perfect spot for today's mindfulness session. The sound of birds and rustling leaves was so peaceful 🍃",
        imageUrl: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400",
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        likes: 18,
        comments: 5,
        badges: ["Mindful Master"],
      ),
      CommunityPost(
        id: "post_004",
        userId: "user_004",
        username: "active_anna",
        userAvatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150",
        taskType: "fitness",
        taskTitle: "Bike to Work Day",
        description: "Cycled to work instead of driving today! 🚴‍♀️ Not only great exercise but also helping reduce my carbon footprint. Win-win!",
        imageUrl: "https://images.unsplash.com/photo-1558618666-5c0c22756114?w=400",
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        likes: 42,
        comments: 15,
        badges: ["Eco Warrior", "Fitness Enthusiast", "7-Day Streak"],
      ),
    ];
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

  Widget _buildPostCard(CommunityPost post) {
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
                  backgroundImage: NetworkImage(post.userAvatar),
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
                          _buildTaskTypeIcon(post.taskType),
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
                  icon: Icon(Icons.more_horiz, color: darkGray.withOpacity(0.6)),
                  onPressed: () {
                    // Show post options
                  },
                ),
              ],
            ),
          ),

          // Task title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.taskTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
            ),
          ),

          // Post image
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(post.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Post description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.description,
              style: TextStyle(
                color: darkGray.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          // Badges
          if (post.badges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: post.badges.map((badge) => _buildBadge(badge)).toList(),
              ),
            ),

          // Post actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.isLiked ? Colors.red : darkGray.withOpacity(0.6),
                  count: post.likes,
                  onTap: () {
                    // Handle like
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: darkGray.withOpacity(0.6),
                  count: post.comments,
                  onTap: () {
                    // Handle comment
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  color: darkGray.withOpacity(0.6),
                  onTap: () {
                    // Handle share
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.bookmark_border, color: darkGray.withOpacity(0.6)),
                  onPressed: () {
                    // Handle bookmark
                  },
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildFeedTab() {
    final posts = getDummyPosts();

    return RefreshIndicator(
      onRefresh: () async {
        // Handle refresh - fetch new posts from Firebase
        await Future.delayed(const Duration(seconds: 1));
      },
      color: softGreen,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(posts[index]);
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
            // Handle create post
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