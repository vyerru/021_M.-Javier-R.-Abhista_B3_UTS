# E-Ticketing Helpdesk — API Documentation

**Version**: 1.0.0  
**Last Updated**: June 2026  
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
| **Helpdesk** | View all tickets, update status, assign tickets, reply to comments |
| **Admin** | Same as Helpdesk, plus user management (future) |

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
| `status` | `text` | `NOT NULL`, CHECK (`open`, `inProgress`, `resolved`, `closed`) | `'open'` |
| `priority` | `text` | `NOT NULL`, CHECK (`low`, `medium`, `high`, `critical`) | `'medium'` |
| `category` | `text` | `NOT NULL`, CHECK (`Hardware`, `Software`, `Network`, `Account`) | |
| `created_by` | `uuid` | `NOT NULL`, FK → `users(id)` ON DELETE CASCADE | |
| `assigned_to` | `uuid` | FK → `users(id)` ON DELETE SET NULL | |
| `attachment_urls` | `text[]` | `NOT NULL` | `'{}'` |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` |
| `updated_at` | `timestamptz` | `NOT NULL` | `now()` |

#### Status Lifecycle

```
open ──→ inProgress ──→ resolved ──→ closed
  ↑                        │
  └────────────────────────┘
```

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
| `from_status` | `text` | CHECK (`open`, `inProgress`, `resolved`, `closed`) | |
| `to_status` | `text` | CHECK (`open`, `inProgress`, `resolved`, `closed`) | |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` |

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
                   │  created_at   │
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
    "status": "inProgress",
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
  "status": "inProgress"
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
  "to_status": "inProgress"
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
    "inProgress": 3,
    "resolved": 4,
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
  "inProgress" bigint,
  resolved bigint,
  closed bigint
)
language sql
security invoker
stable
as $$
  select
    count(*)::bigint as total,
    count(*) filter (where status = 'open')::bigint as open,
    count(*) filter (where status = 'inProgress')::bigint as "inProgress",
    count(*) filter (where status = 'resolved')::bigint as resolved,
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

### 6.2 `tickets`

| Policy | Operation | Target | Logic |
|--------|-----------|--------|-------|
| `tickets_select` | SELECT | `authenticated` | Own tickets OR any ticket if role is `helpdesk` or `admin` |
| `tickets_insert` | INSERT | `authenticated` | Must be `created_by` AND role must be `user` |
| `tickets_update` | UPDATE | `authenticated` | Only role `helpdesk` or `admin` |

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

