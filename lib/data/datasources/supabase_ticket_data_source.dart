import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_dto.dart';
import '../models/ticket_history_dto.dart';

class SupabaseTicketDataSource {
  final SupabaseClient client;

  SupabaseTicketDataSource(this.client);

  Future<List<TicketDto>> getTickets({String? statusFilter, int page = 0, int pageSize = 20}) async {
    var query = client.from('tickets').select(
      '*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)',
    );

    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }

    final from = page * pageSize;
    final to = from + pageSize - 1;
    final data = await query
        .order('created_at', ascending: false)
        .range(from, to);
    return (data as List)
        .map((e) => TicketDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TicketDto> getTicketById(String id) async {
    final data = await client
        .from('tickets')
        .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
        .eq('id', id)
        .single();

    return TicketDto.fromJson(data);
  }

  Future<TicketDto> createTicket(Map<String, dynamic> ticketData) async {
    final data = await client
        .from('tickets')
        .insert(ticketData)
        .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
        .single();

    return TicketDto.fromJson(data);
  }

  Future<TicketDto> updateStatus(String ticketId, String newStatus) async {
    final data = await client
        .from('tickets')
        .update({'status': newStatus})
        .eq('id', ticketId)
        .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
        .single();

    return TicketDto.fromJson(data);
  }

  Future<TicketDto> assignAndSetInProgress(String ticketId, String assigneeId) async {
    final data = await client
        .from('tickets')
        .update({'assigned_to': assigneeId, 'status': 'inprogress'})
        .eq('id', ticketId)
        .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
        .single();

    return TicketDto.fromJson(data);
  }

  Future<void> updateAttachmentUrls(String ticketId, List<String> urls) async {
    await client
        .from('tickets')
        .update({'attachment_urls': urls})
        .eq('id', ticketId);
  }

  Future<Map<String, int>> getStatistics({String? userId}) async {
    final params = <String, dynamic>{};
    if (userId != null) {
      params['user_id'] = userId;
    }
    final data = await client.rpc('get_statistics', params: params);
    final rows = data as List;
    final row = rows.isNotEmpty ? rows.first as Map<String, dynamic> : <String, dynamic>{};
    return {
      'total': (row['total'] as num).toInt(),
      'open': (row['open'] as num).toInt(),
      'inprogress': (row['inprogress'] as num).toInt(),
      'assign': (row['assign'] as num).toInt(),
      'closed': (row['closed'] as num).toInt(),
    };
  }

  Future<List<Map<String, dynamic>>> getHelpdeskUsers() async {
    final data = await client
        .from('users')
        .select()
        .eq('role', 'helpdesk')
        .order('full_name');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<TicketHistoryDto>> getHistory(String ticketId) async {
    final data = await client
        .from('ticket_history')
        .select('*, changed_by:users!changed_by(*)')
        .eq('ticket_id', ticketId)
        .order('timestamp', ascending: true);

    return (data as List)
        .map((e) => TicketHistoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addHistory(Map<String, dynamic> historyData) async {
    await client.from('ticket_history').insert(historyData);
  }
}
