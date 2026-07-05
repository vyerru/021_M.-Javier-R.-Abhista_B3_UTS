import '../../repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  final AuthRepository _repository;

  UpdatePasswordUseCase(this._repository);

  Future<void> call(String newPassword) {
    return _repository.updatePassword(newPassword);
  }
}
