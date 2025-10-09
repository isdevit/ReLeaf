import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'EditProfilePage.dart';
import 'auth/sign_in_screen.dart';



class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<EditProfilePage> {
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
<<<<<<< HEAD

=======
               
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c



              ],
            ),
          ),
        )
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 0fb0b911fc688522f55327033b32c28e239d988c
