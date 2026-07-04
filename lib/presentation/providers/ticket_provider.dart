import 'package:flutter/foundation.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/comments/add_comment_usecase.dart';
import '../../domain/usecases/comments/get_comments_usecase.dart';
import '../../domain/usecases/tickets/ticket_usecases.dart';

class TicketProvider extends ChangeNotifier {
  final GetTicketsUseCase _getTicketsUseCase;
  final GetTicketByIdUseCase _getTicketByIdUseCase;
  final CreateTicketUseCase _createTicketUseCase;
  final UpdateTicketStatusUseCase _updateTicketStatusUseCase;
  final AssignTicketUseCase _assignTicketUseCase;
  final GetStatisticsUseCase _getStatisticsUseCase;
  final GetHelpdeskUsersUseCase _getHelpdeskUsersUseCase;
  final AddCommentUseCase _addCommentUseCase;
  final GetCommentsUseCase _getCommentsUseCase;

  List<Ticket> _tickets = [];
  List<Ticket> _activeTickets = [];
  Ticket? _selectedTicket;
  Map<String, int>? _statistics;
  List<User> _helpdeskUsers = [];
  TicketStatus? _selectedStatus;
  bool _isLoading = false;
  String? _error;

  TicketProvider({
    required GetTicketsUseCase getTicketsUseCase,
    required GetTicketByIdUseCase getTicketByIdUseCase,
    required CreateTicketUseCase createTicketUseCase,
    required UpdateTicketStatusUseCase updateTicketStatusUseCase,
    required AssignTicketUseCase assignTicketUseCase,
    required GetStatisticsUseCase getStatisticsUseCase,
    required GetHelpdeskUsersUseCase getHelpdeskUsersUseCase,
    required AddCommentUseCase addCommentUseCase,
    required GetCommentsUseCase getCommentsUseCase,
  })  : _getTicketsUseCase = getTicketsUseCase,
        _getTicketByIdUseCase = getTicketByIdUseCase,
        _createTicketUseCase = createTicketUseCase,
        _updateTicketStatusUseCase = updateTicketStatusUseCase,
        _assignTicketUseCase = assignTicketUseCase,
        _getStatisticsUseCase = getStatisticsUseCase,
        _getHelpdeskUsersUseCase = getHelpdeskUsersUseCase,
        _addCommentUseCase = addCommentUseCase,
        _getCommentsUseCase = getCommentsUseCase;

  List<Ticket> get tickets => _tickets;
  List<Ticket> get activeTickets => _activeTickets;
  Ticket? get selectedTicket => _selectedTicket;
  Map<String, int>? get statistics => _statistics;
  List<User> get helpdeskUsers => _helpdeskUsers;
  TicketStatus? get selectedStatus => _selectedStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTickets({TicketStatus? statusFilter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedStatus = statusFilter;
      _tickets = await _getTicketsUseCase.call(statusFilter: statusFilter);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final all = await _getTicketsUseCase.call();
      _activeTickets = all.where((t) => t.status != TicketStatus.closed).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTicketDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTicket = await _getTicketByIdUseCase.call(id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTicket(Ticket ticket) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _createTicketUseCase.call(ticket);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String ticketId, TicketStatus newStatus) async {
    try {
      _selectedTicket = await _updateTicketStatusUseCase.call(ticketId, newStatus);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTicket(String ticketId, String assigneeId) async {
    try {
      _selectedTicket = await _assignTicketUseCase.call(ticketId, assigneeId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadStatistics({String? userId}) async {
    try {
      _statistics = await _getStatisticsUseCase.call(userId: userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadHelpdeskUsers() async {
    try {
      _helpdeskUsers = await _getHelpdeskUsersUseCase.call();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addComment(String ticketId, String authorId, String message) async {
    try {
      await _addCommentUseCase.call(
        ticketId: ticketId,
        authorId: authorId,
        message: message,
      );
      await loadTicketDetail(ticketId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Comment>> loadComments(String ticketId) async {
    try {
      return await _getCommentsUseCase.call(ticketId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
