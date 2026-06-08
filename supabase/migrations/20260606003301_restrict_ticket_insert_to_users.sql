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
