import '../../entities/comment.dart';
import '../../repositories/comment_repository.dart';

class AddCommentUseCase {
  final CommentRepository _repository;

  AddCommentUseCase(this._repository);

  Future<Comment> call({
    required String ticketId,
    required String authorId,
    required String message,
  }) {
    return _repository.addComment(
      ticketId: ticketId,
      authorId: authorId,
      message: message,
    );
  }
}
