import 'enums.dart';
import 'ticket.dart';

extension TicketPermission on Ticket {
  bool canChangeStatusBy(UserRole role) {
    if (role == UserRole.admin && status == TicketStatus.open) return true;
    if (role == UserRole.helpdesk && status == TicketStatus.inprogress) return true;
    return false;
  }

  bool canBeAssignedBy(UserRole role) {
    return role == UserRole.admin && status == TicketStatus.assign;
  }

  List<TicketStatus> availableStatusesFor(UserRole role) {
    if (role == UserRole.admin && status == TicketStatus.open) return [TicketStatus.assign];
    if (role == UserRole.helpdesk && status == TicketStatus.inprogress) return [TicketStatus.closed];
    return [];
  }
}
