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
    final Color podiumBg = Colors.green.shade50;
    final Color scrollBoxBg = Colors.white;
    final Color cardBg = Colors.green.shade100.withOpacity(0.5);
    final Color borderColor = Colors.green.shade200;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FDF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Leaderboard',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          final top3 = users.length >= 3 ? users.sublist(0, 3) : users;
          final rest = users.length > 3 ? users.sublist(3) : [];

          Widget buildTopUser(UserModel user, int rank, {double radius = 36, bool isCenter = false}) {
            return Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Material(
                      elevation: isCenter ? 10 : 4,
                      shape: const CircleBorder(),
                      child: CircleAvatar(
                        radius: radius,
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : const AssetImage('assets/images/avatar.png') as ImageProvider,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    if (isCenter)
                      Positioned(
                        bottom: -10,
                        child: Material(
                          elevation: 4,
                          shape: const CircleBorder(),
                          color: Colors.transparent,
                          child: Icon(Icons.emoji_events, color: Colors.amber[700], size: 36),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user.username,
                  style: GoogleFonts.poppins(fontSize: isCenter ? 16 : 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${user.points} pts",
                  style: GoogleFonts.poppins(fontSize: isCenter ? 14 : 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCenter ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rank $rank',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isCenter ? Colors.green[800] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          }

          Widget buildTop3(List<UserModel> top3) {
            if (top3.length < 3) {
              // Fallback for less than 3 users
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(top3.length, (i) {
                  return buildTopUser(top3[i], i + 1, radius: 36, isCenter: i == 0);
                }),
              );
            }
            // Arrange: 2nd on left, 1st in center (elevated), 3rd on right (2 and 3 same size/level)
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: podiumBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd place
                  buildTopUser(top3[1], 2, radius: 36),
                  // 1st place (center, elevated)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: buildTopUser(top3[0], 1, radius: 44, isCenter: true),
                  ),
                  // 3rd place
                  buildTopUser(top3[2], 3, radius: 36),
                ],
              ),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 24),
              buildTop3(top3),
              const SizedBox(height: 28),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  decoration: BoxDecoration(
                    color: scrollBoxBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: ListView.builder(
                      itemCount: rest.length,
                      padding: const EdgeInsets.only(top: 16, left: 12, right: 12, bottom: 8),
                      itemBuilder: (context, index) {
                        final user = rest[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: borderColor, width: 1),
                          ),
                          color: cardBg,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl.isNotEmpty
                                  ? NetworkImage(user.avatarUrl)
                                  : const AssetImage('assets/images/avatar.png') as ImageProvider,
                              radius: 18,
                              backgroundColor: Colors.white,
                            ),
                            title: Text(
                              user.username,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              "Rank #${index + 4}",
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: Text(
                              "${user.points} pts",
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
