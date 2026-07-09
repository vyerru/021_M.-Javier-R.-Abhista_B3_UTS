-- Add email column back to public.users
alter table public.users add column if not exists email text;

-- Drop old restrictive RLS policies
drop policy if exists users_select_own on public.users;
drop policy if exists users_insert_own on public.users;
drop policy if exists users_update_own on public.users;

-- Create proper RLS policies
drop policy if exists users_select_all on public.users;
create policy users_select_all on public.users
  for select
  to authenticated
  using (true);

drop policy if exists users_insert_own on public.users;
create policy users_insert_own on public.users
  for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists users_update_own on public.users;
create policy users_update_own on public.users
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);
-- Add missing INSERT policy on tickets
drop policy if exists tickets_insert on public.tickets;
create policy tickets_insert on public.tickets
  for insert
  to authenticated
  with check (auth.uid() = created_by);
-- Migration: initial_schema
-- Description: Create all tables, RLS policies, triggers, and helper functions

-- ============================================================
-- 1. TABLES
-- ============================================================

-- 1.1 Users (profiles linked to auth.users)
create table if not exists users (
  id uuid references auth.users(id) on delete cascade primary key,
  username text unique not null,
  full_name text not null,
  avatar_url text not null default '',
  role text not null default 'user'
    check (role in ('user', 'helpdesk', 'admin')),
  created_at timestamptz not null default now()
);

