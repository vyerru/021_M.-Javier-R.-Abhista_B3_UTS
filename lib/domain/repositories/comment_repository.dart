import '../entities/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getComments(int ticketId);
  Future<Comment> addComment({
    required int ticketId,
    required int authorId,
    required String message,
  });
}
