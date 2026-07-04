import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<User> updateProfile({
    required String id,
    required String fullName,
    required String username,
    String? avatarUrl,
  });
  Future<void> resetPassword(String email);
}
