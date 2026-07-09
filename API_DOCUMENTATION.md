# E-Ticketing Helpdesk — API Documentation

**Version**: 1.2.0  
**Last Updated**: July 2026  
**Project**: E-Ticketing Helpdesk System  
**Tech Stack**: Flutter 3.x · Supabase (Postgres, Auth, REST API)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Authentication](#2-authentication)
3. [Database Schema](#3-database-schema)
4. [REST API Endpoints](#4-rest-api-endpoints)
5. [RPC Endpoints](#5-rpc-endpoints)
6. [Row Level Security (RLS)](#6-row-level-security-rls)
7. [Database Triggers & Functions](#7-database-triggers--functions)
8. [Flutter Internal Architecture](#8-flutter-internal-architecture)
9. [Error Codes](#9-error-codes)

---

## 1. Overview

The E-Ticketing Helpdesk is a ticketing management system with three roles:

| Role | Capabilities |
|------|-------------|
| **User** | Create tickets, track status, comment, receive notifications |
| **Helpdesk** | View all tickets, change status (inprogress→closed), reply to comments |
| **Admin** | View all tickets, assign tickets to helpdesk (assigns + sets inprogress), change status (open→assign), reply to comments |

### Architecture

```
┌─────────────────────────────────────────────┐
│              Flutter Application             │
│  ┌─────────┐  ┌──────────┐  ┌────────────┐  │
│  │   UI    │→ │ Providers│→ │ Use Cases  │  │
│  │ (Screen)│  │ (State)  │  │ (Business) │  │
│  └─────────┘  └──────────┘  └──────┬─────┘  │
│                                    │         │
│  ┌──────────────────────────────────┘         │
│  │  ┌────────────┐  ┌──────────────────────┐ │
│  │  │ Repository │→ │    Data Source        │ │
│  │  │ (Domain)   │  │ (Supabase REST/SDK)   │ │
│  │  └────────────┘  └──────────┬───────────┘ │
│  └──────────────────────────────┘              │
└────────────────────────────────────┬──────────┘
                                     │ HTTPS
┌────────────────────────────────────┴──────────┐
│            Supabase Backend                    │
│  ┌──────────┐  ┌─────────┐  ┌──────────────┐ │
│  │ Postgres │→ │  Auth   │→ │  REST API    │ │
│  │   (RLS)  │  │ (GoTrue)│  │  (PostgREST) │ │
│  └──────────┘  └─────────┘  └──────────────┘ │
└───────────────────────────────────────────────┘
```

### Base URL

```
https://zlvxinokxlrkgnlwzdsb.supabase.co
```

### Authentication Header

All API requests require the publishable anon key:

```
apikey: sb_publishable_VX45J-i5DNMiCJyisdxZXQ_j66BaV6K
Authorization: Bearer <JWT_ACCESS_TOKEN>
```

---

## 2. Authentication

Authentication is handled via Supabase Auth (GoTrue). The Flutter SDK manages tokens and sessions automatically.

### 2.1 Login

Authenticates a user with email and password.

```
POST /auth/v1/token?grant_type=password
```

#### Request

```json
{
  "email": "user@e-ticketing.demo",
  "password": "user123456"
}
```

#### Response (200 OK)

```json
{
  "access_token": "eyJhbGciOiJFUzI1NiIsImtpZCI6...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "eyJhbGciOiJFUzI1NiIs...",
  "user": {
    "id": "00000000-0000-0000-0000-000000000003",
    "email": "user@e-ticketing.demo",
    "role": "authenticated",
    "aud": "authenticated"
  }
}
```

#### Flutter Equivalent

```dart
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

After login, the profile is fetched from `public.users`:

```dart
final profile = await supabase
    .from('users')
    .select()
    .eq('id', response.user!.id)
    .single();
```

### 2.2 Register

Creates a new user account.

```
POST /auth/v1/signup
```

#### Request

```json
{
  "email": "newuser@example.com",
  "password": "securePassword123"
}
```

#### Flutter Implementation

```dart
// 1. Create auth user
final response = await supabase.auth.signUp(
  email: email,
  password: password,
);

// 2. Create profile in public.users
await supabase.from('users').insert({
  'id': response.user!.id,
  'username': username,
  'full_name': fullName,
  'avatar_url': '',
  'role': 'user',
});

// 3. Fetch back the profile
final profile = await supabase
    .from('users')
    .select()
    .eq('id', response.user!.id)
    .single();
```

**Note**: New registrations are always assigned the `user` role. Helpdesk and admin roles are assigned manually via the database.

### 2.3 Logout

```
POST /auth/v1/logout
```

#### Flutter Equivalent

```dart
await supabase.auth.signOut();
```

### 2.4 Session Management

On app startup, the SDK checks for a persisted session:

```dart
final session = supabase.auth.currentSession;
if (session != null) {
  final profile = await supabase
      .from('users')
      .select()
      .eq('id', session.user.id)
      .single();
}
```

### 2.5 Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@e-ticketing.demo` | `admin123` |
| Helpdesk | `helpdesk@e-ticketing.demo` | `helpdesk123` |
| User | `user@e-ticketing.demo` | `user123456` |

---

## 3. Database Schema

The system uses 5 tables in the `public` schema.

### 3.1 `users`

Linked to `auth.users`. Stores profile information.

| Column | Type | Constraints | Default |
|--------|------|-------------|---------|
| `id` | `uuid` | `PK`, FK → `auth.users(id)` ON DELETE CASCADE | |
| `username` | `text` | `NOT NULL`, `UNIQUE` | |
| `full_name` | `text` | `NOT NULL` | |
| `email` | `text` | | |
| `avatar_url` | `text` | `NOT NULL` | `''` |
| `role` | `text` | `NOT NULL`, CHECK (`user`, `helpdesk`, `admin`) | `'user'` |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` |

### 3.2 `tickets`

The core entity representing a support ticket.

| Column | Type | Constraints | Default |
|--------|------|-------------|---------|
| `id` | `uuid` | `PK` | `gen_random_uuid()` |
| `title` | `text` | `NOT NULL` | |
| `description` | `text` | `NOT NULL` | |
| `status` | `text` | `NOT NULL`, CHECK (`open`, `assign`, `inprogress`, `closed`) | `'open'` |
| `priority` | `text` | `NOT NULL`, CHECK (`low`, `medium`, `high`, `critical`) | `'medium'` |
| `category` | `text` | `NOT NULL`, CHECK (`Hardware`, `Software`, `Network`, `Account`) | |
| `created_by` | `uuid` | `NOT NULL`, FK → `users(id)` ON DELETE CASCADE | |
| `assigned_to` | `uuid` | FK → `users(id)` ON DELETE SET NULL | |
| `attachment_urls` | `text[]` | `NOT NULL` | `'{}'` |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` |
| `updated_at` | `timestamptz` | `NOT NULL` | `now()` |

#### Status Lifecycle

```
open ──→ assign ──→ inprogress ──→ closed
  ↑          │
  │          ▼
  │    (assign + set inprogress)
  └──────── Admin ──────────┘
```

| Transition | Performed By | Method |
|------------|-------------|--------|
| `open → assign` | Admin | `updateStatus` (status only) |
| `assign → inprogress` | Admin | `assignTicket` (assigns helpdesk + sets status simultaneously) |
| `inprogress → closed` | Helpdesk | `updateStatus` (status only) |

### 3.3 `comments`

Stores messages within a ticket thread.

| Column | Type | Constraints | Default |
|--------|------|-------------|---------|
| `id` | `uuid` | `PK` | `gen_random_uuid()` |
| `ticket_id` | `uuid` | `NOT NULL`, FK → `tickets(id)` ON DELETE CASCADE | |
| `author_id` | `uuid` | `NOT NULL`, FK → `users(id)` ON DELETE CASCADE | |
| `message` | `text` | `NOT NULL` | |
| `attachment_urls` | `text[]` | `NOT NULL` | `'{}'` |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` |

### 3.4 `ticket_history`

Audit log of status changes and assignments.

| Column | Type | Constraints | Default |
|--------|------|-------------|---------|
| `id` | `uuid` | `PK` | `gen_random_uuid()` |
| `ticket_id` | `uuid` | `NOT NULL`, FK → `tickets(id)` ON DELETE CASCADE | |
| `changed_by` | `uuid` | `NOT NULL`, FK → `users(id)` ON DELETE CASCADE | |
| `action` | `text` | `NOT NULL` | |
| `from_status` | `text` | CHECK (`open`, `assign`, `inprogress`, `closed`) | |
| `to_status` | `text` | CHECK (`open`, `assign`, `inprogress`, `closed`) | |
| `timestamp` | `timestamptz` | | `now()` |

### 3.5 `notifications`

Push-style notifications for users.

| Column | Type | Constraints | Default |
|--------|------|-------------|---------|
| `id` | `uuid` | `PK` | `gen_random_uuid()` |
| `user_id` | `uuid` | `NOT NULL`, FK → `users(id)` ON DELETE CASCADE | |
| `title` | `text` | `NOT NULL` | |
| `message` | `text` | `NOT NULL` | |
| `ticket_id` | `uuid` | FK → `tickets(id)` ON DELETE CASCADE | |
| `ticket_title` | `text` | | |
| `is_read` | `boolean` | `NOT NULL` | `false` |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` |

### 3.6 Indexes

```sql
-- Tickets
tickets_created_by_idx       ON tickets(created_by)
tickets_assigned_to_idx      ON tickets(assigned_to)
tickets_status_idx           ON tickets(status)
tickets_created_at_idx       ON tickets(created_at DESC)

-- Comments
comments_ticket_id_idx       ON comments(ticket_id)
comments_author_id_idx       ON comments(author_id)

-- Ticket History
ticket_history_ticket_id_idx ON ticket_history(ticket_id)

-- Notifications
notifications_user_id_idx    ON notifications(user_id)
notifications_user_unread_idx ON notifications(user_id) WHERE (is_read = false)
```

### 3.7 Entity Relationship Diagram

```
┌──────────┐        ┌───────────┐
│   users  │<─── FK ┤  tickets  │
│          │        │           │
│  id (PK) │──┐     │  id (PK)  │
│  username│  │     │  title    │
│  role    │  │     │  status   │
│  email   │  │     │  priority │
└──────────┘  │     │  category │
              │     │  created_by──┐
              │     │  assigned_to─┤
              │     │  created_at  │
              │     │  updated_at  │
              │     └──────────────┘
              │
┌──────────┐  │     ┌───────────────┐
│ comments │  │     │ ticket_history│
│          │  │     │               │
│  id (PK) │  │     │  id (PK)      │
│  ticket_id──┘     │  ticket_id────┘
│  author_id──┐     │  changed_by───┐
│  message   │     │  action       │
│  created_at│     │  from_status  │
└────────────┘     │  to_status    │
                   │  timestamp    │
┌────────────────┐ └───────────────┘
│ notifications  │
│                │
│  id (PK)       │
│  user_id ──────┤
│  title         │
│  message       │
│  ticket_id     │
│  ticket_title  │
│  is_read       │
│  created_at    │
└────────────────┘
```

---

## 4. REST API Endpoints

All endpoints are served by Supabase's PostgREST API at `/rest/v1/`. Responses are JSON.

### 4.1 Tickets

#### List Tickets

```
GET /rest/v1/tickets
```

Retrieves tickets with nested user profiles.

**Query Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `select` | string | Column selection with joins |
| `status` | string (optional) | Filter by status (`eq.status`) |
| `order` | string | Sort order |

**Example:**

```
GET /rest/v1/tickets?select=*,created_by:users!created_by(*),assigned_to:users!assigned_to(*)&order=created_at.desc
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('tickets')
    .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
    .order('created_at', ascending: false);
```

**Response (200):**

```json
[
  {
    "id": "f7924bf2-23a5-4b0d-a1bb-a4985aa26442",
    "title": "Testing Notifikasi Trigger",
    "description": "Test apakah notifikasi trigger berfungsi",
    "status": "inprogress",
    "priority": "medium",
    "category": "Software",
    "created_by": {
      "id": "00000000-0000-0000-0000-000000000003",
      "username": "user",
      "full_name": "User Demo",
      "email": "user@e-ticketing.demo",
      "role": "user",
      "created_at": "2026-06-06T00:00:00+00:00"
    },
    "assigned_to": {
      "id": "00000000-0000-0000-0000-000000000002",
      "username": "helpdesk",
      "full_name": "Helpdesk Demo",
      "email": "helpdesk@e-ticketing.demo",
      "role": "helpdesk",
      "created_at": "2026-06-06T00:00:00+00:00"
    },
    "attachment_urls": [],
    "created_at": "2026-06-06T00:10:20+00:00",
    "updated_at": "2026-06-06T00:10:32+00:00"
  }
]
```

---

#### Get Ticket by ID

```
GET /rest/v1/tickets?id=eq.{ticket_id}
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('tickets')
    .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
    .eq('id', ticketId)
    .single();
```

**Response (200):**

Single ticket object (same shape as list item above).

---

#### Create Ticket

```
POST /rest/v1/tickets
```

Only users with role `user` can create tickets (enforced by RLS).

**Request Headers:**

```
Prefer: return=representation
```

**Request Body:**

```json
{
  "title": "Laptop Tidak Bisa Menyala",
  "description": "Setelah update Windows, laptop saya tidak bisa booting",
  "category": "Hardware",
  "priority": "high",
  "created_by": "00000000-0000-0000-0000-000000000003",
  "assigned_to": null,
  "attachment_urls": []
}
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('tickets')
    .insert({
      'title': title,
      'description': description,
      'status': 'open',
      'priority': priority,
      'category': category,
      'created_by': userId,
      'assigned_to': null,
      'attachment_urls': [],
    })
    .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
    .single();
```

**Response (201):**

```json
{
  "id": "a8996db7-26e9-418f-8158-bfa546e579b2",
  "title": "Laptop Tidak Bisa Menyala",
  "description": "Setelah update Windows, laptop saya tidak bisa booting",
  "status": "open",
  "priority": "high",
  "category": "Hardware",
  "created_by": {
    "id": "00000000-0000-0000-0000-000000000003",
    "username": "user",
    "full_name": "User Demo",
    "role": "user"
  },
  "assigned_to": null,
  "attachment_urls": [],
  "created_at": "2026-06-06T00:15:00+00:00",
  "updated_at": "2026-06-06T00:15:00+00:00"
}
```

---

#### Update Ticket Status

```
PATCH /rest/v1/tickets?id=eq.{ticket_id}
```

Only users with role `helpdesk` or `admin` can update tickets (enforced by RLS).

**Request Body:**

```json
{
  "status": "inprogress"
}
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('tickets')
    .update({'status': newStatus})
    .eq('id', ticketId)
    .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
    .single();
```

**Response (200):**

Full updated ticket object.

---

#### Assign Ticket

```
PATCH /rest/v1/tickets?id=eq.{ticket_id}
```

**Request Body:**

```json
{
  "assigned_to": "00000000-0000-0000-0000-000000000002"
}
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('tickets')
    .update({'assigned_to': assigneeId})
    .eq('id', ticketId)
    .select('*, created_by:users!created_by(*), assigned_to:users!assigned_to(*)')
    .single();
```

#### Update Attachment URLs

Updates the `attachment_urls` array after file uploads.

```
PATCH /rest/v1/tickets?id=eq.{ticket_id}
```

**Request Body:**

```json
{
  "attachment_urls": ["https://...file1.pdf", "https://...file2.png"]
}
```

**Flutter Equivalent:**

```dart
await supabase
    .from('tickets')
    .update({'attachment_urls': urls})
    .eq('id', ticketId);
```

**Note:** Requires the `tickets_update_own` RLS policy (ticket creator) or `tickets_update` policy (admin/helpdesk).

---

### 4.2 Users

#### Get User Profile

```
GET /rest/v1/users?id=eq.{user_id}
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('users')
    .select()
    .eq('id', userId)
    .single();
```

**Response (200):**

```json
{
  "id": "00000000-0000-0000-0000-000000000003",
  "username": "user",
  "full_name": "User Demo",
  "email": "user@e-ticketing.demo",
  "avatar_url": "",
  "role": "user",
  "created_at": "2026-06-06T00:00:00+00:00"
}
```

---

#### List Staff Users (Helpdesk + Admin)

```
GET /rest/v1/users?role=in.(helpdesk,admin)
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('users')
    .select()
    .inFilter('role', ['helpdesk', 'admin'])
    .order('full_name');
```

---

#### Create User Profile (Registration)

```
POST /rest/v1/users
```

**Request Body:**

```json
{
  "id": "auth-user-uuid-here",
  "username": "newuser",
  "full_name": "New User",
  "avatar_url": "",
  "role": "user"
}
```

---

### 4.3 Comments

#### List Comments by Ticket

```
GET /rest/v1/comments?ticket_id=eq.{ticket_id}
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('comments')
    .select('*, author:users(*)')
    .eq('ticket_id', ticketId)
    .order('created_at', ascending: true);
```

**Response (200):**

```json
[
  {
    "id": "comment-uuid",
    "ticket_id": "ticket-uuid",
    "author_id": "user-uuid",
    "author": {
      "id": "user-uuid",
      "username": "helpdesk",
      "full_name": "Helpdesk Demo",
      "role": "helpdesk"
    },
    "message": "Kami sedang mengecek masalah Anda...",
    "attachment_urls": [],
    "created_at": "2026-06-06T00:20:00+00:00"
  }
]
```

---

#### Add Comment

```
POST /rest/v1/comments
```

**Request Body:**

```json
{
  "ticket_id": "ticket-uuid",
  "author_id": "user-uuid",
  "message": "Ini penjelasan tambahan dari saya",
  "attachment_urls": []
}
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('comments')
    .insert({
      'ticket_id': ticketId,
      'author_id': authorId,
      'message': message,
      'attachment_urls': [],
    })
    .select('*, author:users(*)')
    .single();
```

---

### 4.4 Notifications

#### List User Notifications

```
GET /rest/v1/notifications?user_id=eq.{user_id}
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('notifications')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);
```

**Response (200):**

```json
[
  {
    "id": "05280903-d475-45da-8260-c544df6ab169",
    "user_id": "00000000-0000-0000-0000-000000000002",
    "title": "Tiket Baru",
    "message": "Tiket \"Testing Notifikasi Trigger\" telah dibuat.",
    "ticket_id": "f7924bf2-23a5-4b0d-a1bb-a4985aa26442",
    "ticket_title": "Testing Notifikasi Trigger",
    "is_read": false,
    "created_at": "2026-06-06T00:10:20+00:00"
  }
]
```

---

#### Get Unread Count

```
GET /rest/v1/notifications?user_id=eq.{user_id}&is_read=eq.false&select=id
```

**Flutter Equivalent:**

```dart
final data = await supabase
    .from('notifications')
    .select('id')
    .eq('user_id', userId)
    .eq('is_read', false);
// count = data.length
```

---

#### Mark Notification as Read

```
PATCH /rest/v1/notifications?id=eq.{notification_id}
```

**Request Body:**

```json
{
  "is_read": true
}
```

**Flutter Equivalent:**

```dart
await supabase
    .from('notifications')
    .update({'is_read': true})
    .eq('id', notificationId);
```

---

#### Mark All as Read

```
PATCH /rest/v1/notifications?user_id=eq.{user_id}&is_read=eq.false
```

**Request Body:**

```json
{
  "is_read": true
}
```

**Flutter Equivalent:**

```dart
await supabase
    .from('notifications')
    .update({'is_read': true})
    .eq('user_id', userId)
    .eq('is_read', false);
```

---

### 4.5 Ticket History

#### Add History Entry

```
POST /rest/v1/ticket_history
```

**Request Body** (status change):

```json
{
  "ticket_id": "ticket-uuid",
  "changed_by": "user-uuid",
  "action": "Status changed to In Progress",
  "to_status": "inprogress"
}
```

**Request Body** (assignment):

```json
{
  "ticket_id": "ticket-uuid",
  "changed_by": "user-uuid",
  "action": "Assigned to Helpdesk Demo"
}
```

**Flutter Equivalent:**

```dart
await supabase
    .from('ticket_history')
    .insert({
      'ticket_id': ticketId,
      'changed_by': currentUserId,
      'action': action,
      'to_status': newStatus,
    });
```

---

## 5. RPC Endpoints

### 5.1 Get Statistics

Returns ticket counts grouped by status. Results are filtered by RLS (users see only their own tickets, staff see all).

```
POST /rest/v1/rpc/get_statistics
```

**Request Body:**

```json
{
  "user_id": null
}
```

Pass `user_id` to filter by a specific user, or `null` for all tickets visible via RLS.

**Flutter Equivalent:**

```dart
final data = await supabase.rpc('get_statistics', params: {
  'user_id': null,
});
```

**Response (200):**

```json
[
  {
    "total": 12,
    "open": 4,
    "assign": 0,
    "inprogress": 4,
    "closed": 1
  }
]
```

**SQL Definition:**

```sql
create or replace function get_statistics(user_id uuid default null)
returns table (
  total bigint,
  open bigint,
  "assign" bigint,
  inprogress bigint,
  closed bigint
)
language sql
security invoker
stable
as $$
  select
    count(*)::bigint as total,
    count(*) filter (where status = 'open')::bigint as open,
    count(*) filter (where status = 'assign')::bigint as "assign",
    count(*) filter (where status = 'inprogress')::bigint as inprogress,
    count(*) filter (where status = 'closed')::bigint as closed
  from tickets
  where (created_by = user_id or user_id is null);
$$;
```

---

## 6. Row Level Security (RLS)

All tables have RLS enabled. Policies are enforced on every query.

### 6.1 `users`

| Policy | Operation | Target | Logic |
|--------|-----------|--------|-------|
| `users_select_all` | SELECT | `authenticated` | All authenticated users can read any user profile |
| `users_insert_own` | INSERT | `authenticated` | Can only insert own profile (`auth.uid() = id`) |
| `users_update_own` | UPDATE | `authenticated` | Can only update own profile (`auth.uid() = id`) |

```sql
-- SELECT: All authenticated users can read any profile
create policy "users_select_all" on users for select
  to authenticated
  using (true);

-- INSERT: Can only insert own profile
create policy "users_insert_own" on users for insert
  to authenticated
  with check (auth.uid() = id);

-- UPDATE: Can only update own profile
create policy "users_update_own" on users for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);
```

### 6.2 `tickets`

| Policy | Operation | Target | Logic |
|--------|-----------|--------|-------|
| `tickets_select` | SELECT | `authenticated` | Own tickets OR any ticket if role is `helpdesk` or `admin` |
| `tickets_insert` | INSERT | `authenticated` | Must be `created_by` AND role must be `user`, `admin`, or `helpdesk` |
| `tickets_update` | UPDATE | `authenticated` | Only role `helpdesk` or `admin`. `assigned_to` change blocked by `check_assign_permission` trigger |
| `tickets_update_own` | UPDATE | `authenticated` | Ticket creator can update own ticket (`auth.uid() = created_by`) |

**SQL Definitions:**

```sql
-- SELECT: Users see their own tickets, staff see all
create policy "tickets_select" on tickets for select
  to authenticated
  using (
    auth.uid() = created_by
    or exists (
      select 1 from users
      where id = auth.uid() and role in ('helpdesk', 'admin')
    )
  );

-- INSERT: Any authenticated user can create tickets
create policy "tickets_insert" on tickets for insert
  to authenticated
  with check (
    auth.uid() = created_by
    and exists (
      select 1 from users
      where id = auth.uid() and role in ('user', 'admin', 'helpdesk')
    )
  );

-- UPDATE: Only staff can modify tickets
create policy "tickets_update" on tickets for update
  to authenticated
  using (
    exists (
      select 1 from users
      where id = auth.uid() and role in ('helpdesk', 'admin')
    )
  )
  with check (
    exists (
      select 1 from users
      where id = auth.uid() and role in ('helpdesk', 'admin')
    )
  );

-- UPDATE own: Ticket creator can update own ticket
create policy "tickets_update_own" on tickets for update
  to authenticated
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);
```

**Note:** Changing `assigned_to` is further restricted by the `check_assign_permission` database trigger — only admin can assign tickets. Helpdesk will receive an exception if they attempt to change `assigned_to`.

### 6.3 `comments`

| Policy | Operation | Target | Logic |
|--------|-----------|--------|-------|
| `comments_select` | SELECT | `authenticated` | Can view comments on tickets they can see |
| `comments_insert` | INSERT | `authenticated` | Can comment on tickets they can see |

Access to comments is gated by the parent ticket: users must be the ticket's `created_by` OR have role `helpdesk`/`admin`.

### 6.4 `ticket_history`

| Policy | Operation | Target | Logic |
|--------|-----------|--------|-------|
| `ticket_history_select` | SELECT | `authenticated` | Can view history of tickets they can see |
| `ticket_history_insert` | INSERT | `authenticated` | Can add history to tickets they can see |

### 6.5 `notifications`

| Policy | Operation | Target | Logic |
|--------|-----------|--------|-------|
| `notifications_select` | SELECT | `authenticated` | Only own notifications (`auth.uid() = user_id`) |
| `notifications_insert` | INSERT | `authenticated` | Allow any authenticated user/trigger to insert (`with check true`) |
| `notifications_update` | UPDATE | `authenticated` | Can only update own notifications (`auth.uid() = user_id`) |

```sql
-- INSERT: Allows database triggers to create notifications
create policy "notifications_insert" on notifications for insert
  to authenticated
  with check (true);
```

### 6.6 `ticket_attachments` (Storage Bucket)

Supabase Storage bucket for ticket attachment files. Public read access; write restricted to authenticated users.

| Bucket | Public | File Size Limit | Allowed MIME Types |
|--------|--------|-----------------|---------------------|
| `ticket_attachments` | `true` | 10 MB | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `application/pdf`, `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document` |

**Storage RLS Policies (on `storage.objects`):**

| Policy | Operation | Target | Logic |
|--------|-----------|--------|-------|
| `select_ticket_attachments` | SELECT | `authenticated` | Any authenticated user can read (bucket_id = `ticket_attachments`) |
| `insert_ticket_attachments` | INSERT | `authenticated` | Uploader must be authenticated (bucket_id = `ticket_attachments` AND `owner = auth.uid()`) |
| `delete_own_ticket_attachments` | DELETE | `authenticated` | Only file owner can delete (bucket_id = `ticket_attachments` AND `owner = auth.uid()`) |

```sql
-- Create bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ticket_attachments', 'ticket_attachments', true, 10485760,
  array['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf', ...]);

-- RLS policies
create policy "select_ticket_attachments" on storage.objects for select
  to authenticated using ( bucket_id = 'ticket_attachments' );

create policy "insert_ticket_attachments" on storage.objects for insert
  to authenticated with check ( bucket_id = 'ticket_attachments' and owner = auth.uid() );

create policy "delete_own_ticket_attachments" on storage.objects for delete
  to authenticated using ( bucket_id = 'ticket_attachments' and owner = auth.uid() );
```

**Upload Flow (Flutter):**

```dart
final bytes = await file.readAsBytes();
await supabase.storage
    .from('ticket_attachments')
    .uploadBinary('{ticket_id}/{timestamp}.{ext}', bytes);

final url = supabase.storage
    .from('ticket_attachments')
    .getPublicUrl('{ticket_id}/{timestamp}.{ext}');
```

---

## 7. Database Triggers & Functions

### 7.1 `handle_updated_at()`

Automatically updates `updated_at` on `tickets` whenever a row is modified.

```sql
create or replace function handle_updated_at()
returns trigger
language plpgsql
security invoker
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at
  before update on tickets
  for each row
  execute function handle_updated_at();
```

### 7.2 `check_assign_permission()`

Prevents helpdesk users from changing the `assigned_to` column. Only admin can reassign tickets.

```sql
create or replace function check_assign_permission()
returns trigger
language plpgsql
security invoker
as $$
begin
  if old.assigned_to is distinct from new.assigned_to then
    if not exists (select 1 from users where id = auth.uid() and role = 'admin') then
      raise exception 'Hanya admin yang dapat mengassign tiket';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_check_assign_permission
  before update on tickets
  for each row
  execute function check_assign_permission();
```

### 7.3 `notify_ticket_change()`

Creates notifications automatically when tickets are created or updated.

```sql
create or replace function notify_ticket_change()
returns trigger
language plpgsql
security invoker
as $$
begin
  if tg_op = 'INSERT' then
    -- Notify admin only when a ticket is created
    insert into notifications (user_id, title, message, ticket_id, ticket_title, is_read, created_at)
    select
      u.id,
      'Tiket Baru',
      'Tiket "' || new.title || '" telah dibuat oleh '
        || coalesce((select full_name from users where id = new.created_by), 'pengguna'),
      new.id,
      new.title,
      false,
      now()
    from users u
    where u.role = 'admin';

  elsif tg_op = 'UPDATE' then
    -- Notify ticket creator on status change (with assignee info)
    if old.status is distinct from new.status then
      insert into notifications (user_id, title, message, ticket_id, ticket_title, is_read, created_at)
      values (
        new.created_by,
        'Status Tiket Diubah',
        'Status tiket "' || coalesce(new.title, '') || '" berubah menjadi ' || coalesce(new.status, '')
        || case when new.assigned_to is not null
             then ' - Ditugaskan ke ' || coalesce((select full_name from users where id = new.assigned_to), 'petugas')
             else ''
           end,
        new.id,
        new.title,
        false,
        now()
      );

      -- Notify admin when ticket is closed
      if new.status = 'closed' and old.status != 'closed' then
        insert into notifications (user_id, title, message, ticket_id, ticket_title, is_read, created_at)
        select
          u.id,
          'Tiket Selesai',
          'Tiket "' || coalesce(new.title, '') || '" telah selesai dikerjakan oleh '
            || coalesce((select full_name from users where id = new.assigned_to), 'petugas'),
          new.id,
          new.title,
          false,
          now()
        from users u
        where u.role = 'admin';
      end if;
    end if;

    -- Notify assigned helpdesk
    if old.assigned_to is distinct from new.assigned_to and new.assigned_to is not null then
      insert into notifications (user_id, title, message, ticket_id, ticket_title, is_read, created_at)
      values (
        new.assigned_to,
        'Tiket Diassign',
        'Tiket "' || coalesce(new.title, '') || '" telah diassign kepada Anda untuk dikerjakan',
        new.id,
        new.title,
        false,
        now()
      );
    end if;
  end if;

  return new;
end;
$$;

-- Trigger for status changes and assignments
create trigger on_ticket_update
  after update on tickets
  for each row
  execute function notify_ticket_change();

-- Trigger for new tickets
create trigger trg_ticket_insert_notification
  after insert on tickets
  for each row
  execute function notify_ticket_change();
```

### 7.4 `notify_new_comment()`

Automatically notifies the ticket owner when a new comment is added by someone else.

```sql
create or replace function notify_new_comment()
returns trigger
language plpgsql
security invoker
as $$
declare
  t_owner uuid;
  t_title text;
begin
  select created_by, title into t_owner, t_title from tickets where id = new.ticket_id;

  if t_owner is not null and t_owner != new.author_id then
    insert into notifications (user_id, title, message, ticket_id, ticket_title, is_read, created_at)
    values (
      t_owner,
      'Komentar Baru',
      'Tiket "' || coalesce(t_title, '') || '" mendapat komentar baru',
      new.ticket_id,
      t_title,
      false,
      now()
    );
  end if;

  return new;
end;
$$;

create trigger on_comment_insert
  after insert on comments
  for each row
  execute function notify_new_comment();
```

#### Notification Types

| Event | Title | Recipient | Example Message |
|-------|-------|-----------|-----------------|
| Ticket Created | `Tiket Baru` | Admin only | `Tiket "Laptop Rusak" telah dibuat oleh User Demo.` |
| Status Changed | `Status Tiket Diubah` | Ticket creator | `Status tiket "Laptop Rusak" berubah menjadi inprogress - Ditugaskan ke Helpdesk Demo` |
| Ticket Assigned | `Tiket Diassign` | Assigned user (helpdesk) | `Tiket "Laptop Rusak" telah diassign kepada Anda untuk dikerjakan` |
| Ticket Closed | `Tiket Selesai` | All admin | `Tiket "Laptop Rusak" telah selesai dikerjakan oleh Helpdesk Demo` |
| New Comment | `Komentar Baru` | Ticket owner (if not the commenter) | `Tiket "Laptop Rusak" mendapat komentar baru` |

---

## 8. Flutter Internal Architecture

### 8.1 Layer Overview

```
┌──────────────────────────────────────────────────┐
│                 Presentation                      │
│  Screens → Providers (ChangeNotifier) → Widgets  │
├──────────────────────────────────────────────────┤
│                   Domain                          │
│  Entities → Repository Interfaces → Use Cases     │
├──────────────────────────────────────────────────┤
│                    Data                           │
│  DTOs (json_serializable) → Data Sources →        │
│  Repository Implementations                       │
├──────────────────────────────────────────────────┤
│                  Core                             │
│  SupabaseConfig (dotenv) → Theme → Network        │
└──────────────────────────────────────────────────┘
```

### 8.2 Data Sources

Each wraps the `SupabaseClient` and handles direct API calls.

| Data Source | File | Key Methods |
|-------------|------|-------------|
| `SupabaseAuthDataSource` | `lib/data/datasources/supabase_auth_data_source.dart` | `login`, `register`, `logout`, `getCurrentUser`, `updateProfile`, `resetPassword` |
| `SupabaseTicketDataSource` | `lib/data/datasources/supabase_ticket_data_source.dart` | `getTickets`, `getTicketById`, `createTicket`, `updateStatus`, `assignAndSetInProgress`, `updateAttachmentUrls`, `getStatistics`, `getHelpdeskUsers`, `getHistory`, `addHistory` |
| `SupabaseCommentDataSource` | `lib/data/datasources/supabase_comment_data_source.dart` | `getComments`, `addComment` |
| `SupabaseNotificationDataSource` | `lib/data/datasources/supabase_notification_data_source.dart` | `getNotifications`, `getUnreadCount`, `markAsRead`, `markAllAsRead` |
| `SupabaseStorageDataSource` | `lib/data/datasources/supabase_storage_data_source.dart` | `uploadFiles`, `deleteFile` |

### 8.3 Repository Interfaces

| Interface | File | Methods |
|-----------|------|---------|
| `AuthRepository` | `lib/domain/repositories/auth_repository.dart` | `login`, `register`, `logout`, `getCurrentUser`, `updateProfile`, `resetPassword` |
| `TicketRepository` | `lib/domain/repositories/ticket_repository.dart` | `getTickets`, `getTicketById`, `createTicket`, `updateTicketStatus`, `assignTicket`, `updateAttachmentUrls`, `getStatistics`, `getHelpdeskUsers` |
| `CommentRepository` | `lib/domain/repositories/comment_repository.dart` | `getComments`, `addComment` |
| `NotificationRepository` | `lib/domain/repositories/notification_repository.dart` | `getNotifications`, `getUnreadCount`, `markAsRead`, `markAllAsRead` |

### 8.4 Use Cases

Each use case wraps a single repository method and follows the `call()` convention.

| Use Case | Input | Output |
|----------|-------|--------|
| `LoginUseCase` | `(email, password)` | `User` |
| `RegisterUseCase` | `(username, password, fullName, email)` | `User` |
| `LogoutUseCase` | `()` | `void` |
| `GetCurrentUserUseCase` | `()` | `User?` |
| `UpdateProfileUseCase` | `(User user)` | `User` |
| `ResetPasswordUseCase` | `(String newPassword)` | `void` |
| `GetTicketsUseCase` | `({TicketStatus? statusFilter, int page, int pageSize})` | `List<Ticket>` |
| `GetTicketByIdUseCase` | `(String id)` | `Ticket` |
| `CreateTicketUseCase` | `(Ticket ticket)` | `Ticket` |
| `UpdateTicketStatusUseCase` | `(String ticketId, TicketStatus newStatus)` | `Ticket` |
| `AssignTicketUseCase` | `(String ticketId, String assigneeId)` | `Ticket` |
| `UpdateAttachmentUrlsUseCase` | `(String ticketId, List<String> urls)` | `void` |
| `GetStatisticsUseCase` | `({String? userId})` | `Map<String, int>` |
| `GetHelpdeskUsersUseCase` | `()` | `List<User>` |
| `GetCommentsUseCase` | `(String ticketId)` | `List<Comment>` |
| `AddCommentUseCase` | `({ticketId, authorId, message})` | `Comment` |
| `GetNotificationsUseCase` | `(String userId)` | `List<AppNotification>` |
| `GetUnreadCountUseCase` | `(String userId)` | `int` |
| `MarkAsReadUseCase` | `(String notificationId)` | `void` |
| `MarkAllAsReadUseCase` | `(String userId)` | `void` |

### 8.5 Providers (State Management)

| Provider | State Held |
|----------|------------|
| `AuthProvider` | `currentUser`, `isLoading`, `error` |
| `TicketProvider` | `tickets`, `activeTickets`, `selectedTicket`, `statistics`, `helpdeskUsers`, `isLoading`, `isLoadingMore`, `hasMore`, `error` |
| `NotificationProvider` | `notifications`, `unreadCount`, `isLoading`, `error` |

### 8.6 Dependency Injection (main.dart)

```dart
final supabase = Supabase.instance.client;

final authDataSource = SupabaseAuthDataSource(supabase);
final ticketDataSource = SupabaseTicketDataSource(supabase);
final commentDataSource = SupabaseCommentDataSource(supabase);
final notificationDataSource = SupabaseNotificationDataSource(supabase);
final storageDataSource = SupabaseStorageDataSource(supabase);

final authRepo = AuthRepositoryImpl(authDataSource);
final notificationRepo = NotificationRepositoryImpl(notificationDataSource);
final ticketRepo = TicketRepositoryImpl(ticketDataSource, commentDataSource);
final commentRepo = CommentRepositoryImpl(commentDataSource);
```

All providers are registered via `MultiProvider` in `ETicketingApp.build()`, and `SupabaseStorageDataSource` is provided as a plain `Provider` for screens that need file upload capability.

---

## 9. Error Codes

| HTTP Status | Meaning | Common Causes |
|-------------|---------|---------------|
| **200** | Success | Request completed successfully |
| **201** | Created | Resource was created (INSERT) |
| **204** | Success (no content) | UPDATE/DELETE succeeded |
| **400** | Bad Request | Invalid JSON, missing required fields, invalid enum value |
| **401** | Unauthorized | Missing or invalid JWT token |
| **403** | Forbidden | RLS policy blocked the operation |
| **404** | Not Found | Resource does not exist |
| **406** | Not Acceptable | Invalid `Prefer` header or content negotiation |
| **500** | Internal Server Error | Database error or server-side exception |

### Common RLS Errors

#### "User cannot create tickets" (403)

The user's role is not `user`, `admin`, or `helpdesk`. All authenticated user roles can create tickets.

#### "Cannot update ticket" (403)

The user's role is not `helpdesk` or `admin`. Only staff can update tickets. Ticket creators can update their own tickets via the `tickets_update_own` policy.

#### "Cannot assign ticket" (403)

The user's role is not `admin`. Only admins can change the `assigned_to` column, enforced by the `check_assign_permission` database trigger.

#### "Cannot view ticket" (404 or empty list)

The user is not the `created_by` and their role is not `helpdesk` or `admin`.

---

## Appendix: Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| **Admin** | `admin@e-ticketing.demo` | `admin123` |
| **Helpdesk** | `helpdesk@e-ticketing.demo` | `helpdesk123` |
| **User** | `user@e-ticketing.demo` | `user123456` |
