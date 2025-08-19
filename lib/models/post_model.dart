import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String userId;
  final String username;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          return DateTime.now();
        }
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return DateTime.now();
      }
    }

    return Comment(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      text: map['text'] ?? '',
      timestamp: parseTimestamp(map['timestamp']),
    );
  }
}

class PostModel {
  final String postId;
  final String userId;
  final String username;
  final String userAvatarUrl;
  final String imageUrl;
  final String caption;
  final List<String> tags;
  final int likes;
  final List<String> likedBy;
  final List<Comment> comments;
  final int shares;
  final DateTime timestamp;
  final bool isChallengePost;
  final String? relatedTaskId;
  final String? location;

  PostModel({
    required this.postId,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.tags,
    this.likes = 0,
    this.likedBy = const [],
    this.comments = const [],
    this.shares = 0,
    required this.timestamp,
    this.isChallengePost = false,
    this.relatedTaskId,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'tags': tags,
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'shares': shares,
      'timestamp': Timestamp.fromDate(timestamp),
      'isChallengePost': isChallengePost,
      'relatedTaskId': relatedTaskId,
      'location': location,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          return DateTime.now();
        }
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return DateTime.now();
      }
    }

    return PostModel(
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userAvatarUrl: map['userAvatarUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      likes: map['likes'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      comments: (map['comments'] as List<dynamic>?)
              ?.map((comment) => Comment.fromMap(comment))
              .toList() ??
          [],
      shares: map['shares'] ?? 0,
      timestamp: parseTimestamp(map['timestamp']),
      isChallengePost: map['isChallengePost'] ?? false,
      relatedTaskId: map['relatedTaskId'],
      location: map['location'],
    );
  }

  PostModel copyWith({
    String? postId,
    String? userId,
    String? username,
    String? userAvatarUrl,
    String? imageUrl,
    String? caption,
    List<String>? tags,
    int? likes,
    List<String>? likedBy,
    List<Comment>? comments,
    int? shares,
    DateTime? timestamp,
    bool? isChallengePost,
    String? relatedTaskId,
    String? location,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      timestamp: timestamp ?? this.timestamp,
      isChallengePost: isChallengePost ?? this.isChallengePost,
      relatedTaskId: relatedTaskId ?? this.relatedTaskId,
      location: location ?? this.location,
    );
  }
}
