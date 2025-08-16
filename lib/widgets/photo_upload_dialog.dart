import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class PhotoUploadDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onUploadComplete;

  const PhotoUploadDialog({
    super.key,
    required this.task,
    this.onUploadComplete,
  });

  @override
  State<PhotoUploadDialog> createState() => _PhotoUploadDialogState();
}

class _PhotoUploadDialogState extends State<PhotoUploadDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  File? _selectedImage;
  bool _isUploading = false;
  String? _username;
  String? _avatarUrl;

  // Color palette
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _username = doc.data()?['username'] ?? user.email ?? 'User';
        _avatarUrl = doc.data()?['avatarUrl'] ?? '';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        // For now, use the image as-is. We'll implement custom cropping later
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // Show info about aspect ratio
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image selected! For best results, ensure your image has a 16:9 aspect ratio.'),
              backgroundColor: softGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image first');
      return;
    }

    if (_captionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please add a caption');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate unique post ID
      final postId = 'post_${DateTime.now().millisecondsSinceEpoch}_${user.uid}';
      
      // Upload image to Firebase Storage
      final imagePath = 'posts/${user.uid}/$postId.jpg';
      final imageUrl = await _firestoreService.uploadImage(_selectedImage!, imagePath);

      // Create post data
      final post = PostModel(
        postId: postId,
        userId: user.uid,
        username: _username ?? 'User',
        userAvatarUrl: _avatarUrl ?? '',
        imageUrl: imageUrl,
        caption: _captionController.text.trim(),
        tags: (widget.task['tags'] as List?)?.cast<String>() ?? [],
        timestamp: DateTime.now(),
        isChallengePost: true,
        relatedTaskId: widget.task['id'] ?? widget.task['name'],
        location: 'Bangalore, India', // You can make this dynamic later
      );

      // Save post to Firestore
      await _firestoreService.createPost(post);

      // Complete the task and add points
      final taskId = widget.task['id'] ?? widget.task['name'];
      final taskPoints = widget.task['points'] ?? 10; // Default 10 points if not specified
      
      await _firestoreService.completeTask(user.uid, taskId, taskPoints);

      // Show success message with points earned
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task completed! +$taskPoints points earned! 🎉'),
            backgroundColor: softGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Close dialog and notify parent
        Navigator.of(context).pop();
        widget.onUploadComplete?.call();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to upload: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: BoxConstraints(
          maxHeight: isKeyboardVisible 
              ? MediaQuery.of(context).size.height * 0.6
              : MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.verified_rounded, color: softGreen, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete Task',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: darkGray.withOpacity(0.6)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a picture as proof of completion for:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: darkGray.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.task['name'] ?? 'Task',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Image selection
                if (_selectedImage == null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageSourceButton(
                        icon: Icons.photo_camera,
                        label: 'Camera',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      _buildImageSourceButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ] else ...[
                  // Selected image preview
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: softGreen, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedImage = null),
                        icon: Icon(Icons.refresh, color: softGreen),
                        label: Text('Change Photo', style: TextStyle(color: softGreen)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Caption input
                TextField(
                  controller: _captionController,
                  decoration: InputDecoration(
                    hintText: 'Add a caption describing your completion...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: darkGray.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: lightGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: softGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.poppins(fontSize: 14),
                  onTap: () {
                    // Scroll to caption field when focused
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Upload button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedImage != null && !_isUploading ? _uploadPhoto : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: softGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Uploading...',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Complete Task & Share',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                // Add some bottom padding to ensure button is visible above keyboard
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: softGreen.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: softGreen),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
