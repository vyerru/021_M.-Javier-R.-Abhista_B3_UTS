# E-Ticketing Helpdesk — Application Flow

**Versi**: 1.0.0  
**Terakhir Diperbarui**: Juli 2026  
**Tech Stack**: Flutter 3.x · Supabase (Postgres, Auth, REST API, Storage)

---

## Daftar Isi

1. [Arsitektur Aplikasi](#1-arsitektur-aplikasi)
2. [Role-Based Access Control (RBAC)](#2-role-based-access-control-rbac)
3. [Authentication Flow](#3-authentication-flow)
4. [Navigation & Routing](#4-navigation--routing)
5. [Ticket Lifecycle](#5-ticket-lifecycle)
6. [Screen Flows](#6-screen-flows)
7. [Database Operations Index](#7-database-operations-index)
8. [Notification Flow](#8-notification-flow)
9. [Error & Edge Cases](#9-error--edge-cases)
10. [Data Flow Diagram](#10-data-flow-diagram)

---

## 1. Arsitektur Aplikasi

```
┌──────────────────────────────────────────────────────┐
│                    Presentation                        │
│  Screens (Widget) → Provider (ChangeNotifier)         │
│  ┌─────────────────────────────────────────────────┐  │
│  │  AuthProvider      TicketProvider                │  │
│  │  NotificationProvider                             │  │
│  └─────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│                      Domain                            │
│  Entities → Use Cases → Repository Interfaces         │
│  ┌─────────────────────────────────────────────────┐  │
│  │  User, Ticket, Comment, TicketHistory,            │  │
│  │  AppNotification, Enums, TicketPermission         │  │
│  └─────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│                       Data                             │
│  DTOs → Repository Impl → Data Sources (Supabase)     │
│  ┌─────────────────────────────────────────────────┐  │
│  │  AuthDataSource    TicketDataSource               │  │
│  │  CommentDataSource  NotificationDataSource         │  │
│  │  StorageDataSource                                 │  │
│  └─────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│                       Core                             │
│  SupabaseConfig (dotenv) → Theme → Network            │
└──────────────────────────────────────────────────────┘
```

### Dependency Injection

Semua dependency diikat secara manual di `main.dart` tanpa framework DI:

```
SupabaseClient
  ├── SupabaseAuthDataSource → AuthRepositoryImpl → LoginUseCase, RegisterUseCase, etc.
  ├── SupabaseTicketDataSource ─┐
  ├── SupabaseCommentDataSource ─┤→ TicketRepositoryImpl → Ticket use cases
  ├── SupabaseNotificationDataSource → NotificationRepositoryImpl → Notification use cases
  └── SupabaseStorageDataSource → (disediakan langsung ke CreateTicketScreen)
```

### Catatan Penting

**Semua otorisasi bersifat client-side.** Logika siapa yang boleh mengubah status, mengassign, atau membuat tiket diimplementasikan di `ticket_permission.dart` — bukan via Row-Level Security di database. RLS hanya memfilter baris yang bisa diakses, bukan tindakan apa yang boleh dilakukan.

---

## 2. Role-Based Access Control (RBAC)

### Definisi Role

| Role | Label | Kode |
|------|-------|------|
| `user` | User | `UserRole.user` |
| `helpdesk` | Helpdesk | `UserRole.helpdesk` |
| `admin` | Admin | `UserRole.admin` |

### Permission Matrix

| Aksi | User | Helpdesk | Admin |
|------|------|----------|-------|
| Membuat tiket | ✅ | ✅ | ✅ |
| Melihat tiket sendiri | ✅ | ✅ | ✅ |
| Melihat semua tiket | ❌ | ✅ | ✅ |
| Ubah status `open → assign` | ❌ | ❌ | ✅ |
| Assign tiket + set `inprogress` | ❌ | ❌ | ✅ |
| Ubah status `inprogress → closed` | ❌ | ✅ | ❌ |
| Tambah komentar | ✅ | ✅ | ✅ |
| Upload lampiran | ✅ | ✅ | ✅ |
| Lihat notifikasi sendiri | ✅ | ✅ | ✅ |

### Implementasi (ticket_permission.dart)

```dart
canChangeStatusBy(UserRole role):
  admin + status == open  → true  (open → assign)
  helpdesk + status == inprogress → true (inprogress → closed)
  lainnya → false

canBeAssignedBy(UserRole role):
  admin + status == assign → true
  lainnya → false

availableStatusesFor(UserRole role):
  admin + status == open → [assign]
  helpdesk + status == inprogress → [closed]
  lainnya → []
```

---

## 3. Authentication Flow

### Diagram Alur

```
SplashScreen
    │
    ├── checkSession()
    │     ├── Ada session → fetch profile dari users table
    │     │     └── Berhasil → DashboardScreen (pushReplacement)
    │     │     └── Gagal → LoginScreen (pushReplacement)
    │     └── Tidak ada session → LoginScreen (pushReplacement)
    │
    └── (setelah 2.8 detik animasi)
```

### 3.1 Login

```
LoginScreen
    │
    ├── User input email + password
    ├── Tap "Masuk"
    │     ├── Validasi: email tidak kosong, valid format, password ≥ 6 karakter
    │     ├── authProvider.login(email, password)
    │     │     ├── supabase.auth.signInWithPassword(email, password)
    │     │     ├── SELECT * FROM users WHERE id = result.user.id
    │     │     ├── Simpan sebagai currentUser
    │     │     └── Return true
    │     └── Berhasil → DashboardScreen (pushReplacement)
    │     └── Gagal → Tampilkan snackbar merah dengan error (Indonesia)
    │
    ├── Tap "Lupa Password?" → ForgotPasswordScreen (pushReplacement)
    └── Tap "Daftar" → RegisterScreen (pushReplacement)
```

**Pemetaan Error (Indonesia):**

| Error Asli | Pesan Tampilan |
|------------|----------------|
| "Invalid login credentials" | "Email atau password salah" |
| "Email not confirmed" | "Email belum dikonfirmasi" |
| SocketException / HandshakeException | "Tidak dapat terhubung ke server" |

### 3.2 Register

```
RegisterScreen
    │
    ├── User input email, username, fullName, password, confirmPassword
    ├── Tap "Daftar"
    │     ├── Validasi: semua field required, password ≥ 6, confirm == password
    │     ├── authProvider.register(email, username, fullName, password)
    │     │     ├── supabase.auth.signUp(email, password)
    │     │     ├── INSERT INTO users (id, username, full_name, email, avatar_url, role='user')
    │     │     ├── SELECT * FROM users WHERE id = user.id
    │     │     └── Simpan sebagai currentUser
    │     ├── authProvider.logout()  ← auto logout setelah register
    │     └── Berhasil → LoginScreen (pushReplacement)
    │
    └── Tap "Masuk" → LoginScreen (pushReplacement)
```

**Pemetaan Error Register:**

| Error Asli | Pesan Tampilan |
|------------|----------------|
| "User already registered" | "Email sudah terdaftar" |
| Unique constraint (username) | "Username/email sudah digunakan/terdaftar" |

### 3.3 Logout

```
[Any screen] → Logout button
    │
    ├── Konfirmasi dialog
    ├── authProvider.logout()
    │     └── supabase.auth.signOut()
    └── LoginScreen (pushAndRemoveUntil — hapus semua stack)
```

### 3.4 Forgot & Reset Password

```
ForgotPasswordScreen
    │
    ├── Input email
    ├── Tap "Kirim Link Reset"
    │     └── auth.resetPassword(email) → supabase.auth.resetPasswordForEmail(email)
    └── Berhasil → NewPasswordScreen (pushReplacement)

NewPasswordScreen
    │
    ├── [DEMO MODE] Coba login dengan 3 password demo:
    │     ├── admin123 → jika berhasil, update password via updateUser()
    │     ├── helpdesk123 → jika berhasil, update password
    │     └── user123456 → jika berhasil, update password
    ├── Update password: supabase.auth.updateUser(AdminUserAttributes(password: newPass))
    ├── logout: supabase.auth.signOut()
    └── Berhasil → LoginScreen (pushAndRemoveUntil)
```

---

## 4. Navigation & Routing

### Diagram Navigasi Lengkap

```
SplashScreen (/)
  │
  ├── (logged in) ──pushReplacement──→ DashboardScreen
  │                                        │
  │                                        ├── Tab 0: Dashboard (built-in)
  │                                        │     ├── Tap "Lihat Semua" → switch ke Tab 2
  │                                        │     └── Tap kartu tiket → push TicketDetailScreen
  │                                        │
  │                                        ├── Tab 1: RiwayatScreen
  │                                        │     └── Tap kartu → push TicketHistoryScreen
  │                                        │
  │                                        ├── Tab 2: TicketListScreen
  │                                        │     ├── Tap kartu → push TicketDetailScreen
  │                                        │     └── FAB → push CreateTicketScreen
  │                                        │
  │                                        ├── Tab 3: NotificationScreen
  │                                        │     └── Tap notifikasi → push TicketDetailScreen
  │                                        │
  │                                        └── Tab 4: ProfileScreen
  │                                              └── Logout → pushAndRemoveUntil LoginScreen
  │
  └── (not logged in) ──pushReplacement──→ LoginScreen
                                              │
                                              ├── Berhasil login → pushReplacement DashboardScreen
                                              ├── Tap "Daftar" → pushReplacement RegisterScreen
                                              │     └── Berhasil → pushReplacement LoginScreen
                                              └── Tap "Lupa Password?" → pushReplacement ForgotPasswordScreen
                                                    └── Berhasil → pushReplacement NewPasswordScreen
                                                          └── Berhasil → pushAndRemoveUntil LoginScreen
```

### Stack Navigation

| Metode | Penggunaan |
|--------|------------|
| `pushReplacement` | Transisi antar screen auth (Login ↔ Register ↔ ForgotPassword) |
| `pushAndRemoveUntil` | Logout atau reset password — membersihkan seluruh stack navigasi |
| `push` + `pop` | Dari screen dalam ke detail screen (TicketDetail, CreateTicket, TicketHistory) |
| `IndexedStack` | 5 tab di DashboardScreen — menjaga state tiap tab tetap hidup |

---

## 5. Ticket Lifecycle

### Diagram Status

```
open ──→ assign ──→ inprogress ──→ closed
  ↑          │
  │          ▼
  │    (assign + set inprogress)
  └──────── Admin ──────────┘
```

| Step | Performer | Aksi | Metode | Database Write |
|------|-----------|------|--------|----------------|
| 1 | User / Admin / Helpdesk | Buat tiket | `createTicket()` | `tickets.insert({status:'open', ...})` |
| 2 | Admin | Ubah status → assign | `updateStatus()` | `tickets.update({status:'assign'})` |
| 3 | Admin | Assign ke helpdesk | `assignTicket()` | `tickets.update({assigned_to, status:'inprogress'})` + `ticket_history.insert()` |
| 4 | Helpdesk | Selesaikan → closed | `updateStatus()` | `tickets.update({status:'closed'})` |

### Detail Setiap Aksi

**Membuat Tiket:**
1. User (role apa pun) mengisi form: title, description, category, priority
2. Opsional: upload file via `SupabaseStorageDataSource`
3. INSERT ke `tickets` dengan `status='open'`, `assigned_to=null`
4. Jika ada file: upload ke Storage bucket `ticket_attachments`, lalu UPDATE `tickets.attachment_urls`
5. Database trigger `on_ticket_insert` → `notify_ticket_change()` membuat notifikasi "Tiket Baru" ke semua admin

**Ubah Status ke Assign (Admin only):**
1. Admin melihat tiket dengan status `open`
2. Tap "Ubah Status" → konfirmasi → `updateStatus(ticketId, 'assign')`
3. Database trigger `on_ticket_update` → `notify_ticket_change()` membuat notifikasi ke pembuat tiket

**Assign Tiket (Admin only):**
1. Admin melihat tiket dengan status `assign`
2. Tap "Assign Tiket" → pilih helpdesk → `assignTicket(ticketId, helpdeskId)`
3. **Satu query**: `tickets.update({assigned_to: helpdeskId, status: 'inprogress'})`
4. Repository menulis ke `ticket_history`: `action = 'Ditugaskan ke {nama}'`
5. Database trigger membuat notifikasi "Tiket Diassign" ke helpdesk + "Status Tiket Diubah" ke pembuat

**Selesaikan Tiket (Helpdesk only):**
1. Helpdesk melihat tiket dengan status `inprogress`
2. Tap "Ubah Status" → konfirmasi → `updateStatus(ticketId, 'closed')`
3. Database trigger membuat notifikasi "Status Tiket Diubah" ke pembuat + "Tiket Selesai" ke semua admin

### Validasi Client-Side

```
┌──────────────────────────────────────────────┐
│              ticket_permission.dart            │
│                                                │
│  Admin + open     → [assign]                   │
│  Helpdesk + inprogress → [closed]              │
│  Lainnya          → [] (tidak ada aksi)        │
│                                                │
│  Admin + assign   → canBeAssignedBy = true     │
│  Lainnya          → false                      │
└──────────────────────────────────────────────┘
```

---

## 6. Screen Flows

### 6.1 SplashScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Aplikasi dibuka (initial route `/`) |
| **Animasi** | Fade-in + slide-up selama 1.2s, delay 2.8s total |
| **Data Read** | `auth.checkSession()` → `supabase.auth.currentSession` → SELECT `users` |
| **Decision** | `session != null` → DashboardScreen; `null` → LoginScreen |
| **Error Handle** | Silent catch — jika gagal fetch profile, dianggap tidak login |

### 6.2 LoginScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tidak ada session (dari SplashScreen) |
| **State** | `_emailController`, `_passwordController`, `_isLoading`, `_obscurePassword` |
| **Data Write** | `supabase.auth.signInWithPassword()` → SELECT `users` → simpan di AuthProvider |
| **Navigasi** | Berhasil → DashboardScreen; Tap "Daftar" → RegisterScreen; "Lupa Password?" → ForgotPasswordScreen |
| **Error** | Snackbar merah dengan pesan bahasa Indonesia |

### 6.3 RegisterScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tap "Daftar" dari LoginScreen |
| **State** | 5 TextEditingController: email, username, fullName, password, confirmPassword |
| **Data Write** | `supabase.auth.signUp()` → INSERT `users` (role='user') → auto logout |
| **Navigasi** | Berhasil → LoginScreen (pushReplacement setelah auto logout) |
| **Validasi** | Email: format valid; Username: ≥ 3 chars; FullName: ≥ 3 chars; Password: ≥ 6 chars; Confirm: == Password |
| **Error** | Snackbar merah dengan pesan bahasa Indonesia |

### 6.4 ForgotPasswordScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tap "Lupa Password?" dari LoginScreen |
| **Data Write** | `supabase.auth.resetPasswordForEmail(email)` |
| **Navigasi** | Berhasil → NewPasswordScreen; Tap link → LoginScreen |
| **Catatan** | Di production, email reset akan dikirim. Di demo, langsung ke NewPasswordScreen. |

### 6.5 NewPasswordScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Dari ForgotPasswordScreen |
| **Data Write** | Mencoba login dengan 3 password demo, lalu `supabase.auth.updateUser()` |
| **Navigasi** | Berhasil → LoginScreen (pushAndRemoveUntil) |
| **Catatan** | **Hanya untuk demo** — bypass alur reset password normal |

### 6.6 DashboardScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Setelah login berhasil |
| **On Load** | `loadTickets()`, `loadStatistics()`, `loadNotifications(currentUser.id)` |
| **State** | `_selectedNavIndex` (0-4) untuk tab navigation |
| **Data Read** | `ticketProvider.tickets` (5 terbaru), `ticketProvider.statistics` (total, open, assign, inprogress, closed), `notifProvider.unreadCount` |
| **Tab Content** | |
| Tab 0 | Greeting + Statistics Grid + 5 Tiket Terbaru |
| Tab 1 | RiwayatScreen (filter: semua/aktif/selesai) |
| Tab 2 | TicketListScreen (filter status + FAB) |
| Tab 3 | NotificationScreen (daftar + mark read) |
| Tab 4 | ProfileScreen (edit profil + theme + logout) |
| **AppBar** | Title "HelpDesk", theme toggle, logout button |
| **Pull-to-refresh** | Reload tickets, stats, dan notifications |

### 6.7 TicketListScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tab 2 di DashboardScreen |
| **State** | `_selectedStatus` (null = Semua), `_scrollController` untuk infinite scroll |
| **Data Read** | `ticketProvider.loadTickets(statusFilter)` — query dengan join `created_by` dan `assigned_to` |
| **Filter** | Semua, Open, Assign, In Progress, Closed |
| **Pagination** | 20 item per halaman, infinite scroll (loadMore saat 200px dari bottom) |
| **Aksi User** | |
| Filter chip | Reload dengan filter status |
| Tap kartu | Push TicketDetailScreen — refresh on return |
| Scroll ke bawah | Load halaman berikutnya |
| Pull-to-refresh | Reload halaman pertama |
| FAB "Buat Tiket" | Push CreateTicketScreen — refresh on return |
| **Error** | Banner merah di atas list + tombol "Coba Lagi" |
| **Empty State** | Icon + "Belum ada tiket" + "Buat tiket baru untuk memulai" |

### 6.8 RiwayatScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tab 1 di DashboardScreen |
| **Filter** | "Semua" (all → `loadTickets()`), "Aktif" (active → status != closed), "Selesai" (closed → filter) |
| **Visual Card** | Progress stepper 4 titik (Open→Assign→InProgress→Closed), title, status badge, assigned person, timestamp |
| **Aksi User** | Tap card → TicketHistoryScreen |
| **Refresh** | Pull-to-refresh + AppBar refresh button |

### 6.9 TicketDetailScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tap kartu tiket dari TicketListScreen, RiwayatScreen, DashboardScreen, atau NotificationScreen |
| **On Load** | `loadTicketDetail(ticketId)` + `loadHelpdeskUsers()` |
| **Data Read** | `selectedTicket` (dengan joins: created_by, assigned_to, comments, history) |

**Layout:**

```
┌─ AppBar: "Detail Tiket" ──────── PopupMenu ─┐
│                                              │
│  TicketHeaderCard                            │
│  ├─ Status badge (warna: open=merah,        │
│  │   assign=ungu, inprogress=kuning,         │
│  │   closed=abu)                             │
│  ├─ Priority badge                           │
│  ├─ Ticket ID                                │
│  ├─ Title                                    │
│  └─ Description                              │
│                                              │
│  TicketInfoCard                              │
│  ├─ Kategori                                 │
│  ├─ Dibuat oleh                              │
│  ├─ Di-assign ke                             │
│  ├─ Dibuat                                   │
│  └─ Diperbarui                               │
│                                              │
│  TicketAttachments (jika ada)                │
│  └─ Thumbnail grid → tap = full-screen       │
│                                              │
│  StaffActionsCard (hanya staff)              │
│  ├─ Tombol "Ubah Status"                     │
│  └─ Tombol "Assign Tiket"                    │
│                                              │
│  TicketTimeline                              │
│  ├─ Riwayat aktivitas (history entries)      │
│  └─ "Lihat Semua" → TicketHistoryScreen      │
│                                              │
│  CommentsSection                             │
│  └─ Daftar komentar (author avatar,          │
│      message, timestamp)                     │
│                                              │
├──────────────────────────────────────────────┤
│  Bottom: CommentInput (hidden jika closed)   │
└──────────────────────────────────────────────┘
```

**Aksi Staff (PopupMenu):**

| Menu Item | Kondisi | Aksi |
|-----------|---------|------|
| "Ubah Status" | `canChangeStatusBy(role)` == true | Bottom sheet konfirmasi → `updateStatus()` |
| "Assign Tiket" | `canBeAssignedBy(role)` == true | Bottom sheet pilih helpdesk → `assignTicket()` |

**Aksi Semua User:**

| Aksi | Data Write |
|------|-----------|
| Kirim komentar | `comments.insert({ticket_id, author_id, message, attachment_urls})` |
| | Lalu reload `loadTicketDetail()` untuk refresh comments |

### 6.10 CreateTicketScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | FAB dari TicketListScreen |
| **State** | `_titleController`, `_descController`, `_selectedCategory` (default: Hardware), `_selectedPriority` (default: medium), `_selectedFiles` |

**Alur Create:**

```
1. Form: Title*, Description*, Category, Priority, Attachments
2. Tap "Buat Tiket"
   │
   ├── Validasi: title & description tidak kosong
   │
   ├── ticketProvider.createTicket(ticket)
   │     └── tickets.insert({
   │           title, description, status:'open',
   │           priority, category, created_by: userId,
   │           assigned_to: null, attachment_urls: []
   │         }).select(*, created_by, assigned_to)
   │
   ├── Jika ada file:
   │     ├── storage.uploadFiles(files, ticketId: created.id)
   │     │     └── Storage bucket 'ticket_attachments':
   │     │         uploadBinary('{ticketId}/{timestamp}.{ext}', bytes)
   │     │         getPublicUrl(path) → URL list
   │     └── ticketProvider.updateAttachmentUrls(created.id, urls)
   │           └── tickets.update({attachment_urls: urls}).eq('id', created.id)
   │
   └── Navigator.pop(context, true) → TicketListScreen refresh
```

**File Upload Options:**

| Sumber | Library | Multiple? |
|--------|---------|-----------|
| Kamera | `ImagePicker` | Tidak |
| Galeri | `ImagePicker` | Ya (multi-image) |
| File Manager | `FilePicker` | Tidak (satu per session) |

**Allowed File Types:** jpg, jpeg, png, gif, webp, pdf, doc, docx

### 6.11 TicketHistoryScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tap card di RiwayatScreen atau "Lihat Semua" di TicketDetailScreen |
| **On Load** | `loadTicketDetail(ticketId)` |
| **Layout** | |
| | 1. AppBar dengan title tiket |
| | 2. Progress stepper 4 langkah (lingkaran terisi/kosong) |
| | 3. Header: status saat ini, title, assigned to, created by |
| | 4. Timeline aktivitas (garis vertikal + titik) |
| **Data Read** | `selectedTicket.history` — daftar `TicketHistory` dengan join `changed_by:users` |

### 6.12 NotificationScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tab 3 di DashboardScreen |
| **On Load** | `notifProvider.loadNotifications(userId)` |
| **Data Read** | `notifications` table — SELECT by user_id, ORDER created_at DESC |
| **Aksi User** | |
| Tap notifikasi | `markAsRead(id)` → jika `ticketId != null` → push TicketDetailScreen |
| "Tandai Semua Dibaca" | `markAllAsRead(userId)` — UPDATE `notifications SET is_read=true` |
| Pull-to-refresh | Reload notifications |
| **Empty State** | Icon bell-off + "Tidak ada notifikasi" |
| **Visual Card** | Icon (varies by type), title, message, relative timestamp, unread dot, ticket title |

### 6.13 ProfileScreen

| Aspek | Detail |
|-------|--------|
| **Trigger** | Tab 4 di DashboardScreen |
| **State** | `_isEditing`, `_isSaving`, form controllers |
| **Data Read** | `auth.currentUser`, `ticketProvider.statistics` |

**Sections:**

```
┌─ Profile Header ───────────────────────────┐
│  Avatar (initials atau network image)       │
│  Nama Lengkap                               │
│  @username                                  │
│  Role badge (User / Helpdesk / Admin)       │
├─────────────────────────────────────────────┤
│  Info (view mode) / Edit Form (edit mode)   │
│  ├─ Nama Lengkap                            │
│  ├─ Username                                │
│  ├─ Email (read-only)                       │
│  └─ Bergabung (join date)                   │
├─────────────────────────────────────────────┤
│  Statistik Akun                             │
│  ├─ Total Tiket                             │
│  ├─ Open                                    │
│  ├─ In Progress                             │
│  └─ Assign                                  │
├─────────────────────────────────────────────┤
│  Pengaturan                                 │
│  ├─ Dark Mode toggle                        │
│  └─ Logout button                           │
└─────────────────────────────────────────────┘
```

**Aksi:**

| Aksi | Data Write |
|------|-----------|
| Edit → Simpan | `users.update({full_name, username}).eq('id', userId)` |
| Dark Mode | `onThemeToggle()` — state lokal, tidak persist |
| Logout | `supabase.auth.signOut()` → LoginScreen (pushAndRemoveUntil) |

---

## 7. Database Operations Index

### 7.1 SupabaseAuthDataSource

| Operasi | Query | Keterangan |
|---------|-------|------------|
| Login | `auth.signInWithPassword(email, password)` | Auth |
| | `users.select().eq('id', $userId).single()` | Ambil profil |
| Register | `auth.signUp(email, password)` | Buat auth user |
| | `users.insert({id, username, full_name, email, avatar_url, role:'user'})` | Buat profil |
| | `users.select().eq('id', $userId).single()` | Ambil kembali |
| Logout | `auth.signOut()` | Hapus session |
| Get Current User | `auth.currentSession` | Cek session |
| | `users.select().eq('id', $userId).single()` | Ambil profil |
| Update Profile | `users.update({full_name, username, avatar_url}).eq('id', $id)` | Update profil |
| | `users.select().eq('id', $id).single()` | Ambil kembali |
| Reset Password | `auth.resetPasswordForEmail(email)` | Kirim email reset |

### 7.2 SupabaseTicketDataSource

| Operasi | Query | Keterangan |
|---------|-------|------------|
| Get Tickets | `tickets.select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)').order('created_at', ascending: false).range(from, to)` | Paginated 20 item |
| Get Ticket By ID | `tickets.select(*, created_by, assigned_to).eq('id', $id).single()` | Single ticket |
| Create Ticket | `tickets.insert({...}).select(*, created_by, assigned_to).single()` | Return created |
| Update Status | `tickets.update({status}).eq('id', $id).select(...).single()` | |
| Assign + In Progress | `tickets.update({assigned_to, status:'inprogress'}).eq('id', $id).select(...).single()` | 1 query atomik |
| Update Attachment URLs | `tickets.update({attachment_urls}).eq('id', $id)` | No select |
| Get Statistics | `rpc('get_statistics', params: {user_id})` | Return: {total, open, assign, inprogress, closed} |
| Get Helpdesk Users | `users.select().eq('role', 'helpdesk').order('full_name')` | |
| Get History | `ticket_history.select('*, changed_by:users!changed_by(*)').eq('ticket_id', $id).order('timestamp')` | |
| Add History | `ticket_history.insert({ticket_id, changed_by, action, to_status})` | Setelah assign |

### 7.3 SupabaseCommentDataSource

| Operasi | Query | Keterangan |
|---------|-------|------------|
| Get Comments | `comments.select('*, author:users(*)').eq('ticket_id', $id).order('created_at')` | Join author |
| Add Comment | `comments.insert({...}).select('*, author:users(*)').single()` | Return created |

### 7.4 SupabaseNotificationDataSource

| Operasi | Query | Keterangan |
|---------|-------|------------|
| Get Notifications | `notifications.select().eq('user_id', $id).order('created_at', descending)` | |
| Get Unread Count | `notifications.select('id').eq('user_id', $id).eq('is_read', false)` | count = length |
| Mark As Read | `notifications.update({is_read: true}).eq('id', $notifId)` | Single |
| Mark All As Read | `notifications.update({is_read: true}).eq('user_id', $id).eq('is_read', false)` | Bulk |

### 7.5 SupabaseStorageDataSource

| Operasi | Bucket | Metode | Keterangan |
|---------|--------|--------|------------|
| Upload Files | `ticket_attachments` | `uploadBinary('{ticketId}/{timestamp}.{ext}', bytes)` | Per file |
| | | `getPublicUrl(path)` | Dapatkan URL publik |
| Delete File | `ticket_attachments` | `remove([objectPath])` | Parse URL ke path |

### 7.6 Database Triggers (Server-Side)

| Trigger | Event | Fungsi | Efek |
|---------|-------|--------|------|
| `on_ticket_update` | AFTER UPDATE on `tickets` | `notify_ticket_change()` | Notifikasi perubahan status |
| `trg_ticket_insert_notification` | AFTER INSERT on `tickets` | `notify_ticket_change()` | Notifikasi tiket baru ke admin |
| `on_comment_insert` | AFTER INSERT on `comments` | `notify_new_comment()` | Notifikasi komentar baru ke owner |
| `set_updated_at` | BEFORE UPDATE on `tickets` | `handle_updated_at()` | Auto-update `updated_at` |
| `trg_check_assign_permission` | BEFORE UPDATE on `tickets` | `check_assign_permission()` | Cegah helpdesk assign |

---

## 8. Notification Flow

### Diagram

```
┌──────────────────────────────────────────────────┐
│                    EVENT                          │
│                                                   │
│  Tiket Baru (INSERT tickets)                      │
│  Status Diubah (UPDATE tickets.status)            │
│  Tiket Diassign (UPDATE tickets.assigned_to)      │
│  Tiket Selesai (UPDATE tickets.status=closed)     │
│  Komentar Baru (INSERT comments)                  │
│                                                   │
└──────────────────────┬───────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│           DATABASE TRIGGER                        │
│                                                   │
│  notify_ticket_change()                           │
│    ├── INSERT → admin                             │
│    ├── UPDATE.status → ticket creator             │
│    ├── UPDATE.assigned_to → helpdesk yg diassign  │
│    └── UPDATE.status=closed → semua admin         │
│                                                   │
│  notify_new_comment()                             │
│    └── INSERT → ticket owner (jika bukan diri)    │
│                                                   │
└──────────────────────┬───────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│            notifications TABLE                    │
│                                                   │
│  INSERT INTO notifications                        │
│  (user_id, title, message, ticket_id,             │
│   ticket_title, is_read=false, created_at)        │
│                                                   │
└──────────────────────┬───────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│              FLUTTER APP                           │
│                                                   │
│  NotificationScreen:                               │
│  SELECT * FROM notifications WHERE user_id=$id     │
│  ORDER BY created_at DESC                          │
│                                                   │
│  Tap → markAsRead() → TicketDetailScreen          │
└──────────────────────────────────────────────────┘
```

### Jenis Notifikasi

| Event | Title | Recipient | Contoh Pesan |
|-------|-------|-----------|--------------|
| Tiket Baru | `Tiket Baru` | Admin | `Tiket "Laptop Rusak" telah dibuat oleh User Demo.` |
| Status Diubah | `Status Tiket Diubah` | Pembuat tiket | `Status tiket "Laptop Rusak" berubah menjadi inprogress - Ditugaskan ke Helpdesk Demo` |
| Tiket Diassign | `Tiket Diassign` | Helpdesk yg ditunjuk | `Tiket "Laptop Rusak" telah diassign kepada Anda untuk dikerjakan` |
| Tiket Selesai | `Tiket Selesai` | Semua admin | `Tiket "Laptop Rusak" telah selesai dikerjakan oleh Helpdesk Demo` |
| Komentar Baru | `Komentar Baru` | Pemilik tiket (jika bukan pengomentar) | `Tiket "Laptop Rusak" mendapat komentar baru` |

### Alur di Flutter

```
User membuka NotificationScreen (Tab 3)
    │
    ├── notifProvider.loadNotifications(userId)
    │     └── notifications.select().eq('user_id', userId).order('created_at', descending)
    │
    ├── Tampilkan daftar notifikasi
    │     ├── Unread: dot biru
    │     └── Read: tanpa dot
    │
    ├── Tap notifikasi
    │     ├── notifProvider.markAsRead(notifId)
    │     │     └── notifications.update({is_read: true}).eq('id', notifId)
    │     │         + update lokal (copyWith) + decrement unreadCount
    │     └── Jika ticketId != null → push TicketDetailScreen(ticketId)
    │
    └── Tap "Tandai Semua Dibaca"
          └── notifProvider.markAllAsRead(userId)
                └── notifications.update({is_read: true})
                      .eq('user_id', userId).eq('is_read', false)
                    + semua item lokal di-set read + unreadCount = 0
```

---

## 9. Error & Edge Cases

### 9.1 Error Handling per Layer

| Layer | Strategi |
|-------|----------|
| **DataSource** | Catch `AuthException`, `PostgrestException`, `SocketException`, generic → `throw Exception(pesan Indonesia)` |
| **Repository** | Propagate exception ke atas; `_fetchComments` dan `_fetchHistory` catch & return `[]` (silent) |
| **UseCase** | Pure pass-through, tanpa error handling |
| **Provider** | Catch semua exception → simpan di `_error` (string), `notifyListeners()`. Method write return `bool` |
| **Screen** | Gagal write → SnackBar merah; Gagal load → inline error + retry button |

### 9.2 Skeleton Loading

| Screen | Loading State |
|--------|---------------|
| DashboardScreen | Skeleton cards (abu-abu animate) untuk statistik grid + recent tickets |
| TicketListScreen | CircularProgressIndicator sentral |
| TicketDetailScreen | CircularProgressIndicator sentral |
| NotificationScreen | CircularProgressIndicator sentral |

### 9.3 Error States

| Screen | Error Handling |
|--------|---------------|
| TicketListScreen | Banner merah di atas list + tombol "Coba Lagi" |
| NotificationScreen | Pesan error + tombol "Coba Lagi" |
| TicketDetailScreen | Pesan error + tombol "Coba Lagi" |
| LoginScreen | SnackBar merah (otomatis hilang) |
| CreateTicketScreen | SnackBar merah (otomatis hilang) |

### 9.4 Pagination

```
loadTickets(statusFilter?) → page 0, 20 items
  Jika result.length == 20 → hasMore = true
  Jika result.length < 20 → hasMore = false

loadMore()
  page++ → append ke _tickets list
  Guard: isLoadingMore → cegah double fetch

Scroll: listener di _scrollController
  Jika posisi <= 200px dari maxScrollExtent → panggil loadMore()
```

### 9.5 Empty States

| Screen | Empty State Message |
|--------|---------------------|
| TicketListScreen | Icon + "Belum ada tiket" + "Buat tiket baru untuk memulai" |
| NotificationScreen | "Tidak ada notifikasi" dengan bell-off icon |
| RiwayatScreen | (Tergantung filter: "Tidak ada tiket" / "Tidak ada tiket aktif" / "Tidak ada tiket selesai") |

### 9.6 Edge Cases

| Skenario | Perilaku |
|----------|----------|
| Register lalu langsung login | Auto logout setelah register → user harus login manual |
| Tiket dengan status `closed` | Comment input disembunyikan |
| Helpdesk mencoba assign | Dicegah oleh `check_assign_permission` trigger → exception |
| Network timeout | `SocketException` → "Tidak dapat terhubung ke server" |
| Duplicate username | `PostgrestException` code 23505 → "Username sudah digunakan" |
| File upload gagal | Tiket tetap terbuat tanpa lampiran (error dicatch silent) |
| Dark mode toggle | State lokal, tidak persist (reset saat app restart) |

---

## 10. Data Flow Diagram

### Flow "Buat Tiket" (Lengkap)

```
User tap "Buat Tiket"
    │
    ▼
[1] CreateTicketScreen

    │
    ▼
[2] ticketProvider.createTicket(ticket)
    │
    ▼
[3] CreateTicketUseCase.call(ticket)
    │
    ▼
[4] TicketRepositoryImpl.createTicket(ticket)
    │
    ▼
[5] SupabaseTicketDataSource.createTicket(ticketData)
    │
    ▼
[6] Supabase REST API
    └── POST /rest/v1/tickets
        Body: {title, description, status:'open', priority, category,
               created_by:userId, assigned_to:null, attachment_urls:[]}
        Header: Prefer: return=representation
    │
    ▼
[7] Database Trigger: trg_ticket_insert_notification
    └── notify_ticket_change() → INSERT ke notifications untuk admin
    │
    ▼
[8] Response: TicketDTO ({id, title, ..., created_by:{...}, assigned_to:null})
    │
    ▼
[9] Kembali ke CreateTicketScreen
    │
    ├── Jika ada file:
    │     ▼
    │   [10] SupabaseStorageDataSource.uploadFiles(files, ticketId)
    │     │
    │     ▼
    │   [11] Storage REST API
    │     └── POST /storage/v1/object/ticket_attachments/{ticketId}/{timestamp}.{ext}
    │     │
    │     ▼
    │   [12] SupabaseTicketDataSource.updateAttachmentUrls(ticketId, urls)
    │     │
    │     ▼
    │   [13] PATCH /rest/v1/tickets?id=eq.{ticketId}
    │         Body: {attachment_urls: [url1, url2, ...]}
    │
    └── Navigator.pop(context, true)
          │
          ▼
        TicketListScreen.refresh()
```

### Flow "Assign Tiket" (Lengkap)

```
Admin tap "Assign Tiket" (status saat ini: assign)
    │
    ▼
[1] Bottom sheet pilih helpdesk
    │
    ▼
[2] ticketProvider.assignTicket(ticketId, helpdeskId)
    │
    ▼
[3] AssignTicketUseCase.call(ticketId, helpdeskId)
    │
    ▼
[4] TicketRepositoryImpl.assignTicket(ticketId, helpdeskId)
    │
    ├── [5] SupabaseTicketDataSource.assignAndSetInProgress(ticketId, helpdeskId)
    │     │
    │     ▼
    │   [6] PATCH /rest/v1/tickets?id=eq.{ticketId}
    │         Body: {assigned_to: helpdeskId, status: 'inprogress'}
    │     │
    │     ▼
    │   [7] Database Trigger: check_assign_permission (BEFORE UPDATE)
    │         └── Jika bukan admin → RAISE EXCEPTION
    │     │
    │     ▼
    │   [8] Database Trigger: on_ticket_update (AFTER UPDATE)
    │         └── notify_ticket_change() → INSERT notifications:
    │               ├── ke created_by: "Status Tiket Diubah ... inprogress - Ditugaskan ke ..."
    │               └── ke assigned_to: "Tiket Diassign ... kepada Anda"
    │
    ├── [9] SupabaseTicketDataSource.getHistory(ticketId)
    │
    └── [10] SupabaseTicketDataSource.addHistory({
               ticket_id, changed_by: adminId,
               action: 'Ditugaskan ke {nama}',
               to_status: 'inprogress'
             })
```

### Flow "Infinite Scroll" (Ticket List)

```
User buka TicketListScreen
    │
    ▼
loadTickets(statusFilter: null, page: 0, pageSize: 20)
    │
    ▼
GET /rest/v1/tickets?select=*,created_by:users!created_by(*),assigned_to:users!assigned_to(*)&order=created_at.desc&offset=0&limit=20
    │
    ▼
Response: 20 items → _hasMore = true, _page = 1
    │
    ▼
User scroll ke bawah (<= 200px dari bottom)
    │
    ▼
loadMore() → page: 2
    │
    ▼
GET ...&offset=20&limit=20
    │
    ▼
Response: 12 items (< 20) → _hasMore = false
    │
    ▼
Tidak ada loadMore lagi
```

### Flow "Baca Notifikasi"

```
NotificationScreen menampilkan daftar
    │
    ▼
User tap notifikasi (unread)
    │
    ├── Update lokal: set isRead = true (optimistic UI)
    ├── Decrement unreadCount
    │
    ▼
notifProvider.markAsRead(notifId)
    │
    ▼
PATCH /rest/v1/notifications?id=eq.{notifId}
  Body: {is_read: true}
    │
    ▼
Push TicketDetailScreen(ticketId)
```

---

## Appendix: Ringkasan Arrow Notation

| Simbol | Arti |
|--------|------|
| `→` | Transisi / aliran data |
| `Screen → Screen` | Navigasi push |
| `Screen ──pushReplacement──→` | Navigasi ganti screen |
| `Screen ──pushAndRemoveUntil──→` | Navigasi bersihkan stack |
| `Provider.method()` | Panggil provider |
| `DataSource.query()` | Query ke database |
| `INSERT INTO` | Database write |
| `SELECT ... WHERE` | Database read |
| `⟳` | Reload / refresh data |
