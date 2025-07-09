import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../task_recommender.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskRecommender _recommender = TaskRecommender();
  late Future<Map<String, dynamic>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
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

  @override
  Widget build(BuildContext context) {
    final username = "Dan Smith"; // Replace with dynamic data later
    final greeting = getGreeting();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/images/avatar.png'),
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
                            username,
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
              const SizedBox(height: 24),
              // Weekly Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Weekly Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 10),
                      Icon(Icons.add, size: 20),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
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
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: weeklyTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final task = weeklyTasks[index];
                            return Container(
                              width: 200,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 4,
                                    children: (task['tags'] as List?)?.map((tag) => Chip(
                                      label: Text(tag.toString()),
                                      backgroundColor: Colors.green[100],
                                      labelStyle: const TextStyle(fontSize: 10),
                                    )).toList() ?? [],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    task['name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    task['description'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.blue),
                                        onPressed: () {}, // TODO: Mark as completed
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.camera_alt, color: Colors.green),
                                        onPressed: () {}, // TODO: Click picture
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Today's Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 10),
                      Icon(Icons.add, size: 20),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(20),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.blue),
                                    onPressed: () {}, // TODO: Mark as completed
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                children: (task['tags'] as List?)?.map((tag) => Chip(
                                  label: Text(tag.toString()),
                                  backgroundColor: Colors.green[100],
                                  labelStyle: const TextStyle(fontSize: 10),
                                )).toList() ?? [],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                task['description'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: const [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                                  SizedBox(width: 4),
                                  Text("Mon, 10 July 2025", style: TextStyle(fontSize: 12)),
                                  Spacer(),
                                  CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                                  SizedBox(width: 4),
                                  CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                                  SizedBox(width: 4),
                                  Text("+1")
                                ],
                              )
                            ],
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
