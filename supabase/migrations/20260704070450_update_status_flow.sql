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
