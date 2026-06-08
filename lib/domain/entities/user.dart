import 'enums.dart';

class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String avatarUrl;
  final UserRole role;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? avatarUrl,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'User(id: $id, username: $username, role: ${role.label})';
}
