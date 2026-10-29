-- Run this in Supabase: SQL Editor -> New query -> Run
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  name text default 'Me',
  status text default 'Available',
  emoji text default '🙂',
  last_seen timestamptz default now(),
  theme jsonb default '{"accent":"#e0457b","bg":"#f2effa","font":"ui-rounded, system-ui, sans-serif","presets":["💼 Working","😴 Sleeping","🍽️ Eating","🚗 Commuting","🎮 Playing"]}'
);
create table notes (
  id bigint generated always as identity primary key,
  from_id uuid references profiles(id) default auth.uid(),
  text text not null,
  created_at timestamptz default now()
);
alter table profiles enable row level security;
alter table notes enable row level security;
create policy "read profiles" on profiles for select to authenticated using (true);
create policy "update own profile" on profiles for update to authenticated using (id = auth.uid());
create policy "read notes" on notes for select to authenticated using (true);
create policy "send notes" on notes for insert to authenticated with check (from_id = auth.uid());
create function handle_new_user() returns trigger language plpgsql security definer as $$
begin insert into profiles(id) values (new.id); return new; end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();
alter publication supabase_realtime add table profiles, notes;
