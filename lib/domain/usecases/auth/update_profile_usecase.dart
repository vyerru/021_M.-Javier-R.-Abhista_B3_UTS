import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<User> call({
    required String id,
    required String fullName,
    required String username,
    String? avatarUrl,
  }) {
    return _repository.updateProfile(
      id: id,
      fullName: fullName,
      username: username,
      avatarUrl: avatarUrl,
    );
  }
}
