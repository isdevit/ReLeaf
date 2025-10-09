import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskRecommender {
  static const List<String> allTags = ['eco', 'wealth', 'health'];
  Interpreter? _interpreter;
  bool _modelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('task_recommender_model.tflite');
      _modelLoaded = true;
    } catch (e) {
      _interpreter = null;
      _modelLoaded = false;
    }
  }

  Future<List<String>> getCompletedTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return List<String>.from(doc.data()?['tasksCompleted'] ?? []);
  }

  Future<List<String>> getTagsForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return [];
    final tasks = await FirebaseFirestore.instance
        .collection('tasks')
        .where(FieldPath.documentId, whereIn: taskIds)
        .get();
    final tags = <String>{};
    for (var doc in tasks.docs) {
      tags.addAll(List<String>.from(doc['tags'] ?? []));
    }
    return tags.toList();
  }

  List<double> generateTagVector(List<String> tags) {
    return allTags.map((tag) => tags.contains(tag) ? 1.0 : 0.0).toList();
  }

  Future<List<String>> predictTopTags(List<double> tagVector) async {
    if (!_modelLoaded || _interpreter == null) return allTags.take(2).toList(); // fallback
    var input = [tagVector];
    var output = List.filled(allTags.length, 0.0).reshape([1, allTags.length]);
    _interpreter!.run(input, output);
    final probs = output[0];
    final tagProbs = List.generate(allTags.length, (i) => MapEntry(allTags[i], probs[i]));
    tagProbs.sort((a, b) => b.value.compareTo(a.value));
    return tagProbs.take(2).map((e) => e.key).toList();
  }

  Future<List<Map<String, dynamic>>> fetchRecommendedTasks(List<String> topTags, List<String> completed) async {
    if (topTags.isEmpty) return mockTasks('eco');
    final query = await FirebaseFirestore.instance
        .collection('tasks')
        .where('tags', arrayContainsAny: topTags)
        .get();
    final tasks = query.docs
        .where((doc) => !completed.contains(doc.id))
        .take(3)
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
    if (tasks.isEmpty) return mockTasks(topTags.first);
    return tasks;
  }

  Future<List<Map<String, dynamic>>> fetchWeeklyTasks(List<String> completed) async {
    final query = await FirebaseFirestore.instance
        .collection('tasks')
        .orderBy(FieldPath.documentId)
        .limit(10)
        .get();
    final tasks = query.docs
        .where((doc) => !completed.contains(doc.id))
        .take(5)
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
    if (tasks.isEmpty) return mockTasks('eco');
    return tasks;
  }

  // Fallback for testing
  List<Map<String, dynamic>> mockTasks(String tag) => [
    {
      'name': 'Mock Task 1',
      'description': 'Description for mock task 1',
      'tags': [tag],
      'id': 'mock1'
    },
    {
      'name': 'Mock Task 2',
      'description': 'Description for mock task 2',
      'tags': [tag],
      'id': 'mock2'
    }
  ];
} 