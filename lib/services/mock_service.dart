import '../domain/entities/entities.dart';

/// Kelas exception kustom untuk error autentikasi.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Kelas exception kustom untuk error operasi tiket.
class TicketException implements Exception {
  final String message;
  const TicketException(this.message);

  @override
  String toString() => 'TicketException: $message';
}

/// Service utama yang mengelola semua data dummy dan logika bisnis sisi client.
///
/// Menggunakan **Singleton Pattern** — akses selalu lewat [MockService.instance].
///
/// Semua fungsi async mensimulasikan network latency dengan [Future.delayed]
/// agar UI dapat menampilkan loading indicator yang realistis.
class MockService {
  // ─── Singleton Setup ────────────────────────────────────────────────────────

  MockService._internal();
  static final MockService _instance = MockService._internal();

  /// Satu-satunya titik akses ke instance [MockService].
  static MockService get instance => _instance;

  // ─── State Global ────────────────────────────────────────────────────────────

  /// Pengguna yang sedang login. `null` jika belum login.
  static User? currentUser;

  /// Counter untuk auto-increment ID tiket baru.
  static int _ticketIdCounter = 16;

  /// Counter untuk auto-increment ID komentar baru.
  static int _commentIdCounter = 100;

  /// Counter untuk auto-increment ID history baru.
  static int _historyIdCounter = 200;

  /// Counter untuk auto-increment ID notifikasi baru.
  static int _notifIdCounter = 1;

  // ─── Seed Data: Users ────────────────────────────────────────────────────────

  /// Daftar pengguna terdaftar dalam sistem.
  static final List<User> _users = [
    User(
      id: 1,
      username: 'admin',
      password: 'admin123',
      fullName: 'Javier Rakha',
      email: 'admin@helpdesk.id',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      role: UserRole.admin,
      createdAt: DateTime(2024, 1, 10),
    ),
    User(
      id: 2,
      username: 'helpdesk1',
      password: 'helpdesk123',
      fullName: 'Surya Prakoso',
      email: 'siti@helpdesk.id',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      role: UserRole.helpdesk,
      createdAt: DateTime(2024, 1, 15),
    ),
    User(
      id: 3,
      username: 'helpdesk2',
      password: 'helpdesk123',
      fullName: 'Aditya Alif',
      email: 'andi@helpdesk.id',
      avatarUrl: 'https://i.pravatar.cc/150?img=7',
      role: UserRole.helpdesk,
      createdAt: DateTime(2024, 2, 1),
    ),
    User(
      id: 4,
      username: 'user1',
      password: 'user123',
      fullName: 'Muhammad Abhista',
      email: 'dewi@gmail.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      role: UserRole.user,
      createdAt: DateTime(2024, 3, 5),
    ),
    User(
      id: 5,
      username: 'user2',
      password: 'user123',
      fullName: 'Reza Firmansyah',
      email: 'reza@gmail.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      role: UserRole.user,
      createdAt: DateTime(2024, 3, 20),
    ),
    User(
      id: 6,
      username: 'user3',
      password: 'user123',
      fullName: 'Nita Kurniawan',
      email: 'nita@gmail.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=13',
      role: UserRole.user,
      createdAt: DateTime(2024, 4, 1),
    ),
  ];

  // Getter shorthand untuk user-user tertentu (dipakai saat seed tiket).
  static User get _admin => _users[0];
  static User get _helpdesk1 => _users[1];
  static User get _helpdesk2 => _users[2];
  static User get _user1 => _users[3];
  static User get _user2 => _users[4];
  static User get _user3 => _users[5];

  // ─── Seed Data: Tickets ──────────────────────────────────────────────────────

