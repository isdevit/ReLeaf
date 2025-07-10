import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<UserModel>> fetchLeaderboardUsers() async {
    final snapshot = await _db
        .collection('users')
        .orderBy('points', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }
} 