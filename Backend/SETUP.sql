-- FenerVerse ücretsiz başlangıç şeması
-- Supabase Dashboard > SQL Editor içine TAMAMINI yapıştırıp bir kez çalıştır.
-- Bu şema public okuma / service-role yazma modeli kullanır. service_role anahtarını asla istemciye koyma.

create extension if not exists pgcrypto;

create table if not exists public.sports (
  slug text primary key,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sport_slug text not null references public.sports(slug) on update cascade,
  gender text,
  season text,
  source_url text,
  created_at timestamptz not null default now(),
  unique(name, sport_slug, season)
);

create table if not exists public.athletes (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  sport_slug text not null references public.sports(slug) on update cascade,
  team_id uuid references public.teams(id) on delete set null,
  biography text,
  source_url text,
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  external_id text unique,
  title text not null,
  sport_slug text not null default 'genel' references public.sports(slug) on update cascade,
  home_team text not null default 'Fenerbahçe',
  away_team text not null,
  starts_at timestamptz,
  status text not null default 'scheduled' check (status in ('scheduled','live','finished','postponed','cancelled','unknown')),
  home_score integer,
  away_score integer,
  source_name text,
  source_url text,
  updated_at timestamptz not null default now()
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text not null default '',
  sport_slug text not null default 'genel' references public.sports(slug) on update cascade,
  source_name text not null,
  canonical_url text not null unique,
  image_url text,
  published_at timestamptz,
  ingested_at timestamptz not null default now(),
  language text not null default 'tr'
);

create table if not exists public.automation_runs (
  id uuid primary key default gen_random_uuid(),
  job_name text not null,
  status text not null check (status in ('started','success','partial','failed')),
  items_seen integer not null default 0,
  items_written integer not null default 0,
  message text,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

create index if not exists articles_published_at_idx on public.articles (published_at desc nulls last);
create index if not exists articles_sport_slug_idx on public.articles (sport_slug);
create index if not exists events_starts_at_idx on public.events (starts_at);
create index if not exists events_sport_slug_idx on public.events (sport_slug);

insert into public.sports(slug, name) values
 ('futbol','Futbol'), ('kadin-futbol','Kadın Futbolu'), ('basketbol','Basketbol'),
 ('voleybol','Voleybol'), ('yuzme','Yüzme'), ('atletizm','Atletizm'),
 ('kures','Kürek'), ('yelken','Yelken'), ('boks','Boks'), ('masa-tenisi','Masa Tenisi'),
 ('tenis','Tenis'), ('eskrim','Eskrim'), ('jimnastik','Jimnastik'), ('gures','Güreş'),
 ('judo','Judo'), ('diger','Diğer Branşlar'), ('genel','Genel')
on conflict (slug) do update set name = excluded.name;

alter table public.sports enable row level security;
alter table public.teams enable row level security;
alter table public.athletes enable row level security;
alter table public.events enable row level security;
alter table public.articles enable row level security;
alter table public.automation_runs enable row level security;

drop policy if exists "public read sports" on public.sports;
create policy "public read sports" on public.sports for select to anon, authenticated using (true);
drop policy if exists "public read teams" on public.teams;
create policy "public read teams" on public.teams for select to anon, authenticated using (true);
drop policy if exists "public read athletes" on public.athletes;
create policy "public read athletes" on public.athletes for select to anon, authenticated using (true);
drop policy if exists "public read events" on public.events;
create policy "public read events" on public.events for select to anon, authenticated using (true);
drop policy if exists "public read articles" on public.articles;
create policy "public read articles" on public.articles for select to anon, authenticated using (true);
-- automation_runs bilinçli olarak public okunmaz; servis anahtarıyla yazılır.

grant select on public.sports, public.teams, public.athletes, public.events, public.articles to anon, authenticated;
-- Public/anon istemcilere INSERT/UPDATE/DELETE yetkisi verilmez.
