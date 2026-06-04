import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<User> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
}
