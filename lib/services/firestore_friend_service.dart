import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreFriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _me() => _auth.currentUser?.uid ?? '';

  Future<List<Map<String, dynamic>>> searchUsersByUsername(String query, {int limit = 20}) async {
    // Assumes 'users' collection has 'usernameLower' for case-insensitive search
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return <Map<String, dynamic>>[];
    final snapshot = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> sendFriendRequest(String toUserId) async {
    final String from = _me();
    final String docId = from.compareTo(toUserId) < 0 ? '${from}_$toUserId' : '${toUserId}_$from';
    await _db.collection('friend_requests').doc(docId).set({
      'from': from,
      'to': toUserId,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: false));
  }

  Future<void> acceptFriendRequest(String fromUserId) async {
    final String me = _me();
    final String docId = fromUserId.compareTo(me) < 0 ? '${fromUserId}_$me' : '${me}_$fromUserId';
    final WriteBatch batch = _db.batch();
    final requestRef = _db.collection('friend_requests').doc(docId);
    batch.update(requestRef, {'status': 'accepted', 'acceptedAt': DateTime.now().millisecondsSinceEpoch});
    batch.set(_db.collection('friends').doc(me).collection('list').doc(fromUserId), {
      'userId': fromUserId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    batch.set(_db.collection('friends').doc(fromUserId).collection('list').doc(me), {
      'userId': me,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    await batch.commit();
  }

  Future<void> declineFriendRequest(String fromUserId) async {
    final String me = _me();
    final String docId = fromUserId.compareTo(me) < 0 ? '${fromUserId}_$me' : '${me}_$fromUserId';
    await _db.collection('friend_requests').doc(docId).update({'status': 'declined'});
  }

  Stream<List<Map<String, dynamic>>> incomingRequestsStream() {
    final String me = _me();
    return _db
        .collection('friend_requests')
        .where('to', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> friendsStream() {
    final String me = _me();
    return _db
        .collection('friends')
        .doc(me)
        .collection('list')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...?doc.data()};
  }

  Stream<Map<String, dynamic>?> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) => doc.exists ? {'id': doc.id, ...?doc.data()} : null);
  }
}


