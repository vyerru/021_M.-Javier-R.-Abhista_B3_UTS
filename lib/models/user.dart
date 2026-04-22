import 'enums.dart';

/// Model data untuk pengguna aplikasi.
///
/// Mendukung tiga role: [UserRole.user], [UserRole.helpdesk], [UserRole.admin].
class User {
  final int id;
  final String username;
  final String password; // Hanya untuk simulasi; jangan simpan plain-text di production.
  final String fullName;
  final String email;
  final String avatarUrl;
  final UserRole role;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  /// Membuat salinan [User] dengan nilai yang diperbarui.
  User copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? email,
    String? avatarUrl,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
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