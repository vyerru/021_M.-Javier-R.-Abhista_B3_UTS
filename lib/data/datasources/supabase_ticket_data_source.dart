import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_dto.dart';

class SupabaseTicketDataSource {
  final SupabaseClient client;

  SupabaseTicketDataSource(this.client);

  Future<List<TicketDto>> getTickets({String? statusFilter}) async {
    var query = client.from('tickets').select(
      '*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)',
    );

    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }

    final data = await query.order('created_at', ascending: false);
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

  Future<TicketDto> assignTicket(String ticketId, String assigneeId) async {
    final data = await client
        .from('tickets')
        .update({'assigned_to': assigneeId})
        .eq('id', ticketId)
        .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
        .single();

    return TicketDto.fromJson(data);
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
      'inProgress': (row['inProgress'] as num).toInt(),
      'resolved': (row['resolved'] as num).toInt(),
      'closed': (row['closed'] as num).toInt(),
    };
  }

  Future<List<Map<String, dynamic>>> getHelpdeskUsers() async {
    final data = await client
        .from('users')
        .select()
        .inFilter('role', ['helpdesk', 'admin'])
        .order('full_name');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> addHistory(Map<String, dynamic> historyData) async {
    await client.from('ticket_history').insert(historyData);
  }
}
