import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/supabase_comment_data_source.dart';

class CommentRepositoryImpl implements CommentRepository {
  final SupabaseCommentDataSource _dataSource;

  CommentRepositoryImpl(this._dataSource);

  @override
  Future<List<Comment>> getComments(String ticketId) async {
    final dtoList = await _dataSource.getComments(ticketId);
    return dtoList.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Comment> addComment({
    required String ticketId,
    required String authorId,
    required String message,
  }) async {
    final dto = await _dataSource.addComment({
      'ticket_id': ticketId,
      'author_id': authorId,
      'message': message,
      'attachment_urls': <String>[],
      'created_at': DateTime.now().toIso8601String(),
    });
    return dto.toEntity();
  }
}
