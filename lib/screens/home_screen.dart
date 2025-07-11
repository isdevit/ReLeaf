import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../task_recommender.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskRecommender _recommender = TaskRecommender();
  late Future<Map<String, dynamic>> _tasksFuture;
  String? _username;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _username = doc.data()?['username'] ?? user.email ?? 'User';
        _avatarUrl = doc.data()?['avatarUrl'] ?? '';
      });
    }
  }

  Future<Map<String, dynamic>> _loadTasks() async {
    await _recommender.loadModel();
    final completed = await _recommender.getCompletedTasks();
    final tags = await _recommender.getTagsForTasks(completed);
    final tagVector = _recommender.generateTagVector(tags);
    final topTags = await _recommender.predictTopTags(tagVector);
    final dailyTasks = await _recommender.fetchRecommendedTasks(topTags, completed);
    final weeklyTasks = await _recommender.fetchWeeklyTasks(completed);
    return {
      'dailyTasks': dailyTasks,
      'weeklyTasks': weeklyTasks,
    };
  }

  // Improved minimalist completion dialog
  void _showCompletionDialog(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, color: Colors.green[700], size: 48),
              const SizedBox(height: 16),
              Text('Complete Task',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Upload a picture or video as proof of completion.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera, size: 32, color: Color(0xFF4CAF50)),
                    onPressed: () {
                      // TODO: Implement camera capture
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library, size: 32, color: Color(0xFF4CAF50)),
                    onPressed: () {
                      // TODO: Implement gallery picker
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam, size: 32, color: Color(0xFF4CAF50)),
                    onPressed: () {
                      // TODO: Implement video picker/capture
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = getGreeting();
    return Scaffold(
      backgroundColor: const Color(0xFFF6FDF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                            ? NetworkImage(_avatarUrl!)
                            : const AssetImage('assets/images/avatar.png') as ImageProvider,
                        radius: 22,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _username ?? 'Loading...',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.search, size: 24, color: Colors.black54),
                      SizedBox(width: 14),
                      Icon(Icons.notifications_none, size: 24, color: Colors.black54),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 18),
              // Weekly Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Weekly Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 22, color: Color(0xFF4CAF50)),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FutureBuilder<Map<String, dynamic>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('Error loading tasks', style: TextStyle(color: Colors.red))),
                    );
                  } else if (!snapshot.hasData || (snapshot.data?['weeklyTasks']?.isEmpty ?? true)) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No weekly tasks found.')),
                    );
                  }
                  final weeklyTasks = snapshot.data!['weeklyTasks'] as List;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${weeklyTasks.length} Tasks Pending",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: weeklyTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final task = weeklyTasks[index];
                            return Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {},
                                child: Container(
                                  width: 180,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade50,
                                        Colors.green.shade100.withOpacity(0.2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['name'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task['description'] ?? '',
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
                                            onPressed: () => _showCompletionDialog(context, task),
                                            tooltip: 'Mark as completed',
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF4CAF50)),
                                            onPressed: () => _showCompletionDialog(context, task),
                                            tooltip: 'Upload proof',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              // Today's Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 22, color: Color(0xFF4CAF50)),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _tasksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading tasks', style: TextStyle(color: Colors.red)));
                    } else if (!snapshot.hasData || (snapshot.data?['dailyTasks']?.isEmpty ?? true)) {
                      return Center(child: Text('No daily tasks found.'));
                    }
                    final dailyTasks = snapshot.data!['dailyTasks'] as List;
                    return ListView.builder(
                      itemCount: dailyTasks.length,
                      itemBuilder: (context, index) {
                        final task = dailyTasks[index];
                        return Material(
                          elevation: 1,
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {},
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade50,
                                    Colors.green.shade100.withOpacity(0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task['name'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
                                        onPressed: () => _showCompletionDialog(context, task),
                                        tooltip: 'Mark as completed',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: (task['tags'] as List?)?.map((tag) => Chip(
                                      label: Text(tag.toString()),
                                      backgroundColor: Colors.green[100],
                                      labelStyle: const TextStyle(fontSize: 10),
                                    )).toList() ?? [],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    task['description'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
