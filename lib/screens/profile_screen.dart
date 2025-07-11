import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/sign_in_screen.dart';

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _username = doc.data()?['username'] ?? 'User';
          _avatarUrl = doc.data()?['avatarUrl'] ?? '';
        });
        _usernameController.text = _username;
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
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final file = File(pickedImage.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', file.path);
      setState(() {
        _imageFile = file;
      });
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
      body: SingleChildScrollView(
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
                                  leading: Icon(Icons.person, color: softGreen),
                                  title: Text('Change Avatar', style: GoogleFonts.poppins()),
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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  title: 'Tasks Completed',
                  value: '24',
                  icon: Icons.check_circle,
                  color: softGreen,
                ),
                _buildStatCard(
                  title: 'Current Streak',
                  value: '7 days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  title: 'Points Earned',
                  value: '1,250',
                  icon: Icons.stars,
                  color: Colors.amber,
                ),
                _buildStatCard(
                  title: 'Badges Earned',
                  value: '8',
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
                // TODO: Navigate to edit profile screen
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
                // TODO: Navigate to detailed statistics screen
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
      ),
    );
  }
}