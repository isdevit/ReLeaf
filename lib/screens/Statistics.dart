import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  // Statistics
  int _tasksCompleted = 0;
  int _currentStreak = 0;
  int _pointsEarned = 0;
  int _badgesEarned = 0;
  bool _isLoadingStats = true;

  // Store details for popups
  List<String> _tasksList = [];
  List<String> _badgesList = [];

  // Colors
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _tasksCompleted = (data['tasksCompleted'] as List?)?.length ?? 0;
            _pointsEarned = data['points'] ?? 0;
            _currentStreak = data['currentStreak'] ?? 0;
            _badgesEarned = data['badgesEarned'] ?? 0;
            _tasksList = List<String>.from((data['tasksCompleted'] as List?) ?? []);
            _badgesList = _calculateBadgesList();
            _isLoadingStats = false;
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  List<String> _calculateBadgesList() {
    List<String> badges = [];
    if (_tasksCompleted >= 1) badges.add("First Task Completed");
    if (_tasksCompleted >= 10) badges.add("10 Tasks Completed");
    if (_tasksCompleted >= 50) badges.add("50 Tasks Completed");
    if (_tasksCompleted >= 100) badges.add("100 Tasks Completed");
    if (_currentStreak >= 7) badges.add("7-Day Streak");
    if (_currentStreak >= 30) badges.add("30-Day Streak");
    if (_pointsEarned >= 100) badges.add("100 Points Earned");
    if (_pointsEarned >= 1000) badges.add("1000 Points Earned");
    return badges;
  }

  Future<void> _refreshStat() async {
    setState(() {
      _isLoadingStats = true;
    });
    await _fetchUserData();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: darkGray.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatDetails(String title, List<String> details) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
            ),
            const SizedBox(height: 12),
            if (details.isEmpty)
              Center(
                child: Text(
                  'No details available',
                  style: GoogleFonts.poppins(color: darkGray.withOpacity(0.6)),
                ),
              )
            else
              ...details.map(
                    (d) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    d,
                    style: GoogleFonts.poppins(color: darkGray),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Statistics',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkGray,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStat,
        color: softGreen,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: _isLoadingStats
              ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(softGreen),
            ),
          )
              : GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                title: 'Tasks Completed',
                value: _formatNumber(_tasksCompleted),
                icon: Icons.check_circle,
                color: softGreen,
                onTap: () => _showStatDetails('Tasks Completed', _tasksList),
              ),
              _buildStatCard(
                title: 'Current Streak',
                value: '$_currentStreak days',
                icon: Icons.local_fire_department,
                color: Colors.orange,
                onTap: () => _showStatDetails('Current Streak', ['$_currentStreak day streak']),
              ),
              _buildStatCard(
                title: 'Points Earned',
                value: _formatNumber(_pointsEarned),
                icon: Icons.stars,
                color: Colors.amber,
                onTap: () => _showStatDetails('Points Earned', ['$_pointsEarned points']),
              ),
              _buildStatCard(
                title: 'Badges Earned',
                value: _formatNumber(_badgesEarned),
                icon: Icons.emoji_events,
                color: Colors.purple,
                onTap: () => _showStatDetails('Badges Earned', _badgesList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}