-- INSERT: Only regular users can create tickets
create policy "tickets_insert" on tickets for insert
  to authenticated
  with check (
    auth.uid() = created_by
    and exists (
      select 1 from users
      where id = auth.uid() and role = 'user'
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
```

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
| `notifications_update` | UPDATE | `authenticated` | Can only update own notifications (`auth.uid() = user_id`) |

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

### 7.2 `notify_ticket_change()`

Creates notifications automatically when tickets are created or updated.

```sql
create or replace function notify_ticket_change()
returns trigger
language plpgsql
security invoker
as $$
begin
  if tg_op = 'INSERT' then
    -- Notify all staff when a ticket is created
    insert into notifications (user_id, title, message, ticket_id, ticket_title, is_read, created_at)
    select
      u.id,
      'Tiket Baru',
      'Tiket "' || new.title || '" telah dibuat.',
      new.id,
      new.title,
      false,
      now()
    from users u
    where u.role in ('helpdesk', 'admin');

  elsif tg_op = 'UPDATE' then
    -- Notify ticket creator when status changes
    if old.status is distinct from new.status then
      insert into notifications (user_id, title, message, ticket_id, ticket_title, is_read, created_at)
      values (
        new.created_by,
        'Status Tiket Diubah',
        'Status tiket "' || coalesce(new.title, '') || '" berubah menjadi ' || coalesce(new.status, ''),
        new.id,
        new.title,
        false,
        now()
      );
    end if;

    -- Notify assigned user
    if old.assigned_to is distinct from new.assigned_to and new.assigned_to is not null then
      insert into notifications (user_id, title, message, ticket_id, ticket_title, is_read, created_at)
      values (
        new.assigned_to,
        'Tiket Diassign',
        'Tiket "' || coalesce(new.title, '') || '" telah diassign kepada Anda',
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

#### Notification Types

| Event | Title | Recipient | Example Message |
|-------|-------|-----------|-----------------|
| Ticket Created | `Tiket Baru` | All helpdesk + admin | `Tiket "Laptop Rusak" telah dibuat.` |
| Status Changed | `Status Tiket Diubah` | Ticket creator | `Status tiket "Laptop Rusak" berubah menjadi inProgress` |
| Ticket Assigned | `Tiket Diassign` | Assigned user | `Tiket "Laptop Rusak" telah diassign kepada Anda` |

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
| `SupabaseAuthDataSource` | `lib/data/datasources/supabase_auth_data_source.dart` | `login`, `register`, `logout`, `getCurrentUser` |
| `SupabaseTicketDataSource` | `lib/data/datasources/supabase_ticket_data_source.dart` | `getTickets`, `getTicketById`, `createTicket`, `updateStatus`, `assignTicket`, `getStatistics`, `getHelpdeskUsers`, `addHistory` |
| `SupabaseCommentDataSource` | `lib/data/datasources/supabase_comment_data_source.dart` | `getComments`, `addComment` |
| `SupabaseNotificationDataSource` | `lib/data/datasources/supabase_notification_data_source.dart` | `getNotifications`, `getUnreadCount`, `markAsRead`, `markAllAsRead` |

### 8.3 Repository Interfaces

| Interface | File | Methods |
|-----------|------|---------|
| `AuthRepository` | `lib/domain/repositories/auth_repository.dart` | `login`, `register`, `logout`, `getCurrentUser` |
| `TicketRepository` | `lib/domain/repositories/ticket_repository.dart` | `getTickets`, `getTicketById`, `createTicket`, `updateTicketStatus`, `assignTicket`, `getStatistics`, `getHelpdeskUsers` |
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
| `GetTicketsUseCase` | `({TicketStatus? statusFilter})` | `List<Ticket>` |
| `GetTicketByIdUseCase` | `(String id)` | `Ticket` |
| `CreateTicketUseCase` | `(Ticket ticket)` | `Ticket` |
| `UpdateTicketStatusUseCase` | `(String ticketId, TicketStatus newStatus)` | `Ticket` |
| `AssignTicketUseCase` | `(String ticketId, String assigneeId)` | `Ticket` |
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
| `TicketProvider` | `tickets`, `statistics`, `isLoading`, `error` |
| `NotificationProvider` | `notifications`, `unreadCount`, `isLoading` |

### 8.6 Dependency Injection (main.dart)

```dart
final supabase = Supabase.instance.client;

final authDataSource = SupabaseAuthDataSource(supabase);
final ticketDataSource = SupabaseTicketDataSource(supabase);
final commentDataSource = SupabaseCommentDataSource(supabase);
final notificationDataSource = SupabaseNotificationDataSource(supabase);

final authRepo = AuthRepositoryImpl(authDataSource);
final notificationRepo = NotificationRepositoryImpl(notificationDataSource);
final ticketRepo = TicketRepositoryImpl(ticketDataSource, commentDataSource);
final commentRepo = CommentRepositoryImpl(commentDataSource);
```

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

The user's role is not `user` (e.g., helpdesk or admin trying to insert a ticket). Only regular users can create tickets.

#### "Cannot update ticket" (403)

The user's role is not `helpdesk` or `admin`. Only staff can update ticket status and assignment.

#### "Cannot view ticket" (404 or empty list)

The user is not the `created_by` and their role is not `helpdesk` or `admin`.

---

## Appendix: Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| **Admin** | `admin@e-ticketing.demo` | `admin123` |
| **Helpdesk** | `helpdesk@e-ticketing.demo` | `helpdesk123` |
| **User** | `user@e-ticketing.demo` | `user123456` |
