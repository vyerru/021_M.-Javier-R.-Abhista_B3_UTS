import '../../entities/comment.dart';
import '../../repositories/comment_repository.dart';

class GetCommentsUseCase {
  final CommentRepository _repository;

  GetCommentsUseCase(this._repository);

  Future<List<Comment>> call(String ticketId) => _repository.getComments(ticketId);
}
