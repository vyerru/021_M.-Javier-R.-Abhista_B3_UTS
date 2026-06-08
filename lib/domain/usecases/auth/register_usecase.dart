import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<User> call({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) {
    return _repository.register(
      username: username,
      password: password,
      fullName: fullName,
      email: email,
    );
  }
}
