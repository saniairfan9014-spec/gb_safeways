-- =====================================================================
-- GB SafeRoute Database Schema - Supabase Setup
-- This script sets up the full database schema for the road safety 
-- and emergency alert system. Run this in your Supabase SQL Editor.
-- =====================================================================

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- 1. PUBLIC USERS PROFILE TABLE
-- Maps auth.users metadata into a public profiles table automatically.
create table if not exists public.users (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  full_name text not null,
  avatar_url text,
  phone_number text default '+92 355 4567890',
  contributions_count integer default 0 not null,
  badge text default 'Basecamp Guide' not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS) on users
alter table public.users enable row level security;

-- Create policies for public.users
create policy "Allow public read access to user profiles" 
  on public.users for select using (true);

create policy "Allow authenticated users to update their own profile" 
  on public.users for update using (auth.uid() = id);

-- Trigger function to automatically create a public user profile upon signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, full_name, avatar_url, phone_number, contributions_count, badge)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'avatar_url', 'https://ui-avatars.com/api/?name=' || urlencode(coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)))),
    coalesce(new.phone, '+92 355 4567890'),
    0,
    'Basecamp Guide'
  );
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to execute function on new auth signup
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 2. ROADS TABLE
-- Tracks the live status of regional highways and passes.
create table if not exists public.roads (
  id text primary key default gen_random_uuid()::text, -- e.g., 'road-kkh', 'road-skardu'
  name text not null,
  status text default 'open' not null check (status in ('Open', 'Caution', 'Blocked', 'open', 'slow', 'closed', 'blocked', 'under_construction')),
  description text not null,
  weather text default 'Clear' not null,
  safety_rating double precision default 5.0 not null check (safety_rating >= 0.0 and safety_rating <= 5.0),
  origin text,
  destination text,
  from_location text,
  to_location text,
  distance_km integer default 50 not null,
  is_verified boolean default false not null,
  created_by uuid references public.users(id) on delete set null,
  last_updated timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Trigger function to automatically sync legacy origin/destination and prompt location columns
create or replace function public.handle_road_locations()
returns trigger as $$
begin
  if new.origin is null then
    new.origin := coalesce(new.from_location, 'Various');
  end if;
  if new.destination is null then
    new.destination := coalesce(new.to_location, 'Various');
  end if;
  if new.from_location is null then
    new.from_location := new.origin;
  end if;
  if new.to_location is null then
    new.to_location := new.destination;
  end if;
  return new;
end;
$$ language plpgsql;

create or replace trigger on_road_insert_update
  before insert or update on public.roads
  for each row execute procedure public.handle_road_locations();

alter table public.roads enable row level security;

create policy "Allow public read access to roads status"
  on public.roads for select using (true);

create policy "Allow authenticated users/patrols to update road status"
  on public.roads for update using (auth.role() = 'authenticated');


-- 3. REPORTS TABLE
-- Submitted road blockages, rockfalls, or landslides.
create table if not exists public.reports (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete set null,
  user_name text not null,
  user_avatar text not null,
  road_id text references public.roads(id) on delete cascade not null,
  road_name text not null,
  hazard_type text not null,
  description text not null,
  severity text not null check (severity in ('Low', 'Medium', 'High')),
  latitude double precision not null,
  longitude double precision not null,
  upvotes integer default 0 not null,
  is_resolved boolean default false not null,
  message text,
  image text,
  location text,
  status text default 'pending' check (status in ('pending', 'verified', 'rejected')) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.reports enable row level security;

create policy "Allow public read access to hazard reports"
  on public.reports for select using (true);

create policy "Allow authenticated users to submit safety reports"
  on public.reports for insert with check (auth.uid() = user_id);

create policy "Allow authenticated users to upvote reports"
  on public.reports for update using (auth.role() = 'authenticated');


-- 4. EMERGENCY REQUESTS TABLE
-- Real-time high-priority SOS emergency signal tracking.
create table if not exists public.emergency_requests (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete set null,
  user_name text not null,
  phone_number text not null,
  latitude double precision not null,
  longitude double precision not null,
  status text default 'Pending' not null check (status in ('Pending', 'Active', 'Resolved')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.emergency_requests enable row level security;

create policy "Allow public read access to emergency beacons"
  on public.emergency_requests for select using (true);

create policy "Allow authenticated users to insert SOS signals"
  on public.emergency_requests for insert with check (auth.uid() = user_id);

create policy "Allow authenticated users or responders to update SOS signals"
  on public.emergency_requests for update using (auth.role() = 'authenticated');


-- 5. ALERTS TABLE
-- Global safety alerts and announcements published by responders.
create table if not exists public.alerts (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  message text not null,
  severity text not null check (severity in ('Info', 'Warning', 'Danger')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.alerts enable row level security;

create policy "Allow public read access to official safety alerts"
  on public.alerts for select using (true);

create policy "Allow admin/responders to manage official alerts"
  on public.alerts for all using (auth.role() = 'authenticated');


-- 6. LOCATIONS TABLE
-- Live tracking of guide and search and rescue personnel coordinates.
create table if not exists public.locations (
  id uuid references public.users(id) on delete cascade primary key,
  latitude double precision not null,
  longitude double precision not null,
  last_updated timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.locations enable row level security;

create policy "Allow public select of traveler locations"
  on public.locations for select using (true);

create policy "Allow users to update their own live location"
  on public.locations for insert with check (auth.uid() = id);

create policy "Allow users to update their own active location row"
  on public.locations for update using (auth.uid() = id);


-- =====================================================================
-- REAL-TIME SETUP
-- Enable Realtime replication for all relevant tables to feed the UI.
-- =====================================================================
begin;
  -- Remove existing publication if exists
  drop publication if exists supabase_realtime;
  
  -- Create new publication for real-time tables
  create publication supabase_realtime for table 
    public.roads, 
    public.reports, 
    public.emergency_requests, 
    public.alerts,
    public.locations,
    public.sos_alerts;
commit;

-- Insert default starter seeds for roads to match UI expectations
insert into public.roads (id, name, from_location, to_location, status, description, is_verified)
values
  ('road-gilgit-skardu', 'Gilgit-Skardu Road', 'Gilgit', 'Skardu', 'open', 'Major GB highway', true),
  ('road-gilgit-hunza', 'Gilgit-Hunza Road', 'Gilgit', 'Hunza', 'open', 'Tourist route', true),
  ('road-hunza-khunjerab', 'Hunza-Khunjerab Pass Road', 'Hunza', 'Khunjerab Pass', 'open', 'China border route', true),
  ('road-jaglot-chilas', 'Jaglot-Chilas Road', 'Jaglot', 'Chilas', 'open', 'KKH section', true),
  ('road-gilgit-astore', 'Gilgit-Astore Road', 'Gilgit', 'Astore', 'open', 'Astore valley route', true),
  ('road-skardu-shigar', 'Skardu-Shigar Road', 'Skardu', 'Shigar', 'open', 'Shigar valley access', true),
  ('road-skardu-khaplu', 'Skardu-Khaplu Road', 'Skardu', 'Khaplu', 'open', 'Ghanche district route', true),
  ('road-gilgit-nagar', 'Gilgit-Nagar Road', 'Gilgit', 'Nagar', 'open', 'Nagar valley route', true),
  ('road-gilgit-gahkuch', 'Gilgit-Gahkuch Road', 'Gilgit', 'Gahkuch', 'open', 'Ghizer district road', true),
  ('road-gahkuch-phander', 'Gahkuch-Phander Road', 'Gahkuch', 'Phander', 'open', 'Phander valley access', true),
  ('road-phander-shandur', 'Phander-Shandur Road', 'Phander', 'Shandur Pass', 'open', 'Shandur route', true),
  ('road-gilgit-danyore', 'Gilgit-Danyore Road', 'Gilgit', 'Danyore', 'open', 'City connection road', true),
  ('road-danyore-naltar', 'Danyore-Naltar Road', 'Danyore', 'Naltar Valley', 'open', 'Tourism route', true),
  ('road-gilgit-karimabad', 'Gilgit-Karimabad Road', 'Gilgit', 'Karimabad', 'open', 'Hunza tourist road', true),
  ('road-aliabad-attabad', 'Aliabad-Attabad Road', 'Aliabad', 'Attabad Lake', 'open', 'Lake access road', true),
  ('road-attabad-sost', 'Attabad-Sost Road', 'Attabad', 'Sost', 'open', 'Upper Hunza route', true),
  ('road-sost-khunjerab', 'Sost-Khunjerab Road', 'Sost', 'Khunjerab Pass', 'open', 'Border highway', true),
  ('road-skardu-deosai', 'Skardu-Deosai Road', 'Skardu', 'Deosai Plains', 'open', 'National park route', true),
  ('road-astore-deosai', 'Astore-Deosai Road', 'Astore', 'Deosai Plains', 'open', 'Deosai access', true),
  ('road-gilgit-chapursan', 'Gilgit-Chapursan Road', 'Gilgit', 'Chapursan Valley', 'open', 'Remote valley route', true),
  ('road-gilgit-yasin', 'Gilgit-Yasin Road', 'Gilgit', 'Yasin Valley', 'open', 'Ghizer valley route', true),
  ('road-yasin-ishkoman', 'Yasin-Ishkoman Road', 'Yasin', 'Ishkoman', 'open', 'Mountain valley road', true),
  ('road-gilgit-hoper', 'Gilgit-Hoper Road', 'Gilgit', 'Hoper Valley', 'open', 'Nagar tourism road', true),
  ('road-gilgit-minapin', 'Gilgit-Minapin Road', 'Gilgit', 'Minapin', 'open', 'Rakaposhi route', true),
  ('road-gilgit-rama', 'Gilgit-Rama Road', 'Gilgit', 'Rama Meadows', 'open', 'Tourism access road', true),
  ('road-chilas-babusar', 'Chilas-Babusar Road', 'Chilas', 'Babusar Top', 'open', 'Seasonal route', true),
  ('road-babusar-naran', 'Babusar-Naran Road', 'Babusar Top', 'Naran', 'open', 'KPK tourism route', true),
  ('road-skardu-sadpara', 'Skardu-Sadpara Road', 'Skardu', 'Sadpara Lake', 'open', 'Lake route', true),
  ('road-gilgit-bagrote', 'Gilgit-Bagrote Road', 'Gilgit', 'Bagrote Valley', 'open', 'Local valley road', true),
  ('road-gilgit-haramosh', 'Gilgit-Haramosh Road', 'Gilgit', 'Haramosh Valley', 'open', 'Mountain village route', true)
on conflict (id) do update set
  is_verified = excluded.is_verified,
  from_location = excluded.from_location,
  to_location = excluded.to_location,
  description = excluded.description;


-- =====================================================================
-- ATOMIC OPERATION HELPERS
-- Custom RPC Functions to avoid client-side race conditions.
-- =====================================================================

-- 1. Atomically increment report upvotes
create or replace function public.increment_report_upvotes(report_id uuid)
returns void as $$
begin
  update public.reports
  set upvotes = upvotes + 1
  where id = report_id;
end;
$$ language plpgsql security definer;

-- 2. Atomically increment user contributions and dynamically update badge ranking
create or replace function public.increment_user_contributions(user_id uuid)
returns void as $$
declare
  new_count integer;
  new_badge text;
begin
  -- Update contributions count atomically and get the new total
  update public.users
  set contributions_count = contributions_count + 1
  where id = user_id
  returning contributions_count into new_count;

  -- Determine badge tier based on new points
  if new_count >= 10 then
    new_badge := 'Himalayan Sherpa';
  elseif new_count >= 5 then
    new_badge := 'Karakoram Sentinel';
  else
    new_badge := 'Basecamp Guide';
  end if;

  -- Update user profile badge
  update public.users
  set badge = new_badge
  where id = user_id;
end;
$$ language plpgsql security definer;


-- =====================================================================
-- 7. SOS ALERTS SCHEMA
-- =====================================================================
create table if not exists public.sos_alerts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  emergency_type text not null,
  description text,
  latitude double precision not null,
  longitude double precision not null,
  status text default 'active' not null check (status in ('active', 'resolved')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  resolved_at timestamp with time zone
);

alter table public.sos_alerts enable row level security;

-- Policies for sos_alerts
create policy "Allow public read access to SOS alerts"
  on public.sos_alerts for select using (true);

create policy "Allow users to insert their own SOS alerts"
  on public.sos_alerts for insert with check (auth.uid() = user_id);

create policy "Allow users or admins to update SOS alerts"
  on public.sos_alerts for update using (auth.role() = 'authenticated');

