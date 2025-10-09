import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<UserModel>> _futureUsers;

  // Color palette matching ReLeaf design from Community screen
  static const Color primaryWhite = Color(0xFFFAFAFA);
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color leafGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _futureUsers = FirestoreService().fetchLeaderboardUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildTopThreeSection(List<UserModel> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'Top Performers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 24),
          if (top3.length >= 3) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPodiumUser(top3[1], 2, 68.0, false),
                _buildPodiumUser(top3[0], 1, 80.0, true),
                _buildPodiumUser(top3[2], 3, 68.0, false),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(top3.length, (i) {
                final size = i == 0 ? 80.0 : 68.0;
                final rank = i + 1;
                return _buildPodiumUser(top3[i], rank, size, i == 0);
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPodiumUser(UserModel user, int rank, double avatarSize, bool showCrown) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: rank == 1 ? softGreen : accentGreen,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: lightGray,
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? NetworkImage(user.avatarUrl)
                    : const AssetImage('assets/images/avatar.png') as ImageProvider,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [softGreen, accentGreen],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (showCrown)
              Positioned(
                top: -20,
                left: (avatarSize / 2) - 12,
                child: Icon(
                  Icons.emoji_events,
                  color: softGreen,
                  size: 24,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user.username,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: darkGray,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: softGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, size: 14, color: softGreen),
              const SizedBox(width: 4),
              Text(
                '${user.points} pts',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: softGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(UserModel user, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [softGreen, accentGreen],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 24,
              backgroundImage: user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : const AssetImage('assets/images/avatar.png') as ImageProvider,
              backgroundColor: lightGray,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 14, color: darkGray.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        'Active user',
                        style: TextStyle(
                          color: darkGray.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: softGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, size: 16, color: softGreen),
                  const SizedBox(width: 4),
                  Text(
                    '${user.points}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: softGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTimeTab(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64, color: darkGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete tasks to appear on the leaderboard!',
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

    final List<UserModel> top3 = users.length >= 3 ? users.sublist(0, 3) : users;
    final List<UserModel> rest = users.length > 3 ? users.sublist(3) : <UserModel>[];

    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        _buildTopThreeSection(top3),
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'All Rankings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkGray,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: rest.map((user) {
                final rank = users.indexOf(user) + 1;
                return _buildLeaderboardCard(user, rank);
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 100), // Bottom padding
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                'Leaderboard',
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
            icon: Icon(Icons.notifications_outlined, color: darkGray),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(softGreen),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: darkGray.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading leaderboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      color: darkGray.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? <UserModel>[];

          return _buildAllTimeTab(users);
        },
      ),
    );
  }
}