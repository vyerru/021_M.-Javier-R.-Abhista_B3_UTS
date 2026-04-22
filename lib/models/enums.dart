/// Enumerasi untuk status tiket helpdesk.
enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  /// Label tampilan untuk UI.
  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }
}

/// Enumerasi untuk prioritas tiket.
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

/// Enumerasi untuk role pengguna.
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