  /// Daftar tiket dummy — minimal 15 tiket dengan variasi status & prioritas.
  static final List<Ticket> _tickets = [
    // ── OPEN ────────────────────────────────────────────────────────────────────
    Ticket(
      id: 1,
      title: 'Komputer tidak bisa menyala',
      description:
          'Laptop saya tidak bisa dinyalakan sejak tadi pagi. Sudah dicoba charge tapi tetap tidak merespons.',
      status: TicketStatus.open,
      priority: TicketPriority.high,
      category: 'Hardware',
      createdBy: _user1,
      assignedTo: null,
      createdAt: DateTime(2026, 4, 20, 8, 30),
      updatedAt: DateTime(2026, 4, 20, 8, 30),
      history: [
        TicketHistory(
          id: 1,
          ticketId: 1,
          changedBy: _user1,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 20, 8, 30),
        ),
      ],
    ),
    Ticket(
      id: 2,
      title: 'Tidak bisa akses sistem SIAKAD',
      description:
          'Muncul error 403 Forbidden ketika login ke SIAKAD. Sudah coba reset password tapi tetap tidak bisa.',
      status: TicketStatus.open,
      priority: TicketPriority.critical,
      category: 'Software',
      createdBy: _user2,
      assignedTo: null,
      createdAt: DateTime(2026, 4, 21, 9, 0),
      updatedAt: DateTime(2026, 4, 21, 9, 0),
      history: [
        TicketHistory(
          id: 2,
          ticketId: 2,
          changedBy: _user2,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 21, 9, 0),
        ),
      ],
    ),
    Ticket(
      id: 3,
      title: 'Koneksi WiFi Lab B terputus-putus',
      description:
          'Sinyal WiFi di Lab B sangat tidak stabil. Sudah berlangsung 2 hari dan mengganggu kegiatan praktikum.',
      status: TicketStatus.open,
      priority: TicketPriority.medium,
      category: 'Network',
      createdBy: _user3,
      assignedTo: null,
      createdAt: DateTime(2026, 4, 22, 7, 15),
      updatedAt: DateTime(2026, 4, 22, 7, 15),
      history: [
        TicketHistory(
          id: 3,
          ticketId: 3,
          changedBy: _user3,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 22, 7, 15),
        ),
      ],
    ),
    Ticket(
      id: 4,
      title: 'Printer di ruang dosen macet',
      description:
          'Printer Canon MG3600 di ruang dosen lantai 3 macet dan mengeluarkan bunyi aneh saat mencetak.',
      status: TicketStatus.open,
      priority: TicketPriority.low,
      category: 'Hardware',
      createdBy: _user1,
      assignedTo: null,
      createdAt: DateTime(2026, 4, 22, 10, 45),
      updatedAt: DateTime(2026, 4, 22, 10, 45),
      history: [
        TicketHistory(
          id: 4,
          ticketId: 4,
          changedBy: _user1,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 22, 10, 45),
        ),
      ],
    ),
    Ticket(
      id: 5,
      title: 'Akun email kampus tidak aktif',
      description:
          'Email @student.unair.ac.id saya tidak bisa digunakan. Pesan error: "Account disabled".',
      status: TicketStatus.open,
      priority: TicketPriority.medium,
      category: 'Account',
      createdBy: _user2,
      assignedTo: null,
      createdAt: DateTime(2026, 4, 22, 11, 20),
      updatedAt: DateTime(2026, 4, 22, 11, 20),
      history: [
        TicketHistory(
          id: 5,
          ticketId: 5,
          changedBy: _user2,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 22, 11, 20),
        ),
      ],
    ),

    // ── IN PROGRESS ─────────────────────────────────────────────────────────────
    Ticket(
      id: 6,
      title: 'Software AutoCAD tidak bisa di-install',
      description:
          'Gagal install AutoCAD 2024, muncul error "Installation Failed" di tengah proses. Sudah dicoba 3 kali.',
      status: TicketStatus.inProgress,
      priority: TicketPriority.high,
      category: 'Software',
      createdBy: _user1,
      assignedTo: _helpdesk1,
      createdAt: DateTime(2026, 4, 18, 14, 0),
      updatedAt: DateTime(2026, 4, 19, 9, 30),
      comments: [
        Comment(
          id: 1,
          ticketId: 6,
          author: _helpdesk1,
          message:
              'Halo, saya sudah menerima tiket ini. Mohon pastikan spesifikasi minimum terpenuhi. Akan saya cek lisensi server AutoCAD.',
          createdAt: DateTime(2026, 4, 19, 9, 30),
        ),
      ],
      history: [
        TicketHistory(
          id: 6,
          ticketId: 6,
          changedBy: _user1,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 18, 14, 0),
        ),
        TicketHistory(
          id: 7,
          ticketId: 6,
          changedBy: _helpdesk1,
          action: 'Tiket di-assign dan status diperbarui',
          fromStatus: TicketStatus.open,
          toStatus: TicketStatus.inProgress,
          timestamp: DateTime(2026, 4, 19, 9, 30),
        ),
      ],
    ),
    Ticket(
      id: 7,
      title: 'Monitor bergaris horizontal',
      description:
          'Monitor di komputer nomor 12 Lab A muncul garis-garis horizontal. Sudah coba ganti kabel VGA tapi masalah sama.',
      status: TicketStatus.inProgress,
      priority: TicketPriority.medium,
      category: 'Hardware',
      createdBy: _user3,
      assignedTo: _helpdesk2,
      createdAt: DateTime(2026, 4, 17, 13, 0),
      updatedAt: DateTime(2026, 4, 18, 10, 0),
      comments: [
        Comment(
          id: 2,
          ticketId: 7,
          author: _helpdesk2,
          message:
              'Sudah saya cek, kemungkinan panel LCD-nya rusak. Sedang menunggu unit pengganti dari gudang.',
          createdAt: DateTime(2026, 4, 18, 10, 0),
        ),
      ],
      history: [
        TicketHistory(
          id: 8,
          ticketId: 7,
          changedBy: _user3,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 17, 13, 0),
        ),
        TicketHistory(
          id: 9,
          ticketId: 7,
          changedBy: _helpdesk2,
          action: 'Tiket di-assign ke Andi Wijaya',
          fromStatus: TicketStatus.open,
          toStatus: TicketStatus.inProgress,
          timestamp: DateTime(2026, 4, 18, 10, 0),
        ),
      ],
    ),
    Ticket(
      id: 8,
      title: 'VPN kampus tidak terkoneksi',
      description:
          'Tidak bisa terhubung ke VPN kampus dari rumah. Error: "Connection timed out". Penting untuk akses jurnal.',
      status: TicketStatus.inProgress,
      priority: TicketPriority.high,
      category: 'Network',
      createdBy: _user2,
      assignedTo: _helpdesk1,
      createdAt: DateTime(2026, 4, 16, 20, 0),
      updatedAt: DateTime(2026, 4, 17, 8, 0),
      comments: [
        Comment(
          id: 3,
          ticketId: 8,
          author: _helpdesk1,
          message:
              'Sedang kami investigasi dari sisi server VPN. Mohon berikan IP address yang Anda gunakan.',
          createdAt: DateTime(2026, 4, 17, 8, 0),
        ),
        Comment(
          id: 4,
          ticketId: 8,
          author: _user2,
          message: 'IP saya: 180.244.xxx.xxx (provider Indihome).',
          createdAt: DateTime(2026, 4, 17, 9, 15),
        ),
      ],
      history: [
        TicketHistory(
          id: 10,
          ticketId: 8,
          changedBy: _user2,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 16, 20, 0),
        ),
        TicketHistory(
          id: 11,
          ticketId: 8,
          changedBy: _admin,
          action: 'Tiket di-assign ke Siti Rahayu',
          fromStatus: TicketStatus.open,
          toStatus: TicketStatus.inProgress,
          timestamp: DateTime(2026, 4, 17, 8, 0),
        ),
      ],
    ),
    Ticket(
      id: 9,
      title: 'Keyboard laptop rusak beberapa tombol',
      description:
          'Tombol huruf "E" dan "R" pada laptop inventaris A-023 tidak berfungsi. Laptop dipinjam untuk keperluan penelitian.',
      status: TicketStatus.inProgress,
      priority: TicketPriority.medium,
      category: 'Hardware',
      createdBy: _user1,
      assignedTo: _helpdesk2,
      createdAt: DateTime(2026, 4, 15, 11, 0),
      updatedAt: DateTime(2026, 4, 16, 14, 0),
      history: [
        TicketHistory(
          id: 12,
          ticketId: 9,
          changedBy: _user1,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 15, 11, 0),
        ),
        TicketHistory(
          id: 13,
          ticketId: 9,
          changedBy: _admin,
          action: 'Tiket di-assign ke Andi Wijaya',
          fromStatus: TicketStatus.open,
          toStatus: TicketStatus.inProgress,
          timestamp: DateTime(2026, 4, 16, 14, 0),
        ),
      ],
    ),

    // ── RESOLVED ─────────────────────────────────────────────────────────────────
    Ticket(
      id: 10,
      title: 'Lupa password login Windows',
      description: 'Tidak bisa login ke Windows karena lupa password. Perlu segera digunakan untuk ujian besok.',
      status: TicketStatus.resolved,
      priority: TicketPriority.critical,
      category: 'Account',
      createdBy: _user3,
      assignedTo: _helpdesk1,
      createdAt: DateTime(2026, 4, 10, 16, 0),
      updatedAt: DateTime(2026, 4, 10, 17, 30),
      comments: [
        Comment(
          id: 5,
          ticketId: 10,
          author: _helpdesk1,
          message: 'Password sudah di-reset. Silakan coba login dengan password sementara: Helpdesk@2026',
          createdAt: DateTime(2026, 4, 10, 17, 30),
        ),
        Comment(
          id: 6,
          ticketId: 10,
          author: _user3,
          message: 'Berhasil masuk, terima kasih!',
          createdAt: DateTime(2026, 4, 10, 17, 45),
        ),
      ],
      history: [
        TicketHistory(
          id: 14,
          ticketId: 10,
          changedBy: _user3,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 10, 16, 0),
        ),
        TicketHistory(
          id: 15,
          ticketId: 10,
          changedBy: _helpdesk1,
          action: 'Masalah selesai ditangani',
          fromStatus: TicketStatus.inProgress,
          toStatus: TicketStatus.resolved,
          timestamp: DateTime(2026, 4, 10, 17, 30),
        ),
      ],
    ),
    Ticket(
      id: 11,
      title: 'Proyektor ruang kelas 301 tidak menyala',
      description: 'Proyektor Epson di ruang 301 tidak bisa dinyalakan. Remote sudah diganti baterai.',
      status: TicketStatus.resolved,
      priority: TicketPriority.high,
      category: 'Hardware',
      createdBy: _user2,
      assignedTo: _helpdesk2,
      createdAt: DateTime(2026, 4, 8, 7, 0),
      updatedAt: DateTime(2026, 4, 8, 11, 0),
      comments: [
        Comment(
          id: 7,
          ticketId: 11,
          author: _helpdesk2,
          message: 'Ditemukan kabel power longgar. Sudah diperbaiki dan proyektor kini berfungsi normal.',
          createdAt: DateTime(2026, 4, 8, 11, 0),
        ),
      ],
      history: [
        TicketHistory(
          id: 16,
          ticketId: 11,
          changedBy: _user2,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 8, 7, 0),
        ),
        TicketHistory(
          id: 17,
          ticketId: 11,
          changedBy: _helpdesk2,
          action: 'Masalah selesai ditangani',
          fromStatus: TicketStatus.inProgress,
          toStatus: TicketStatus.resolved,
          timestamp: DateTime(2026, 4, 8, 11, 0),
        ),
      ],
    ),
    Ticket(
      id: 12,
      title: 'Request instalasi software MATLAB',
      description: 'Mohon diinstalkan MATLAB R2024a di Lab Komputasi lantai 2 untuk kebutuhan mata kuliah Pemodelan.',
      status: TicketStatus.resolved,
      priority: TicketPriority.medium,
      category: 'Software',
      createdBy: _user1,
      assignedTo: _helpdesk1,
      createdAt: DateTime(2026, 4, 5, 9, 0),
      updatedAt: DateTime(2026, 4, 7, 16, 0),
      history: [
        TicketHistory(
          id: 18,
          ticketId: 12,
          changedBy: _user1,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 5, 9, 0),
        ),
        TicketHistory(
          id: 19,
          ticketId: 12,
          changedBy: _helpdesk1,
          action: 'MATLAB berhasil diinstal di semua unit Lab Komputasi',
          fromStatus: TicketStatus.inProgress,
          toStatus: TicketStatus.resolved,
          timestamp: DateTime(2026, 4, 7, 16, 0),
        ),
      ],
    ),
    Ticket(
      id: 13,
      title: 'Scanner dokumen error',
      description: 'Scanner HP ScanJet di ruang TU tidak terdeteksi komputer setelah update Windows.',
      status: TicketStatus.resolved,
      priority: TicketPriority.low,
      category: 'Hardware',
      createdBy: _user3,
      assignedTo: _helpdesk2,
      createdAt: DateTime(2026, 4, 3, 10, 0),
      updatedAt: DateTime(2026, 4, 4, 14, 0),
      history: [
        TicketHistory(
          id: 20,
          ticketId: 13,
          changedBy: _user3,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 4, 3, 10, 0),
        ),
        TicketHistory(
          id: 21,
          ticketId: 13,
          changedBy: _helpdesk2,
          action: 'Driver di-reinstall, scanner terdeteksi kembali',
          fromStatus: TicketStatus.inProgress,
          toStatus: TicketStatus.resolved,
          timestamp: DateTime(2026, 4, 4, 14, 0),
        ),
      ],
    ),

    // ── CLOSED ────────────────────────────────────────────────────────────────────
    Ticket(
      id: 14,
      title: 'Internet di Gedung C lambat',
      description: 'Koneksi internet sangat lambat di seluruh Gedung C sejak 3 minggu lalu.',
      status: TicketStatus.closed,
      priority: TicketPriority.high,
      category: 'Network',
      createdBy: _user2,
      assignedTo: _helpdesk1,
      createdAt: DateTime(2026, 3, 25, 8, 0),
      updatedAt: DateTime(2026, 4, 1, 15, 0),
      comments: [
        Comment(
          id: 8,
          ticketId: 14,
          author: _helpdesk1,
          message: 'Switch core Gedung C sudah diganti. Kecepatan internet kembali normal.',
          createdAt: DateTime(2026, 4, 1, 15, 0),
        ),
      ],
      history: [
        TicketHistory(
          id: 22,
          ticketId: 14,
          changedBy: _user2,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 3, 25, 8, 0),
        ),
        TicketHistory(
          id: 23,
          ticketId: 14,
          changedBy: _helpdesk1,
          action: 'Masalah diselesaikan, tiket ditutup',
          fromStatus: TicketStatus.resolved,
          toStatus: TicketStatus.closed,
          timestamp: DateTime(2026, 4, 1, 15, 0),
        ),
      ],
    ),
    Ticket(
      id: 15,
      title: 'Request penambahan RAM komputer Lab D',
      description: 'Komputer Lab D spesifikasinya sudah sangat tua. Mohon pertimbangan upgrade RAM agar lebih responsif.',
      status: TicketStatus.closed,
      priority: TicketPriority.low,
      category: 'Hardware',
      createdBy: _user1,
      assignedTo: _admin,
      createdAt: DateTime(2026, 3, 15, 10, 0),
      updatedAt: DateTime(2026, 3, 28, 16, 0),
      comments: [
        Comment(
          id: 9,
          ticketId: 15,
          author: _admin,
          message: 'Pengajuan sudah diproses. RAM 8GB telah dipasang di semua unit Lab D.',
          createdAt: DateTime(2026, 3, 28, 16, 0),
        ),
      ],
      history: [
        TicketHistory(
          id: 24,
          ticketId: 15,
          changedBy: _user1,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime(2026, 3, 15, 10, 0),
        ),
        TicketHistory(
          id: 25,
          ticketId: 15,
          changedBy: _admin,
          action: 'Upgrade selesai, tiket ditutup',
          fromStatus: TicketStatus.resolved,
          toStatus: TicketStatus.closed,
          timestamp: DateTime(2026, 3, 28, 16, 0),
        ),
      ],
    ),
  ];

  // ─── Notifications ─────────────────────────────────────────────────────────────

  /// Daftar notifikasi dalam sistem.
  static final List<AppNotification> _notifications = <AppNotification>[
    AppNotification(
      id: _notifIdCounter++,
      userId: _user1.id,
      title: 'Status Tiket Diperbarui',
      message: 'Tiket "Software AutoCAD tidak bisa di-install" telah diubah menjadi In Progress oleh Surya Prakoso.',
      ticketId: 6,
      ticketTitle: 'Software AutoCAD tidak bisa di-install',
      isRead: false,
      createdAt: DateTime(2026, 4, 19, 9, 30),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _user3.id,
      title: 'Status Tiket Diperbarui',
      message: 'Tiket "Monitor bergaris horizontal" telah di-assign ke Andi Wijaya dan status menjadi In Progress.',
      ticketId: 7,
      ticketTitle: 'Monitor bergaris horizontal',
      isRead: false,
      createdAt: DateTime(2026, 4, 18, 10, 0),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _helpdesk1.id,
      title: 'Tiket Baru',
      message: 'Tiket baru "Komputer tidak bisa menyala" dibuat oleh Muhammad Abhista.',
      ticketId: 1,
      ticketTitle: 'Komputer tidak bisa menyala',
      isRead: false,
      createdAt: DateTime(2026, 4, 20, 8, 30),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _helpdesk2.id,
      title: 'Tiket Baru',
      message: 'Tiket baru "Komputer tidak bisa menyala" dibuat oleh Muhammad Abhista.',
      ticketId: 1,
      ticketTitle: 'Komputer tidak bisa menyala',
      isRead: false,
      createdAt: DateTime(2026, 4, 20, 8, 30),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _admin.id,
      title: 'Tiket Baru',
      message: 'Tiket baru "Komputer tidak bisa menyala" dibuat oleh Muhammad Abhista.',
      ticketId: 1,
      ticketTitle: 'Komputer tidak bisa menyala',
      isRead: false,
      createdAt: DateTime(2026, 4, 20, 8, 30),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _user3.id,
      title: 'Status Tiket Diperbarui',
      message: 'Tiket "Lupa password login Windows" telah diubah menjadi Resolved oleh Surya Prakoso.',
      ticketId: 10,
      ticketTitle: 'Lupa password login Windows',
      isRead: true,
      createdAt: DateTime(2026, 4, 10, 17, 30),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _helpdesk1.id,
      title: 'Tiket Baru',
      message: 'Tiket baru "Tidak bisa akses sistem SIAKAD" dibuat oleh Reza Firmansyah.',
      ticketId: 2,
      ticketTitle: 'Tidak bisa akses sistem SIAKAD',
      isRead: false,
      createdAt: DateTime(2026, 4, 21, 9, 0),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _helpdesk2.id,
      title: 'Tiket Baru',
      message: 'Tiket baru "Tidak bisa akses sistem SIAKAD" dibuat oleh Reza Firmansyah.',
      ticketId: 2,
      ticketTitle: 'Tidak bisa akses sistem SIAKAD',
      isRead: false,
      createdAt: DateTime(2026, 4, 21, 9, 0),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _admin.id,
      title: 'Tiket Baru',
      message: 'Tiket baru "Tidak bisa akses sistem SIAKAD" dibuat oleh Reza Firmansyah.',
      ticketId: 2,
      ticketTitle: 'Tidak bisa akses sistem SIAKAD',
      isRead: false,
      createdAt: DateTime(2026, 4, 21, 9, 0),
    ),
    AppNotification(
      id: _notifIdCounter++,
      userId: _user2.id,
      title: 'Status Tiket Diperbarui',
      message: 'Tiket "Internet di Gedung C lambat" telah ditutup oleh Surya Prakoso.',
      ticketId: 14,
      ticketTitle: 'Internet di Gedung C lambat',
      isRead: true,
      createdAt: DateTime(2026, 4, 1, 15, 0),
    ),
  ];

  // ─── Authentication ───────────────────────────────────────────────────────────

  /// Mensimulasikan proses login.
  ///
  /// Melempar [AuthException] jika kredensial salah.
  /// Delay 800ms mensimulasikan network call ke server.
  static Future<User> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _users.where(
      (u) => u.username == username && u.password == password,
    );

    if (user.isEmpty) {
      throw const AuthException('Username atau password salah.');
    }

    currentUser = user.first;
    return currentUser!;
  }

  /// Mensimulasikan proses logout.
  static Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    currentUser = null;
  }

  /// Mensimulasikan proses registrasi user baru.
  ///
  /// Melempar [AuthException] jika username sudah dipakai.
  static Future<User> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final exists = _users.any((u) => u.username == username);
    if (exists) {
      throw const AuthException('Username sudah digunakan. Coba yang lain.');
    }

    final newUser = User(
      id: _users.length + 1,
      username: username,
      password: password,
      fullName: fullName,
      email: email,
      avatarUrl: 'https://i.pravatar.cc/150?img=${_users.length + 20}',
      role: UserRole.user, // Registrasi mandiri hanya untuk role User.
      createdAt: DateTime.now(),
    );

    _users.add(newUser);
    return newUser;
  }

  /// Mensimulasikan reset password.
  ///
  /// Melempar [AuthException] jika email tidak ditemukan.
  static Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final exists = _users.any((u) => u.email == email);
    if (!exists) {
      throw const AuthException('Email tidak terdaftar dalam sistem.');
    }
    // Simulasi: email reset terkirim.
  }

  // ─── Ticket CRUD ─────────────────────────────────────────────────────────────

  /// Menambahkan tiket baru ke daftar.
  ///
  /// Otomatis mengisi [Ticket.createdBy] dari [currentUser].
  /// Delay 600ms mensimulasikan upload data ke server.
  static Future<Ticket> addTicket(Ticket ticket) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final newTicket = ticket.copyWith(
      id: _ticketIdCounter++,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      history: [
        TicketHistory(
          id: _historyIdCounter++,
          ticketId: _ticketIdCounter - 1,
          changedBy: currentUser!,
          action: 'Tiket dibuat',
          toStatus: TicketStatus.open,
          timestamp: DateTime.now(),
        ),
      ],
    );

    _tickets.add(newTicket);

    _notifyStaffNewTicket(newTicket);

    return newTicket;
  }

  /// Memperbarui status sebuah tiket berdasarkan [id].
  ///
  /// Melempar [TicketException] jika tiket tidak ditemukan.
  /// Delay 500ms mensimulasikan request PATCH ke server.
  static Future<Ticket> updateTicketStatus(
      int id, TicketStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _tickets.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw TicketException('Tiket dengan ID $id tidak ditemukan.');
    }

    final oldTicket = _tickets[index];
    final newHistory = TicketHistory(
      id: _historyIdCounter++,
      ticketId: id,
      changedBy: currentUser!,
      action: 'Status diubah menjadi ${newStatus.label}',
      fromStatus: oldTicket.status,
      toStatus: newStatus,
      timestamp: DateTime.now(),
    );

    final updatedTicket = oldTicket.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      history: [...oldTicket.history, newHistory],
    );

    _tickets[index] = updatedTicket;

    _notifyTicketOwner(updatedTicket);

    return updatedTicket;
  }

  /// Meng-assign tiket ke seorang helpdesk/admin.
  ///
  /// Melempar [TicketException] jika tiket atau user tidak ditemukan.
  static Future<Ticket> assignTicket(int ticketId, int assigneeId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) {
      throw TicketException('Tiket dengan ID $ticketId tidak ditemukan.');
    }

    final assignee = _users.firstWhere(
      (u) => u.id == assigneeId,
      orElse: () => throw TicketException('User assignee tidak ditemukan.'),
    );

    final oldTicket = _tickets[ticketIndex];
    final newHistory = TicketHistory(
      id: _historyIdCounter++,
      ticketId: ticketId,
      changedBy: currentUser!,
      action: 'Tiket di-assign ke ${assignee.fullName}',
      fromStatus: oldTicket.status,
      toStatus: TicketStatus.inProgress,
      timestamp: DateTime.now(),
    );

    final updatedTicket = oldTicket.copyWith(
      assignedTo: assignee,
      status: TicketStatus.inProgress,
      updatedAt: DateTime.now(),
      history: [...oldTicket.history, newHistory],
    );

    _tickets[ticketIndex] = updatedTicket;

    _notifyTicketOwner(updatedTicket);

    return updatedTicket;
  }

  /// Menambahkan komentar ke sebuah tiket.
  ///
  /// Melempar [TicketException] jika tiket tidak ditemukan.
  static Future<Comment> addComment(int ticketId, String message) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) {
      throw TicketException('Tiket dengan ID $ticketId tidak ditemukan.');
    }

    final comment = Comment(
      id: _commentIdCounter++,
      ticketId: ticketId,
      author: currentUser!,
      message: message,
      createdAt: DateTime.now(),
    );

    final oldTicket = _tickets[index];
    _tickets[index] = oldTicket.copyWith(
      comments: [...oldTicket.comments, comment],
      updatedAt: DateTime.now(),
    );

    return comment;
  }

  // ─── Ticket Queries ───────────────────────────────────────────────────────────

  /// Mengambil daftar tiket berdasarkan role [currentUser].
  ///
  /// - **Admin & Helpdesk**: melihat semua tiket.
  /// - **User biasa**: hanya tiket yang dia buat sendiri.
  ///
  /// Delay 600ms mensimulasikan fetch data dari server.
  static Future<List<Ticket>> getTicketsByRole() async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (currentUser == null) return [];

    if (currentUser!.role == UserRole.user) {
      return _tickets
          .where((t) => t.createdBy.id == currentUser!.id)
          .toList();
    }

    // Admin & Helpdesk melihat semua tiket.
    return List.unmodifiable(_tickets);
  }

  /// Mengambil detail satu tiket berdasarkan [id].
  ///
  /// Melempar [TicketException] jika tidak ditemukan.
  static Future<Ticket> getTicketById(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final ticket = _tickets.firstWhere(
      (t) => t.id == id,
      orElse: () => throw TicketException('Tiket dengan ID $id tidak ditemukan.'),
    );
    return ticket;
  }

  /// Mengambil tiket yang di-filter berdasarkan [status].
  static Future<List<Ticket>> getTicketsByStatus(TicketStatus status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final all = await getTicketsByRole();
    return all.where((t) => t.status == status).toList();
  }

  // ─── Dashboard Statistics ─────────────────────────────────────────────────────

  /// Mengembalikan map statistik ringkasan tiket untuk tampilan Dashboard.
  ///
  /// Keys: `'total'`, `'open'`, `'inProgress'`, `'resolved'`, `'closed'`.
  static Future<Map<String, int>> getTicketStatistics() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final tickets = await getTicketsByRole();

    return {
      'total': tickets.length,
      'open': tickets.where((t) => t.status == TicketStatus.open).length,
      'inProgress':
          tickets.where((t) => t.status == TicketStatus.inProgress).length,
      'resolved':
          tickets.where((t) => t.status == TicketStatus.resolved).length,
      'closed': tickets.where((t) => t.status == TicketStatus.closed).length,
    };
  }

  // ─── User Queries ─────────────────────────────────────────────────────────────

  /// Mengambil daftar semua helpdesk & admin untuk keperluan assign tiket.
  static Future<List<User>> getHelpdeskUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _users
        .where((u) =>
            u.role == UserRole.helpdesk || u.role == UserRole.admin)
        .toList();
  }

  /// Mengambil seluruh daftar user (hanya Admin yang boleh akses).
  static Future<List<User>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (currentUser?.role != UserRole.admin) {
      throw const AuthException('Akses ditolak. Hanya Admin yang dapat melihat semua user.');
    }

    return List.unmodifiable(_users);
  }

  // ─── Internal Helper: Notifikasi ──────────────────────────────────────────────

  /// Menambahkan notifikasi ke daftar untuk [userId] tertentu.
  static void _addNotification({
    required int userId,
    required String title,
    required String message,
    int? ticketId,
    String? ticketTitle,
  }) {
    _notifications.add(AppNotification(
      id: _notifIdCounter++,
      userId: userId,
      title: title,
      message: message,
      ticketId: ticketId,
      ticketTitle: ticketTitle,
      isRead: false,
      createdAt: DateTime.now(),
    ));
  }

  /// Memberi notifikasi ke semua helpdesk & admin tentang tiket baru.
  static void _notifyStaffNewTicket(Ticket ticket) {
    final staff = _users.where(
      (u) => u.role == UserRole.helpdesk || u.role == UserRole.admin,
    );
    for (final user in staff) {
      _addNotification(
        userId: user.id,
        title: 'Tiket Baru',
        message:
            'Tiket baru "${ticket.title}" dibuat oleh ${ticket.createdBy.fullName}.',
        ticketId: ticket.id,
        ticketTitle: ticket.title,
      );
    }
  }

  /// Memberi notifikasi ke pembuat tiket bahwa statusnya berubah.
  static void _notifyTicketOwner(Ticket ticket) {
    if (currentUser?.id == ticket.createdBy.id) return;
    _addNotification(
      userId: ticket.createdBy.id,
      title: 'Status Tiket Diperbarui',
      message:
          'Tiket "${ticket.title}" telah diubah menjadi ${ticket.status.label} oleh ${currentUser?.fullName ?? "Sistem"}.',
      ticketId: ticket.id,
      ticketTitle: ticket.title,
    );
  }

  // ─── Notification Queries ─────────────────────────────────────────────────────

  /// Mengambil daftar notifikasi untuk user yang sedang login.
  static Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (currentUser == null) return [];
    return _notifications
        .where((n) => n.userId == currentUser!.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Mengambil jumlah notifikasi yang belum dibaca.
  static Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (currentUser == null) return 0;
    return _notifications
        .where((n) => n.userId == currentUser!.id && !n.isRead)
        .length;
  }

  /// Menandai satu notifikasi sebagai sudah dibaca.
  static Future<void> markNotificationAsRead(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  /// Menandai semua notifikasi user saat ini sebagai sudah dibaca.
  static Future<void> markAllNotificationsAsRead() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (currentUser == null) return;
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == currentUser!.id && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }
}