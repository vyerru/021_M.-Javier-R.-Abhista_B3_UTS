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
