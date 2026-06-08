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
