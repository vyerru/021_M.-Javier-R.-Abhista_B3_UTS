import '../entities/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getComments(String ticketId);
  Future<Comment> addComment({
    required String ticketId,
    required String authorId,
    required String message,
  });
}
