import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/post_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<UserModel>> fetchLeaderboardUsers() async {
    final snapshot = await _db
        .collection('users')
        .orderBy('points', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create a new post
  Future<void> createPost(PostModel post) async {
    try {
      await _db.collection('posts').doc(post.postId).set(post.toMap());
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Get posts for a user
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final snapshot = await _db
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  // Get all posts for community feed
  Future<List<PostModel>> getAllPosts() async {
    try {
      final snapshot = await _db
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _db.collection('posts').doc(postId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _db.collection('posts').doc(postId).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  // Add comment to a post
  Future<void> addComment(String postId, Comment comment) async {
    try {
      await _db.collection('posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Complete task and update user points
  Future<void> completeTask(String userId, String taskId, int taskPoints) async {
    try {
      // Update user points
      await _db.collection('users').doc(userId).update({
        'points': FieldValue.increment(taskPoints),
        'tasksCompleted': FieldValue.arrayUnion([taskId]),
      });
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  // Get user data including points and completed tasks
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }
} 