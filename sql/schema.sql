-- ============================================================
-- Pair App — schema
-- Paste this whole file into: Supabase Dashboard → SQL Editor → New query → Run
-- ============================================================

-- PROFILES
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_url text,
  timezone text not null default 'UTC',
  last_seen_at timestamptz default now(),
  is_online boolean default false,
  location_sharing_enabled boolean default false,
  pet_name text,                    -- nickname set BY your partner, FOR you
  role text not null default 'user' check (role in ('user', 'premium', 'admin')),
  created_at timestamptz default now()
);

-- PAIRINGS
-- `code_expires_at` bounds how long a generated code is guessable —
-- without this, a 6-digit code (1 in a million) has an unlimited time
-- window to brute-force. 15 minutes is generous for "read it to your
-- partner over a call" while closing that window for anyone else.
create table public.pairings (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid references public.profiles(id) on delete cascade,
  user_b_id uuid references public.profiles(id) on delete cascade,
  pairing_code text unique,
  code_expires_at timestamptz,
  status text not null default 'pending',
  created_at timestamptz default now(),
  bound_at timestamptz
);
create index on public.pairings (pairing_code) where pairing_code is not null;

-- SCHEDULE BLOCKS
-- `for_date` is the calendar date this block applies to, interpreted in
-- the owner's OWN local calendar/timezone (profiles.timezone). This lets
-- either partner plan ahead ("set tomorrow's schedule today").
create table public.schedule_blocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  for_date date not null,
  start_time time not null,
  end_time time not null,
  block_type text not null check (block_type in ('sleep','work','free','custom')),
  label text,
  remind_me boolean not null default false,
  created_at timestamptz default now()
);
create index on public.schedule_blocks (user_id, for_date);

-- STATUS UPDATES
create table public.status_updates (
  id uuid primary key default gen_random_uuid(),
  pairing_id uuid references public.pairings(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  status_text text,
  emoji text,
  created_at timestamptz default now()
);

-- MESSAGES (chat + sticky notes + doodle metadata)
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  pairing_id uuid references public.pairings(id) on delete cascade,
  sender_id uuid references public.profiles(id) on delete cascade,
  kind text not null default 'chat',
  content text,
  metadata jsonb default '{}',
  created_at timestamptz default now()
);
create index on public.messages (pairing_id, created_at desc);

-- NOTE: There is deliberately NO game_sessions table. Games are played
-- LIVE ONLY — state is exchanged directly between the two partners over
-- an ephemeral Realtime Broadcast channel (see lib/services/pair_channel.dart)
-- and never touches the database. Nothing is saved, nothing to clean up.

-- LOCATION PINGS (travel/route history — only written while a user has
-- location sharing switched ON; see profiles.location_sharing_enabled)
create table public.location_pings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  pairing_id uuid references public.pairings(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  accuracy_m double precision,
  recorded_at timestamptz default now()
);
create index on public.location_pings (pairing_id, user_id, recorded_at desc);

-- ============================================================
-- ROW LEVEL SECURITY — a pair can only ever see its own room
-- ============================================================
alter table public.profiles enable row level security;
alter table public.pairings enable row level security;
alter table public.schedule_blocks enable row level security;
alter table public.status_updates enable row level security;
alter table public.messages enable row level security;
alter table public.location_pings enable row level security;

-- Profiles: you can always read your own profile, and you can read your
-- paired partner's profile (needed to show their name/timezone) — but
-- NOT arbitrary other users' profiles.
create policy "self and partner can read profile"
  on public.profiles for select
  using (
    auth.uid() = id
    or exists (
      select 1 from public.pairings p
      where (p.user_a_id = auth.uid() and p.user_b_id = id)
         or (p.user_b_id = auth.uid() and p.user_a_id = id)
    )
  );

create policy "users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Pairings: only the two members can see their pairing row.
create policy "members can read their pairing"
  on public.pairings for select
  using (auth.uid() = user_a_id or auth.uid() = user_b_id);

-- Schedule blocks: you can manage your own; you (and only your paired
-- partner) can read them — NOT any authenticated stranger.
create policy "users manage their own schedule"
  on public.schedule_blocks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "self and partner can read schedule blocks"
  on public.schedule_blocks for select
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.pairings p
      where (p.user_a_id = auth.uid() and p.user_b_id = schedule_blocks.user_id)
         or (p.user_b_id = auth.uid() and p.user_a_id = schedule_blocks.user_id)
    )
  );

-- Messages: only members of the pairing can read/write.
create policy "members can access their messages"
  on public.messages for all
  using (
    exists (select 1 from public.pairings p
            where p.id = pairing_id
            and (p.user_a_id = auth.uid() or p.user_b_id = auth.uid()))
  );

-- Status updates: same pattern.
create policy "members can access their status updates"
  on public.status_updates for all
  using (
    exists (select 1 from public.pairings p
            where p.id = pairing_id
            and (p.user_a_id = auth.uid() or p.user_b_id = auth.uid()))
  );

-- Location pings: only members of the pairing can read/write.
create policy "members can access their location pings"
  on public.location_pings for all
  using (
    exists (select 1 from public.pairings p
            where p.id = pairing_id
            and (p.user_a_id = auth.uid() or p.user_b_id = auth.uid()))
  );

-- ============================================================
-- FUNCTIONS
-- ============================================================

create or replace function public.create_pairing()
returns text
language plpgsql
security definer
as $$
declare
  new_code text;
begin
  loop
    new_code := lpad(floor(random() * 1000000)::text, 6, '0');
    exit when not exists (select 1 from public.pairings where pairing_code = new_code);
  end loop;

  insert into public.pairings (user_a_id, pairing_code, code_expires_at, status)
  values (auth.uid(), new_code, now() + interval '15 minutes', 'pending');

  return new_code;
end;
$$;

create or replace function public.join_pairing(code text)
returns uuid
language plpgsql
security definer
as $$
declare
  target_id uuid;
begin
  update public.pairings
  set user_b_id = auth.uid(), status = 'active', bound_at = now(), pairing_code = null
  where pairing_code = code
    and status = 'pending'
    and user_a_id != auth.uid()
    and code_expires_at > now()          -- rejects expired/guessed codes
  returning id into target_id;

  if target_id is null then
    raise exception 'Invalid or expired code';
  end if;

  return target_id;
end;
$$;

-- Lets a user set the nickname their PARTNER sees when the app greets them
-- (e.g. "Welcome back, baby") — narrow, security-definer write to a single
-- column on the partner's row, since normal RLS only allows self-updates.
create or replace function public.set_partner_nickname(nickname text)
returns void
language plpgsql
security definer
as $$
declare
  partner uuid;
begin
  select case when user_a_id = auth.uid() then user_b_id else user_a_id end
  into partner
  from public.pairings
  where (user_a_id = auth.uid() or user_b_id = auth.uid())
    and status = 'active'
  limit 1;

  if partner is null then
    raise exception 'You are not in an active pairing yet';
  end if;

  update public.profiles set pet_name = nickname where id = partner;
end;
$$;

-- ============================================================
-- REALTIME — enable replication so INSERT/UPDATE events push to clients
-- ============================================================
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.pairings;
alter publication supabase_realtime add table public.status_updates;
alter publication supabase_realtime add table public.location_pings;
