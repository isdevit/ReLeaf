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

  @override
  void initState() {
    super.initState();
    _futureUsers = FirestoreService().fetchLeaderboardUsers();
  }

  @override
  Widget build(BuildContext context) {
    // Figma palette
    const Color textPrimary = Color(0xFF4F4F4F); // rgb(79,79,79)
    const Color lime = Color(0xFFC7F064); // rgb(199,240,100)
    const Color paleGreen = Color(0xFFF0F4E7); // rgb(240,244,231)

    final TextStyle titleStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: textPrimary,
    );
    final TextStyle nameStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w700,
      fontSize: 14.4,
      color: textPrimary,
    );
    final TextStyle pointsStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w400,
      fontSize: 14.4,
      color: textPrimary,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text('Leaderboard', style: titleStyle),
        actions: [
          // Right header actions to mirror Figma (notification, chat)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                _HeaderIconButton(
                  background: const Color(0xFFFcfaf3),
                  icon: Icons.notifications_none,
                  iconColor: const Color(0xFF1C1E20),
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  background: const Color(0xFFFcfaf3),
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFF1C1E20),
                ),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data ?? <UserModel>[];
          if (users.isEmpty) {
            return Center(
              child: Text('No users found.',
                  style: GoogleFonts.plusJakartaSans(color: textPrimary)),
            );
          }

          final List<UserModel> top3 = users.length >= 3
              ? users.sublist(0, 3)
              : users;
          final List<UserModel> rest = users.length > 3 ? users.sublist(3) : <
              UserModel>[];

          return Column(
            children: [
              const SizedBox(height: 8),
              // Top 3 podium area
              _TopThreeRow(
                top3: top3,
                lime: lime,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 16),
              // Rounded top container with list
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: paleGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: rest.length,
                      itemBuilder: (context, index) {
                        final user = rest[index];
                        final rank = index + 4; // since top 3 already shown
                        return _LeaderboardCard(
                          rank: rank,
                          user: user,
                          nameStyle: nameStyle,
                          pointsStyle: pointsStyle,
                          textPrimary: textPrimary,
                          lime: lime,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final Color background;
  final IconData icon;
  final Color iconColor;

  const _HeaderIconButton({
    required this.background,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}

class _TopThreeRow extends StatelessWidget {
  final List<UserModel> top3;
  final Color lime;
  final Color textPrimary;

  const _TopThreeRow({
    required this.top3,
    required this.lime,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    // If fewer than 3 users, show whatever we have centered
    if (top3.length < 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(top3.length, (i) {
          final size = i == 0 ? 76.0 : 68.0;
          final rank = i + 1;
          return _PodiumUser(
            user: top3[i],
            rank: rank,
            avatarSize: size,
            lime: lime,
            textPrimary: textPrimary,
            showCrown: i == 0,
          );
        }),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _PodiumUser(
                user: top3[1],
                rank: 2,
                avatarSize: 68,
                lime: lime,
                textPrimary: textPrimary,
                showCrown: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PodiumUser(
                  user: top3[0],
                  rank: 1,
                  avatarSize: 80,
                  lime: lime,
                  textPrimary: textPrimary,
                  showCrown: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _PodiumUser(
                user: top3[2],
                rank: 3,
                avatarSize: 68,
                lime: lime,
                textPrimary: textPrimary,
                showCrown: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumUser extends StatelessWidget {
  final UserModel user;
  final int rank;
  final double avatarSize;
  final Color lime;
  final Color textPrimary;
  final bool showCrown;

  const _PodiumUser({
    required this.user,
    required this.rank,
    required this.avatarSize,
    required this.lime,
    required this.textPrimary,
    required this.showCrown,
  });

  @override
  Widget build(BuildContext context) {
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
                border: Border.all(color: lime, width: 3),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? NetworkImage(user.avatarUrl)
                    : const AssetImage(
                    'assets/images/avatar.png') as ImageProvider,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: lime,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            if (showCrown)
              Positioned(
                top: -20,
                left: (avatarSize / 2) - 12,
                child: Icon(Icons.emoji_events, color: lime, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.username,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14.4,
            color: textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 16, color: lime),
            const SizedBox(width: 4),
            Text(
              '${user.points} pts',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final UserModel user;
  final TextStyle nameStyle;
  final TextStyle pointsStyle;
  final Color textPrimary;
  final Color lime;

  const _LeaderboardCard({
    required this.rank,
    required this.user,
    required this.nameStyle,
    required this.pointsStyle,
    required this.textPrimary,
    required this.lime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14.4,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : const AssetImage(
                  'assets/images/avatar.png') as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.username,
              style: nameStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('${user.points} pts', style: pointsStyle),
        ],
      ),
    );
  }
}
