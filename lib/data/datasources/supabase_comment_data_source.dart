import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_dto.dart';

class SupabaseCommentDataSource {
  final SupabaseClient client;

  SupabaseCommentDataSource(this.client);

  Future<List<CommentDto>> getComments(String ticketId) async {
    final data = await client
        .from('comments')
        .select('*, author:users(*)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => CommentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentDto> addComment(Map<String, dynamic> commentData) async {
    final data = await client
        .from('comments')
        .insert(commentData)
        .select('*, author:users(*)')
        .single();

    return CommentDto.fromJson(data);
  }
}
