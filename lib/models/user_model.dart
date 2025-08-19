class UserModel {
  final String id;
  final String username;
  final int points;
  final String avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.points,
    required this.avatarUrl,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      username: data['username'] ?? '',
      points: data['points'] ?? 0,
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }
} 