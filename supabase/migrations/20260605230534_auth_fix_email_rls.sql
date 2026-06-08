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
