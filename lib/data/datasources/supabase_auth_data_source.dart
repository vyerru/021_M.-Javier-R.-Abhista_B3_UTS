import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_dto.dart';

class SupabaseAuthDataSource {
  final SupabaseClient _client;

  SupabaseAuthDataSource(this._client);

  Future<UserDto> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw Exception('Login gagal. Silakan coba lagi.');

      final userData = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserDto.fromJson(userData);
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e.message));
    } catch (e) {
      throw Exception(_mapGenericError(e));
    }
  }

  Future<UserDto> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw Exception('Registrasi gagal. Silakan coba lagi.');

      final newUser = {
        'id': user.id,
        'username': username,
        'full_name': fullName,
        'email': email,
        'avatar_url': '',
        'role': 'user',
      };

      await _client.from('users').insert(newUser);

      final userData = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserDto.fromJson(userData);
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e.message));
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      throw Exception(_mapGenericError(e));
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<UserDto?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;

      final userId = session.user.id;

      final userData = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserDto.fromJson(userData);
    } catch (_) {
      return null;
    }
  }

  Future<UserDto> updateProfile({
    required String id,
    required String fullName,
    required String username,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'full_name': fullName,
        'username': username,
      };
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _client.from('users').update(updates).eq('id', id);

      final userData = await _client
          .from('users')
          .select()
          .eq('id', id)
          .single();

      return UserDto.fromJson(userData);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      throw Exception(_mapGenericError(e));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e.message));
    } catch (e) {
      throw Exception(_mapGenericError(e));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        AdminUserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e.message));
    } catch (e) {
      throw Exception(_mapGenericError(e));
    }
  }

  String _mapAuthError(String message) {
    switch (message) {
      case 'Invalid login credentials':
        return 'Email atau password salah';
      case 'Email not confirmed':
        return 'Email belum dikonfirmasi. Silakan cek inbox email Anda';
      case 'User already registered':
        return 'Email sudah terdaftar';
      case 'Password should be at least 6 characters':
        return 'Password minimal 6 karakter';
      case 'Signup requires a valid password':
        return 'Password tidak boleh kosong';
      default:
        return message;
    }
  }

  String _mapPostgrestError(PostgrestException e) {
    if (e.code == '23505') {
      if (e.message.contains('username')) return 'Username sudah digunakan';
      if (e.message.contains('email')) return 'Email sudah terdaftar';
      return 'Data sudah ada';
    }
    if (e.code == '23503') return 'Data terkait tidak ditemukan';
    if (e.code == '42P01') return 'Terjadi kesalahan sistem';
    return e.message;
  }

  String _mapGenericError(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('HandshakeException')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda';
    }
    if (text.contains('TimeoutException')) {
      return 'Koneksi timeout. Silakan coba lagi';
    }
    return 'Terjadi kesalahan. Silakan coba lagi';
  }
}