-- 1.2 Tickets
create table if not exists tickets (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null,
  status text not null default 'open'
    check (status in ('open', 'inProgress', 'resolved', 'closed')),
  priority text not null default 'medium'
    check (priority in ('low', 'medium', 'high', 'critical')),
  category text not null
    check (category in ('Hardware', 'Software', 'Network', 'Account')),
  created_by uuid not null references users(id) on delete cascade,
  assigned_to uuid references users(id) on delete set null,
  attachment_urls text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 1.3 Comments
create table if not exists comments (
  id uuid default gen_random_uuid() primary key,
  ticket_id uuid not null references tickets(id) on delete cascade,
  author_id uuid not null references users(id) on delete cascade,
  message text not null,
  attachment_urls text[] not null default '{}',
  created_at timestamptz not null default now()
);

-- 1.4 Ticket History
create table if not exists ticket_history (
  id uuid default gen_random_uuid() primary key,
  ticket_id uuid not null references tickets(id) on delete cascade,
  changed_by uuid not null references users(id) on delete cascade,
  action text not null,
  from_status text
    check (from_status in ('open', 'inProgress', 'resolved', 'closed')),
  to_status text
    check (to_status in ('open', 'inProgress', 'resolved', 'closed')),
  created_at timestamptz not null default now()
);

-- 1.5 Notifications
create table if not exists notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references users(id) on delete cascade,
  title text not null,
  message text not null,
  ticket_id uuid references tickets(id) on delete cascade,
  ticket_title text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 2. INDEXES (FK columns + query patterns)
-- ============================================================

create index if not exists tickets_created_by_idx on tickets(created_by);
create index if not exists tickets_assigned_to_idx on tickets(assigned_to);
create index if not exists tickets_status_idx on tickets(status);
create index if not exists tickets_created_at_idx on tickets(created_at desc);

create index if not exists comments_ticket_id_idx on comments(ticket_id);
create index if not exists comments_author_id_idx on comments(author_id);

create index if not exists ticket_history_ticket_id_idx on ticket_history(ticket_id);

create index if not exists notifications_user_id_idx on notifications(user_id);
create index if not exists notifications_user_unread_idx on notifications(user_id) where (is_read = false);

-- ============================================================
-- 3. TRIGGER: auto-update updated_at on tickets
-- ============================================================

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

-- ============================================================
-- 4. FUNCTION: get_statistics
-- ============================================================

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

-- ============================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================

-- 5.1 Users
alter table users enable row level security;

drop policy if exists "users_select_own" on users;
create policy "users_select_own" on users for select
  to authenticated
  using ( auth.uid() = id );

drop policy if exists "users_insert_own" on users;
create policy "users_insert_own" on users for insert
  to authenticated
  with check ( auth.uid() = id );

drop policy if exists "users_update_own" on users;
create policy "users_update_own" on users for update
  to authenticated
  using ( auth.uid() = id )
  with check ( auth.uid() = id );

-- 5.2 Tickets
alter table tickets enable row level security;

drop policy if exists "tickets_select" on tickets;
create policy "tickets_select" on tickets for select
  to authenticated
  using (
    auth.uid() = created_by
    or exists (
      select 1 from users
      where id = auth.uid() and role in ('helpdesk', 'admin')
    )
  );

drop policy if exists "tickets_insert" on tickets;
create policy "tickets_insert" on tickets for insert
  to authenticated
  with check ( auth.uid() = created_by );

drop policy if exists "tickets_update" on tickets;
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

-- 5.3 Comments
alter table comments enable row level security;

drop policy if exists "comments_select" on comments;
create policy "comments_select" on comments for select
  to authenticated
  using (
    exists (
      select 1 from tickets
      where tickets.id = comments.ticket_id
      and (
        tickets.created_by = auth.uid()
        or exists (
          select 1 from users
          where users.id = auth.uid() and users.role in ('helpdesk', 'admin')
        )
      )
    )
  );

drop policy if exists "comments_insert" on comments;
create policy "comments_insert" on comments for insert
  to authenticated
  with check (
    exists (
      select 1 from tickets
      where tickets.id = ticket_id
      and (
        tickets.created_by = auth.uid()
        or exists (
          select 1 from users
          where users.id = auth.uid() and users.role in ('helpdesk', 'admin')
        )
      )
    )
  );

-- 5.4 Ticket History
alter table ticket_history enable row level security;

drop policy if exists "ticket_history_select" on ticket_history;
create policy "ticket_history_select" on ticket_history for select
  to authenticated
  using (
    exists (
      select 1 from tickets
      where tickets.id = ticket_history.ticket_id
      and (
        tickets.created_by = auth.uid()
        or exists (
          select 1 from users
          where users.id = auth.uid() and users.role in ('helpdesk', 'admin')
        )
      )
    )
  );

drop policy if exists "ticket_history_insert" on ticket_history;
create policy "ticket_history_insert" on ticket_history for insert
  to authenticated
  with check (
    exists (
      select 1 from tickets
      where tickets.id = ticket_id
      and (
        tickets.created_by = auth.uid()
        or exists (
          select 1 from users
          where users.id = auth.uid() and users.role in ('helpdesk', 'admin')
        )
      )
    )
  );

-- 5.5 Notifications
alter table notifications enable row level security;

drop policy if exists "notifications_select" on notifications;
create policy "notifications_select" on notifications for select
  to authenticated
  using ( auth.uid() = user_id );

drop policy if exists "notifications_update" on notifications;
create policy "notifications_update" on notifications for update
  to authenticated
  using ( auth.uid() = user_id )
  with check ( auth.uid() = user_id );
-- Fix notification triggers: remove duplicate, unify into notify_ticket_change

-- Drop unused RPC function (was meant for Dart code, now handled by triggers)
drop function if exists public.create_notification;

-- Remove duplicate trigger and function (English messages, fired on INSERT+UPDATE)
drop trigger if exists trg_ticket_notification on tickets;
drop function if exists handle_ticket_notification;

-- Recreate notify_ticket_change to handle both INSERT and UPDATE
create or replace function notify_ticket_change()
returns trigger
language plpgsql
security invoker
as $$
begin
  if tg_op = 'INSERT' then
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

-- Recreate triggers (drop first for idempotency)
drop trigger if exists on_ticket_update on tickets;
create trigger on_ticket_update
  after update on tickets
  for each row
  execute function notify_ticket_change();

drop trigger if exists trg_ticket_insert_notification on tickets;
create trigger trg_ticket_insert_notification
  after insert on tickets
  for each row
  execute function notify_ticket_change();
-- Restrict ticket creation to users with role 'user' only
-- Helpdesk and admin should not be able to create tickets

drop policy if exists tickets_insert on public.tickets;
create policy tickets_insert on public.tickets
  for insert
  to authenticated
  with check (
    auth.uid() = created_by
    and exists (
      select 1 from public.users
      where id = auth.uid() and role = 'user'
    )
  );
-- Migration: update_status_flow
-- Description: Mengubah status flow: open→assign→inprogress→closed
-- + RLS, trigger notifikasi, fungsi statistik

-- ============================================================
-- 1. UPDATE CHECK CONSTRAINTS + DATA MIGRATION
-- ============================================================

alter table tickets
  drop constraint if exists chk_tickets_status cascade;

update tickets set status = 'inprogress' where status in ('inProgress', 'resolved');
update ticket_history set from_status = 'inprogress' where from_status in ('inProgress', 'resolved');
update ticket_history set to_status = 'inprogress' where to_status in ('inProgress', 'resolved');

alter table tickets
  add constraint chk_tickets_status
  check (status in ('open', 'assign', 'inprogress', 'closed'));

-- ============================================================
-- 2. UPDATE get_statistics FUNCTION
-- ============================================================

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

-- ============================================================
-- 3. UPDATE NOTIFICATION TRIGGER
-- ============================================================

create or replace function notify_ticket_change()
returns trigger
language plpgsql
security invoker
as $$
begin
  if tg_op = 'INSERT' then
    -- Notify admin when ticket is created by user/admin
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
    -- Notify creator (user) on any status change
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

      -- Notify admin when ticket is closed (helpdesk finished)
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

    -- Notify helpdesk when assigned
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

-- ============================================================
-- 4. UPDATE RLS: tickets_insert (allow user AND admin)
-- ============================================================

drop policy if exists tickets_insert on public.tickets;
create policy tickets_insert on public.tickets
  for insert
  to authenticated
  with check (
    auth.uid() = created_by
    and exists (
      select 1 from public.users
      where id = auth.uid() and role in ('user', 'admin')
    )
  );

-- ============================================================
-- 5. TRIGGER: Prevent helpdesk from changing assigned_to
-- ============================================================

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

drop trigger if exists trg_check_assign_permission on tickets;
create trigger trg_check_assign_permission
  before update on tickets
  for each row
  execute function check_assign_permission();

-- ============================================================
-- 6. UPDATE notification INSERT policy (allow trigger to insert)
-- ============================================================

drop policy if exists notifications_insert on public.notifications;
create policy notifications_insert on public.notifications
  for insert
  to authenticated
  with check (true);

-- ============================================================
-- ADDITIONAL: Applied via dashboard / execute_sql
-- ============================================================

-- tickets_update_own policy (for attachment URL updates)
create policy if not exists "tickets_update_own" on public.tickets
  for update
  to authenticated
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);

-- Compound index for user's filtered queries
create index if not exists tickets_created_by_status_idx on tickets(created_by, status);
create index if not exists users_role_idx on users(role);

-- Storage bucket
insert into storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
values (
  'ticket_attachments', 'ticket_attachments', true, false, 10485760,
  array['image/jpeg','image/png','image/gif','image/webp','application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document']
)
on conflict (id) do nothing;

-- Storage RLS policies
create policy if not exists "select_ticket_attachments"
  on storage.objects for select to authenticated
  using ( bucket_id = 'ticket_attachments' );

create policy if not exists "insert_ticket_attachments"
  on storage.objects for insert to authenticated
  with check ( bucket_id = 'ticket_attachments' and owner = auth.uid() );

create policy if not exists "delete_own_ticket_attachments"
  on storage.objects for delete to authenticated
  using ( bucket_id = 'ticket_attachments' and owner = auth.uid() );
