import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<User> login(String email, String password) async {
    final dto = await _dataSource.login(email, password);
    return dto.toEntity();
  }

  @override
  Future<User> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) async {
    final dto = await _dataSource.register(
      email: email,
      password: password,
      username: username,
      fullName: fullName,
    );
    return dto.toEntity();
  }

  @override
  Future<void> logout() async {
    await _dataSource.logout();
  }

  @override
  Future<User?> getCurrentUser() async {
    final dto = await _dataSource.getCurrentUser();
    return dto?.toEntity();
  }

  @override
  Future<User> updateProfile({
    required String id,
    required String fullName,
    required String username,
    String? avatarUrl,
  }) async {
    final dto = await _dataSource.updateProfile(
      id: id,
      fullName: fullName,
      username: username,
      avatarUrl: avatarUrl,
    );
    return dto.toEntity();
  }
}
