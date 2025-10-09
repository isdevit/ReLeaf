import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'EditProfilePage.dart';
import 'Statistics.dart';
import 'auth/sign_in_screen.dart';

// ---------- Helper for Page Slide Transition ----------
void navigateWithSlide(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );
}


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  String _username = 'User';
  String? _avatarUrl;
  bool _isEditingUsername = false;
  final TextEditingController _usernameController = TextEditingController();

  // Real data for statistics
  int _tasksCompleted = 0;
  int _currentStreak = 0;
  int _pointsEarned = 0;
  int _badgesEarned = 0;
  bool _isLoadingStats = true;
  bool _isUploadingAvatar = false;
  double _uploadProgress = 0.0;

  // Color palette matching other screens
  static const Color primaryWhite = Color(0xFFFAFAFA);
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadImageFromPrefs();
    _fetchUserData();
  }

  Future<void> _loadImageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _imageFile = File(imagePath);
      });
    }
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _username = data['username'] ?? 'User';
            _avatarUrl = data['avatarUrl'] ?? '';
            _tasksCompleted = (data['tasksCompleted'] as List?)?.length ?? 0;
            _pointsEarned = data['points'] ?? 0;
            _currentStreak = data['currentStreak'] ?? 0;
            _badgesEarned = data['badgesEarned'] ?? 0;
            _isLoadingStats = false;
          });
          _usernameController.text = _username;

          // Calculate current streak
          await _calculateCurrentStreak();

          // Calculate badges based on achievements
          await _calculateBadges();

          // Update tasks completed count from posts
          final postsCount = await _getUserPostsCount();
          final totalLikes = await _getUserTotalLikes();
          final avgDailyPosts = await _getUserAverageDailyPosts();
          final bestPost = await _getUserBestPost();
          final totalEngagement = await _getUserTotalEngagement();
          final totalShares = await _getUserTotalShares();
          final totalComments = await _getUserTotalComments();
          final totalViews = await _getUserTotalViews();
          final totalFollowers = await _getUserTotalFollowers();
          final totalFollowing = await _getUserTotalFollowing();
          setState(() {
            _tasksCompleted = postsCount;
            // You can add totalLikes, avgDailyPosts, bestPost, totalEngagement, totalShares, totalComments, totalViews, totalFollowers, and totalFollowing to state if you want to display them
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

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoadingStats = true;
    });
    await _fetchUserData();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Future<void> _calculateCurrentStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Get posts from the last 30 days to calculate streak
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
            .orderBy('timestamp', descending: true)
            .get();

        int currentStreak = 0;
        DateTime? lastPostDate;

        for (var doc in postsQuery.docs) {
          final postDate = (doc.data()['timestamp'] as Timestamp).toDate();
          final postDay = DateTime(postDate.year, postDate.month, postDate.day);

          if (lastPostDate == null) {
            lastPostDate = postDay;
            currentStreak = 1;
          } else {
            final daysDifference = lastPostDate.difference(postDay).inDays;
            if (daysDifference == 1) {
              currentStreak++;
              lastPostDate = postDay;
            } else {
              break;
            }
          }
        }

        setState(() {
          _currentStreak = currentStreak;
        });

        // Update the streak in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'currentStreak': currentStreak});
      } catch (e) {
        print('Error calculating streak: $e');
      }
    }
  }

  Future<void> _calculateBadges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        int badges = 0;

        // Badge 1: First task completion
        if (_tasksCompleted >= 1) badges++;

        // Badge 2: 10 tasks completed
        if (_tasksCompleted >= 10) badges++;

        // Badge 3: 50 tasks completed
        if (_tasksCompleted >= 50) badges++;

        // Badge 4: 100 tasks completed
        if (_tasksCompleted >= 100) badges++;

        // Badge 5: 7-day streak
        if (_currentStreak >= 7) badges++;

        // Badge 6: 30-day streak
        if (_currentStreak >= 30) badges++;

        // Badge 7: 100 points earned
        if (_pointsEarned >= 100) badges++;

        // Badge 8: 1000 points earned
        if (_pointsEarned >= 1000) badges++;

        setState(() {
          _badgesEarned = badges;
        });

        // Update badges in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'badgesEarned': badges});
      } catch (e) {
        print('Error calculating badges: $e');
      }
    }
  }

  // Method to get user's achievement level based on points
  String _getAchievementLevel() {
    if (_pointsEarned >= 1000) return 'Master';
    if (_pointsEarned >= 500) return 'Expert';
    if (_pointsEarned >= 200) return 'Advanced';
    if (_pointsEarned >= 100) return 'Intermediate';
    if (_pointsEarned >= 50) return 'Beginner';
    return 'Newcomer';
  }

  // Method to get achievement level color
  Color _getAchievementLevelColor() {
    if (_pointsEarned >= 1000) return Colors.purple;
    if (_pointsEarned >= 500) return Colors.blue;
    if (_pointsEarned >= 200) return Colors.orange;
    if (_pointsEarned >= 100) return Colors.amber;
    if (_pointsEarned >= 50) return Colors.green;
    return Colors.grey;
  }

  // Method to get next milestone
  String _getNextMilestone() {
    if (_pointsEarned < 50) return '50 points';
    if (_pointsEarned < 100) return '100 points';
    if (_pointsEarned < 200) return '200 points';
    if (_pointsEarned < 500) return '500 points';
    if (_pointsEarned < 1000) return '1000 points';
    return 'Max level reached!';
  }

  // Method to get progress to next milestone
  double _getProgressToNextMilestone() {
    if (_pointsEarned >= 1000) return 1.0;
    if (_pointsEarned >= 500) return (_pointsEarned - 500) / 500;
    if (_pointsEarned >= 200) return (_pointsEarned - 200) / 300;
    if (_pointsEarned >= 100) return (_pointsEarned - 100) / 100;
    if (_pointsEarned >= 50) return (_pointsEarned - 50) / 50;
    return _pointsEarned / 50;
  }

  // Method to get user's rank based on points
  String _getUserRank() {
    if (_pointsEarned >= 1000) return '🥇 Legend';
    if (_pointsEarned >= 500) return '🥈 Champion';
    if (_pointsEarned >= 200) return '🥉 Elite';
    if (_pointsEarned >= 100) return '⭐ Rising Star';
    if (_pointsEarned >= 50) return '🌱 Green Thumb';
    return '🌿 Newcomer';
  }

  // Method to get user's total posts count
  Future<int> _getUserPostsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();
        return postsQuery.docs.length;
      } catch (e) {
        print('Error getting posts count: $e');
        return 0;
      }
    }
    return 0;
  }

  // Method to get user's total likes received
  Future<int> _getUserTotalLikes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        int totalLikes = 0;
        for (var doc in postsQuery.docs) {
          totalLikes += (doc.data()['likes'] ?? 0) as int;
        }
        return totalLikes;
      } catch (e) {
        print('Error getting total likes: $e');
        return 0;
      }
    }
    return 0;
  }

  // Method to get user's average daily posts
  Future<double> _getUserAverageDailyPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();

        if (postsQuery.docs.isEmpty) return 0.0;

        final firstPost = postsQuery.docs.first.data()['timestamp'] as Timestamp;
        final lastPost = postsQuery.docs.last.data()['timestamp'] as Timestamp;

        final daysDifference = firstPost.toDate().difference(lastPost.toDate()).inDays;
        if (daysDifference == 0) return postsQuery.docs.length.toDouble();

        return postsQuery.docs.length / daysDifference;
      } catch (e) {
        print('Error calculating average daily posts: $e');
        return 0.0;
      }
    }
    return 0.0;
  }

  // Method to get user's best performing post
  Future<Map<String, dynamic>?> _getUserBestPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .orderBy('likes', descending: true)
            .limit(1)
            .get();

        if (postsQuery.docs.isNotEmpty) {
          return postsQuery.docs.first.data();
        }
      } catch (e) {
        print('Error getting best post: $e');
      }
    }
    return null;
  }

  // Method to get user's total engagement (likes + comments)
  Future<int> _getUserTotalEngagement() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        int totalEngagement = 0;
        for (var doc in postsQuery.docs) {
          totalEngagement += (doc.data()['likes'] ?? 0) as int;
          totalEngagement += (doc.data()['comments'] as List?)?.length ?? 0;
        }
        return totalEngagement;
      } catch (e) {
        print('Error getting total engagement: $e');
        return 0;
      }
    }
    return 0;
  }

  // Method to get user's total shares
  Future<int> _getUserTotalShares() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        int totalShares = 0;
        for (var doc in postsQuery.docs) {
          totalShares += (doc.data()['shares'] ?? 0) as int;
        }
        return totalShares;
      } catch (e) {
        print('Error getting total shares: $e');
        return 0;
      }
    }
    return 0;
  }

  // Method to get user's total comments received
  Future<int> _getUserTotalComments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        int totalComments = 0;
        for (var doc in postsQuery.docs) {
          totalComments += (doc.data()['comments'] as List?)?.length ?? 0;
        }
        return totalComments;
      } catch (e) {
        print('Error getting total comments: $e');
        return 0;
      }
    }
    return 0;
  }

  // Method to get user's total views (estimated from engagement)
  Future<int> _getUserTotalViews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        // Estimate views based on engagement (likes + comments + shares) * 10
        int totalViews = 0;
        for (var doc in postsQuery.docs) {
          final likes = (doc.data()['likes'] ?? 0) as int;
          final comments = (doc.data()['comments'] as List?)?.length ?? 0;
          final shares = (doc.data()['shares'] ?? 0) as int;
          totalViews += (likes + comments + shares) * 10;
        }
        return totalViews;
      } catch (e) {
        print('Error getting total views: $e');
        return 0;
      }
    }
    return 0;
  }

  // Method to get user's total followers (placeholder for future implementation)
  Future<int> _getUserTotalFollowers() async {
    // This would be implemented when you add a followers system
    return 0;
  }

  // Method to get user's total following (placeholder for future implementation)
  Future<int> _getUserTotalFollowing() async {
    // This would be implemented when you add a following system
    return 0;
  }

  // Method to get user's total posts this month
  Future<int> _getUserPostsThisMonth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);

        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .where('timestamp', isGreaterThan: Timestamp.fromDate(firstDayOfMonth))
            .get();

        return postsQuery.docs.length;
      } catch (e) {
        print('Error getting posts this month: $e');
        return 0;
      }
    }
    return 0;
  }

  Future<bool> _validateImage(File imageFile) async {
    try {
      // Check file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image file is too large. Please select an image smaller than 5MB.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }

      // Check if it's a valid image file
      final bytes = await imageFile.readAsBytes();
      if (bytes.length < 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid image file. Please select a valid image.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating image: $e');
      return false;
    }
  }

  Future<void> _removeAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Remove Avatar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Are you sure you want to remove your avatar? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;

      // Delete from Firebase Storage
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(_avatarUrl!);
          await storageRef.delete();
        } catch (e) {
          print('Error deleting from storage: $e');
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'avatarUrl': '',
        'lastAvatarUpdate': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        _avatarUrl = '';
        _imageFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar removed successfully'),
            backgroundColor: softGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error removing avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove avatar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _usernameController.text.trim().isNotEmpty) {
      final newUsername = _usernameController.text.trim();
      if (newUsername == _username) {
        // No change, just exit edit mode
        setState(() {
          _isEditingUsername = false;
        });
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': newUsername,
        });

        setState(() {
          _username = newUsername;
          _isEditingUsername = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update username: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedImage != null) {
      final file = File(pickedImage.path);
      if (await _validateImage(file)) {
        await _uploadAvatarToStorage(file);
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedImage != null) {
      final file = File(pickedImage.path);
      if (await _validateImage(file)) {
        await _uploadAvatarToStorage(file);
      }
    }
  }

  Future<void> _uploadAvatarToStorage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading state
      setState(() {
        _imageFile = imageFile;
        _isUploadingAvatar = true;
        _uploadProgress = 0.0;
      });

      // Upload to Firebase Storage with progress tracking
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${user.uid}.jpg');

      final uploadTask = storageRef.putFile(imageFile);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'avatarUrl': downloadUrl,
        'lastAvatarUpdate': FieldValue.serverTimestamp(),
        'avatarLastUpdated': DateTime.now().toIso8601String(),
      });

      // Update local state
      setState(() {
        _avatarUrl = downloadUrl;
        _isUploadingAvatar = false;
        _uploadProgress = 0.0;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar updated successfully! 🎉'),
            backgroundColor: softGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadAvatarToStorage(imageFile),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: softGreen),
              title: Text('Take Photo', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: softGreen),
              title: Text('Choose from Gallery', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: softGreen),
              title: Text('Edit Username', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _isEditingUsername = true;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAchievementsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Achievements', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAchievementItem('First Task', 'Complete your first task', _tasksCompleted >= 1, Icons.star),
              _buildAchievementItem('Task Master', 'Complete 10 tasks', _tasksCompleted >= 10, Icons.star_border),
              _buildAchievementItem('Task Champion', 'Complete 50 tasks', _tasksCompleted >= 50, Icons.star_border),
              _buildAchievementItem('Task Legend', 'Complete 100 tasks', _tasksCompleted >= 100, Icons.star_border),
              _buildAchievementItem('Week Warrior', '7-day streak', _currentStreak >= 7, Icons.local_fire_department),
              _buildAchievementItem('Month Master', '30-day streak', _currentStreak >= 30, Icons.local_fire_department),
              _buildAchievementItem('Point Collector', 'Earn 100 points', _pointsEarned >= 100, Icons.stars),
              _buildAchievementItem('Point Master', 'Earn 1000 points', _pointsEarned >= 1000, Icons.stars),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, bool isUnlocked, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: isUnlocked ? Colors.amber : Colors.grey,
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: isUnlocked ? darkGray : Colors.grey,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.poppins(
          color: isUnlocked ? darkGray.withOpacity(0.7) : Colors.grey,
        ),
      ),
      trailing: isUnlocked
          ? Icon(Icons.check_circle, color: softGreen)
          : Icon(Icons.lock, color: Colors.grey),
    );
  }

  void _showDetailedStatisticsDialog() async {
    final totalLikes = await _getUserTotalLikes();
    final avgDailyPosts = await _getUserAverageDailyPosts();
    final totalEngagement = await _getUserTotalEngagement();
    final totalShares = await _getUserTotalShares();
    final totalComments = await _getUserTotalComments();
    final totalViews = await _getUserTotalViews();
    final postsThisMonth = await _getUserPostsThisMonth();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detailed Statistics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('Total Posts', _formatNumber(_tasksCompleted), Icons.post_add),
              _buildStatItem('Posts This Month', _formatNumber(postsThisMonth), Icons.calendar_month),
              _buildStatItem('Total Likes', _formatNumber(totalLikes), Icons.favorite),
              _buildStatItem('Total Comments', _formatNumber(totalComments), Icons.comment),
              _buildStatItem('Total Shares', _formatNumber(totalShares), Icons.share),
              _buildStatItem('Total Views', _formatNumber(totalViews), Icons.visibility),
              _buildStatItem('Total Engagement', _formatNumber(totalEngagement), Icons.trending_up),
              _buildStatItem('Avg Daily Posts', avgDailyPosts.toStringAsFixed(1), Icons.analytics),
              _buildStatItem('Current Streak', '$_currentStreak days', Icons.local_fire_department),
              _buildStatItem('Points Earned', _formatNumber(_pointsEarned), Icons.stars),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: softGreen, size: 24),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: darkGray,
        ),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: softGreen,
          fontSize: 16,
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notification Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Push Notifications', style: GoogleFonts.poppins()),
              subtitle: Text('Receive notifications for new messages and updates'),
              value: true,
              onChanged: (value) {
                // TODO: Implement notification toggle
              },
            ),
            SwitchListTile(
              title: Text('Email Notifications', style: GoogleFonts.poppins()),
              subtitle: Text('Receive email updates about your account'),
              value: false,
              onChanged: (value) {
                // TODO: Implement email notification toggle
              },
            ),
            SwitchListTile(
              title: Text('Achievement Alerts', style: GoogleFonts.poppins()),
              subtitle: Text('Get notified when you earn new achievements'),
              value: true,
              onChanged: (value) {
                // TODO: Implement achievement notification toggle
              },
            ),
            SwitchListTile(
              title: Text('Friend Requests', style: GoogleFonts.poppins()),
              subtitle: Text('Notify when someone sends you a friend request'),
              value: true,
              onChanged: (value) {
                // TODO: Implement friend request notification toggle
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Public Profile', style: GoogleFonts.poppins()),
              subtitle: Text('Allow others to view your profile'),
              value: true,
              onChanged: (value) {
                // TODO: Implement public profile toggle
              },
            ),
            SwitchListTile(
              title: Text('Show Online Status', style: GoogleFonts.poppins()),
              subtitle: Text('Let others see when you are online'),
              value: true,
              onChanged: (value) {
                // TODO: Implement online status toggle
              },
            ),
            SwitchListTile(
              title: Text('Allow Friend Requests', style: GoogleFonts.poppins()),
              subtitle: Text('Allow others to send you friend requests'),
              value: true,
              onChanged: (value) {
                // TODO: Implement friend request toggle
              },
            ),
            SwitchListTile(
              title: Text('Show Activity Status', style: GoogleFonts.poppins()),
              subtitle: Text('Display your recent activity to others'),
              value: false,
              onChanged: (value) {
                // TODO: Implement activity status toggle
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.help_outline, color: softGreen),
              title: Text('FAQ', style: GoogleFonts.poppins()),
              subtitle: Text('Frequently asked questions'),
              onTap: () {
                Navigator.of(context).pop();
                _showFAQDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_support, color: softGreen),
              title: Text('Contact Support', style: GoogleFonts.poppins()),
              subtitle: Text('Get help from our support team'),
              onTap: () {
                Navigator.of(context).pop();
                _showContactSupportDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.bug_report, color: softGreen),
              title: Text('Report a Bug', style: GoogleFonts.poppins()),
              subtitle: Text('Report issues or bugs'),
              onTap: () {
                Navigator.of(context).pop();
                _showReportBugDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback, color: softGreen),
              title: Text('Send Feedback', style: GoogleFonts.poppins()),
              subtitle: Text('Share your thoughts with us'),
              onTap: () {
                Navigator.of(context).pop();
                _showFeedbackDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Frequently Asked Questions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQItem('How do I complete tasks?', 'Tasks are completed by posting about your activities in the community section.'),
              _buildFAQItem('How do I earn points?', 'Points are earned by completing tasks, maintaining streaks, and engaging with the community.'),
              _buildFAQItem('What are badges?', 'Badges are achievements you earn for reaching milestones in your journey.'),
              _buildFAQItem('How do I add friends?', 'You can search for users by username and send them friend requests.'),
              _buildFAQItem('How do I change my avatar?', 'Go to Edit Profile and choose to take a photo or select from your gallery.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: GoogleFonts.poppins()),
        ),
      ],
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Support', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email, color: softGreen),
              title: Text('Email Support', style: GoogleFonts.poppins()),
              subtitle: Text('support@releaf.com'),
              onTap: () {
                // TODO: Implement email support
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Email support feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: softGreen),
              title: Text('Live Chat', style: GoogleFonts.poppins()),
              subtitle: Text('Chat with our support team'),
              onTap: () {
                // TODO: Implement live chat
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Live chat feature coming soon!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog() {
    final TextEditingController bugController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report a Bug', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bugController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the bug you encountered...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement bug reporting
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bug report submitted! Thank you for your feedback.')),
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Feedback', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your thoughts and suggestions...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement feedback submission
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Feedback submitted! Thank you for your input.')),
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
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
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? softGreen, size: 24),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: darkGray,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: darkGray.withOpacity(0.4), size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your.email@example.com';

    return Scaffold(
        backgroundColor: primaryWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: darkGray,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: darkGray),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: softGreen,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!)
                                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                        ? NetworkImage(_avatarUrl!)
                                        : null,
                                    backgroundColor: softGreen,
                                    child: _imageFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty)
                                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                                        : null,
                                  ),
                                  if (_isUploadingAvatar)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: _uploadProgress,
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 3,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_isEditingUsername) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _usernameController,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: darkGray,
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: 'Enter new username',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: softGreen),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: softGreen, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: Icon(Icons.check, color: softGreen, size: 24),
                                  onPressed: () async {
                                    await _updateUsername();
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red, size: 24),
                                  onPressed: () {
                                    setState(() {
                                      _isEditingUsername = false;
                                      _usernameController.text = _username;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              child: Text(
                                _username,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: darkGray,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getUserRank(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _getAchievementLevelColor(),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            child: Text(
                              email,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: darkGray.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getAchievementLevelColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getAchievementLevelColor().withOpacity(0.3)),
                            ),
                            child: Text(
                              _getAchievementLevel(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _getAchievementLevelColor(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Progress to next milestone
                          if (_pointsEarned < 1000) ...[
                            Text(
                              'Next: ${_getNextMilestone()}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: darkGray.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 200,
                              height: 6,
                              decoration: BoxDecoration(
                                color: lightGray,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _getProgressToNextMilestone(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getAchievementLevelColor(),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Edit button in top right corner
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.photo_camera, color: softGreen),
                                      title: Text('Take Photo', style: GoogleFonts.poppins()),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _pickImageFromCamera();
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.photo_library, color: softGreen),
                                      title: Text('Choose from Gallery', style: GoogleFonts.poppins()),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _pickImage();
                                      },
                                    ),
                                    if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                      ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
                                        title: Text('Remove Avatar', style: GoogleFonts.poppins(color: Colors.red)),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _removeAvatar();
                                        },
                                      ),
                                    ListTile(
                                      leading: Icon(Icons.edit, color: softGreen),
                                      title: Text('Edit Username', style: GoogleFonts.poppins()),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          _isEditingUsername = true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Cancel'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.edit, color: softGreen, size: 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            shape: CircleBorder(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Statistics
                Text(
                  'Statistics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                ),
                const SizedBox(height: 12),
                _isLoadingStats
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
                    ),
                    _buildStatCard(
                      title: 'Current Streak',
                      value: '$_currentStreak days',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      title: 'Points Earned',
                      value: _formatNumber(_pointsEarned),
                      icon: Icons.stars,
                      color: Colors.amber,
                    ),
                    _buildStatCard(
                      title: 'Badges Earned',
                      value: _formatNumber(_badgesEarned),
                      icon: Icons.emoji_events,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Profile Options

                Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileCard(
                  title: 'Edit Profile',
                  icon: Icons.person_outline,
                  onTap: () {
                    navigateWithSlide(context, EditProfilePage());
                  },
                ),
                _buildProfileCard(
                  title: 'Achievements',
                  icon: Icons.emoji_events_outlined,
                  onTap: () {
                    // TODO: Navigate to achievements screen
                  },
                ),
                _buildProfileCard(
                  title: 'Statistics',
                  icon: Icons.analytics_outlined,
                  onTap: () {
                    navigateWithSlide(context, Statistics());
                  },
                ),
                _buildProfileCard(
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    // TODO: Navigate to notifications settings
                  },
                ),
                _buildProfileCard(
                  title: 'Privacy Settings',
                  icon: Icons.security_outlined,
                  onTap: () {
                    // TODO: Navigate to privacy settings
                  },
                ),
                _buildProfileCard(
                  title: 'Help & Support',
                  icon: Icons.help_outline,
                  onTap: () {
                    // TODO: Navigate to help screen
                  },
                ),
                _buildProfileCard(
                  title: 'Sign Out',
                  icon: Icons.logout,
                  onTap: _signOut,
                  iconColor: Colors.red,
                ),
              ],
            ),
<<<<<<< HEAD
          ),
        )
=======
            const SizedBox(height: 12),
            _buildProfileCard(
              title: 'Edit Profile',
              icon: Icons.person_outline,
              onTap: () {
                _showEditProfileDialog();
              },
            ),
            _buildProfileCard(
              title: 'Achievements',
              icon: Icons.emoji_events_outlined,
              onTap: () {
                _showAchievementsDialog();
              },
            ),
            _buildProfileCard(
              title: 'Statistics',
              icon: Icons.analytics_outlined,
              onTap: () {
                _showDetailedStatisticsDialog();
              },
            ),
            _buildProfileCard(
              title: 'Notifications',
              icon: Icons.notifications_outlined,
              onTap: () {
                _showNotificationSettingsDialog();
              },
            ),
            _buildProfileCard(
              title: 'Privacy Settings',
              icon: Icons.security_outlined,
              onTap: () {
                _showPrivacySettingsDialog();
              },
            ),
            _buildProfileCard(
              title: 'Help & Support',
              icon: Icons.help_outline,
              onTap: () {
                _showHelpSupportDialog();
              },
            ),
            _buildProfileCard(
              title: 'Sign Out',
              icon: Icons.logout,
              onTap: _signOut,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
      )
>>>>>>> 8a4d85730ba1b3c725a4b24d0d653b3f03532524
    );
  }
}