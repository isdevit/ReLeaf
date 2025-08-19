import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../task_recommender.dart';
import '../widgets/photo_upload_dialog.dart';

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
  int _userPoints = 0;
  List<String> _completedTaskIds = [];

  // Color palette matching community screen
  static const Color primaryWhite = Color(0xFFFAFAFA);
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);

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
        _userPoints = doc.data()?['points'] ?? 0;
        _completedTaskIds = List<String>.from(doc.data()?['tasksCompleted'] ?? []);
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

  Widget _buildBadge(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [softGreen, accentGreen],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => PhotoUploadDialog(
        task: task,
        onUploadComplete: () {
          // Refresh tasks and user data after completion
          setState(() {
            _tasksFuture = _loadTasks();
          });
          _fetchUserData(); // Refresh user points and completed tasks
        },
      ),
    );
  }

  void _showTaskSelectionDialog(BuildContext context) {
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
              Icon(Icons.camera_alt, color: softGreen, size: 48),
              const SizedBox(height: 16),
              Text(
                'Share Your Progress',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a task to share your completion photo',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: darkGray.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FutureBuilder<Map<String, dynamic>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: Text('No tasks available')),
                    );
                  }

                  final weeklyTasks = snapshot.data!['weeklyTasks'] as List;
                  final dailyTasks = snapshot.data!['dailyTasks'] as List;
                  final allTasks = [...weeklyTasks, ...dailyTasks];

                  if (allTasks.isEmpty) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: Text('No tasks available')),
                    );
                  }

                  return Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allTasks.length,
                      itemBuilder: (context, index) {
                        final task = allTasks[index];
                        return ListTile(
                          leading: Icon(Icons.task_alt, color: softGreen),
                          title: Text(
                            task['name'] ?? 'Task',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            task['description'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showCompletionDialog(context, task);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: darkGray.withOpacity(0.6)),
                ),
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
      backgroundColor: primaryWhite,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show a dialog to select a task for photo upload
          _showTaskSelectionDialog(context);
        },
        backgroundColor: softGreen,
        foregroundColor: Colors.white,
        icon: Icon(Icons.camera_alt),
        label: Text(
          'Share Progress',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              color: darkGray.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            _username ?? 'Loading...',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: darkGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Points display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [softGreen, accentGreen],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$_userPoints',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.search, size: 24, color: darkGray.withOpacity(0.6)),
                      const SizedBox(width: 16),
                      Icon(Icons.notifications_outlined, size: 24, color: darkGray.withOpacity(0.6)),
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
                      color: darkGray,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 22, color: softGreen),
                    onPressed: () {},
                  ),
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
                        style: GoogleFonts.poppins(fontSize: 12, color: darkGray.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: weeklyTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final task = weeklyTasks[index];
                            return Container(
                              width: 200,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((task['tags'] as List?)?.isNotEmpty ?? false)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: (task['tags'] as List).take(2).map((tag) => _buildBadge(tag.toString())).toList(),
                                      ),
                                    if ((task['tags'] as List?)?.isNotEmpty ?? false)
                                      const SizedBox(height: 12),
                                    Text(
                                      task['name'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _completedTaskIds.contains(task['id'] ?? task['name']) 
                                            ? darkGray.withOpacity(0.5)
                                            : darkGray,
                                        decoration: _completedTaskIds.contains(task['id'] ?? task['name'])
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      task['description'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: darkGray.withOpacity(0.7),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        if (_completedTaskIds.contains(task['id'] ?? task['name']))
                                          Icon(
                                            Icons.check_circle,
                                            color: softGreen,
                                            size: 20,
                                          )
                                        else
                                          IconButton(
                                            icon: Icon(Icons.check_circle_outline, color: softGreen, size: 20),
                                            onPressed: () => _showCompletionDialog(context, task),
                                            tooltip: 'Mark as completed',
                                          ),
                                        const Spacer(),
                                        if (!_completedTaskIds.contains(task['id'] ?? task['name']))
                                          IconButton(
                                            icon: Icon(Icons.camera_alt_outlined, color: softGreen, size: 20),
                                            onPressed: () => _showCompletionDialog(context, task),
                                            tooltip: 'Upload proof',
                                          ),
                                      ],
                                    ),
                                  ],
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
                      color: darkGray,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 22, color: softGreen),
                    onPressed: () {},
                  ),
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
                                          color: _completedTaskIds.contains(task['id'] ?? task['name']) 
                                              ? darkGray.withOpacity(0.5)
                                              : darkGray,
                                          decoration: _completedTaskIds.contains(task['id'] ?? task['name'])
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.check_circle_outline, color: softGreen, size: 20),
                                      onPressed: () => _showCompletionDialog(context, task),
                                      tooltip: 'Mark as completed',
                                    ),
                                  ],
                                ),
                                if ((task['tags'] as List?)?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: (task['tags'] as List).take(3).map((tag) => _buildBadge(tag.toString())).toList(),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  task['description'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: darkGray.withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
