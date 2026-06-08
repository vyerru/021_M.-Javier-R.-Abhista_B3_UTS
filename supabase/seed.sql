-- Seed: Demo Data
-- Run after migration: initial_schema

-- Enable pgcrypto
create extension if not exists pgcrypto with schema extensions;

do $$
declare
  _uid uuid;
begin
  -- ============================================================
  -- Admin: admin / admin123
  -- ============================================================
  _uid := gen_random_uuid();
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, confirmation_token, recovery_token,
    email_change_token_new, email_change, email_change_token_current,
    phone_change, phone_change_token, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, is_sso_user, is_anonymous
  ) values (
    '00000000-0000-0000-0000-000000000000', _uid,
    'authenticated', 'authenticated',
    'admin@e-ticketing.demo',
    extensions.crypt('admin123', extensions.gen_salt('bf')),
    now(), '', '',
    '', '', '',
    '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"name":"Admin User","role":"admin"}',
    now(), now(), false, false
  );
  insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  values (
    _uid, _uid,
    jsonb_build_object('sub', _uid::text, 'email', 'admin@e-ticketing.demo'),
    'email', 'admin@e-ticketing.demo',
    now(), now(), now()
  );
  insert into public.users (id, username, full_name, role, email)
  values (_uid, 'admin', 'Admin User', 'admin', 'admin@e-ticketing.demo');

  -- ============================================================
  -- Helpdesk: helpdesk / helpdesk123
  -- ============================================================
  _uid := gen_random_uuid();
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, confirmation_token, recovery_token,
    email_change_token_new, email_change, email_change_token_current,
    phone_change, phone_change_token, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, is_sso_user, is_anonymous
  ) values (
    '00000000-0000-0000-0000-000000000000', _uid,
    'authenticated', 'authenticated',
    'helpdesk@e-ticketing.demo',
    extensions.crypt('helpdesk123', extensions.gen_salt('bf')),
    now(), '', '',
    '', '', '',
    '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"name":"Helpdesk Staff","role":"helpdesk"}',
    now(), now(), false, false
  );
  insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  values (
    _uid, _uid,
    jsonb_build_object('sub', _uid::text, 'email', 'helpdesk@e-ticketing.demo'),
    'email', 'helpdesk@e-ticketing.demo',
    now(), now(), now()
  );
  insert into public.users (id, username, full_name, role, email)
  values (_uid, 'helpdesk', 'Helpdesk Staff', 'helpdesk', 'helpdesk@e-ticketing.demo');

  -- ============================================================
  -- User: user / user123456
  -- ============================================================
  _uid := gen_random_uuid();
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, confirmation_token, recovery_token,
    email_change_token_new, email_change, email_change_token_current,
    phone_change, phone_change_token, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, is_sso_user, is_anonymous
  ) values (
    '00000000-0000-0000-0000-000000000000', _uid,
    'authenticated', 'authenticated',
    'user@e-ticketing.demo',
    extensions.crypt('user123456', extensions.gen_salt('bf')),
    now(), '', '',
    '', '', '',
    '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"name":"Regular User","role":"user"}',
    now(), now(), false, false
  );
  insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  values (
    _uid, _uid,
    jsonb_build_object('sub', _uid::text, 'email', 'user@e-ticketing.demo'),
    'email', 'user@e-ticketing.demo',
    now(), now(), now()
  );
  insert into public.users (id, username, full_name, role, email)
  values (_uid, 'user', 'Regular User', 'user', 'user@e-ticketing.demo');

end $$;
