enum TicketStatus {
  open,
  assign,
  inprogress,
  closed;

  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.assign:
        return 'Assign';
      case TicketStatus.inprogress:
        return 'In Progress';
      case TicketStatus.closed:
        return 'Closed';
    }
  }
}

enum TicketPriority {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.critical:
        return 'Critical';
    }
  }
}

enum UserRole {
  user,
  helpdesk,
  admin;

  String get label {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.helpdesk:
        return 'Helpdesk';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
