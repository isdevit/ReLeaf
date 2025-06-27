import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboardData = [
      {'rank': 1, 'name': 'Bryan Wolf', 'points': 43, 'image': 'assets/images/avatar1.png'},
      {'rank': 2, 'name': 'Meghan Jess...', 'points': 40, 'image': 'assets/images/avatar2.png'},
      {'rank': 3, 'name': 'Alex Turner', 'points': 38, 'image': 'assets/images/avatar3.png'},
      {'rank': 4, 'name': 'Marsha Fisher', 'points': 36, 'image': 'assets/images/avatar4.png', 'up': true},
      {'rank': 5, 'name': 'Juanita Cormier', 'points': 35, 'image': 'assets/images/avatar5.png', 'up': false},
      {'rank': 6, 'name': 'You', 'points': 34, 'image': 'assets/images/avatar6.png', 'up': true},
      {'rank': 7, 'name': 'Tamara Schmidt', 'points': 33, 'image': 'assets/images/avatar7.png', 'up': false},
      {'rank': 8, 'name': 'Ricardo Veum', 'points': 32, 'image': 'assets/images/avatar8.png', 'up': false},
      {'rank': 9, 'name': 'Gary Sanford', 'points': 31, 'image': 'assets/images/avatar9.png', 'up': true},
      {'rank': 10, 'name': 'Becky Bartell', 'points': 30, 'image': 'assets/images/avatar10.png', 'up': false},
    ];

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
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Top 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: leaderboardData.sublist(0, 3).map((user) {
              return Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: AssetImage(user['image'] as String),
                      ),
                      if (user['rank'] == 1)
                        Positioned(
                          top: -8,
                          child: Icon(Icons.emoji_events, color: Colors.green[700], size: 28),
                        )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user['name'] as String,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${user['points']} pts",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                  )
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F8F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView.builder(
                itemCount: leaderboardData.length - 3,
                itemBuilder: (context, index) {
                  final user = leaderboardData[index + 3];
                  final isYou = user['name'] == 'You';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isYou ? const Color(0xFFD8F3DC) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${user['rank']}",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          backgroundImage: AssetImage(user['image'] as String),
                          radius: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            user['name'] as String,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        Text(
                          "${user['points']} pts",
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          ((user['up'] ?? true) == true) ? Icons.arrow_upward : Icons.arrow_downward,
                          color: ((user['up'] ?? true) == true) ? Colors.green : Colors.red,
                          size: 16,
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }
}
