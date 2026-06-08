-- Add missing INSERT policy on tickets
drop policy if exists tickets_insert on public.tickets;
create policy tickets_insert on public.tickets
  for insert
  to authenticated
  with check (auth.uid() = created_by);
