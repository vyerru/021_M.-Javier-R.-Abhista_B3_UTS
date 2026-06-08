import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_dto.dart';

class SupabaseAuthDataSource {
  final SupabaseClient _client;

  SupabaseAuthDataSource(this._client);

  Future<UserDto> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw Exception('Login failed');

    final userData = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return UserDto.fromJson(userData);
  }

  Future<UserDto> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw Exception('Registration failed');

    final newUser = {
      'id': user.id,
      'username': username,
      'full_name': fullName,
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
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<UserDto?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final userId = session.user.id;

    final userData = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return UserDto.fromJson(userData);
  }

  Future<UserDto> updateProfile({
    required String id,
    required String fullName,
    required String username,
    String? avatarUrl,
  }) async {
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
  }
}
