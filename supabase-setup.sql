-- ============================================================
-- wanBOTT: struktur database Supabase
-- Jalankan di Supabase > SQL Editor > New query > Run
-- ============================================================
create extension if not exists pgcrypto;

create table if not exists public.modules (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null default 'Kelas Online',
  description text,
  cover_url text,
  external_url text,
  video_url text,
  download_url text,
  content_text text,
  is_free_preview boolean not null default false,
  order_index integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  username text not null unique,
  password text not null,
  whatsapp text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.member_module_access (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  module_id uuid not null references public.modules(id) on delete cascade,
  is_granted boolean not null default true,
  granted_at timestamptz not null default now(),
  unique (member_id, module_id)
);

-- Jika tabel sudah ada sebelumnya, lengkapi kolom yang mungkin belum ada
alter table public.modules
  add column if not exists external_url text,
  add column if not exists video_url text,
  add column if not exists download_url text,
  add column if not exists cover_url text,
  add column if not exists content_text text,
  add column if not exists is_free_preview boolean not null default false,
  add column if not exists order_index integer not null default 0;

-- ------------------------------------------------------------
-- Keamanan (RLS)
-- Admin = login lewat Supabase Auth (role "authenticated")
-- Pengunjung / peserta = role "anon"
-- ------------------------------------------------------------
alter table public.modules enable row level security;
alter table public.members enable row level security;
alter table public.member_module_access enable row level security;

drop policy if exists "modules_read" on public.modules;
drop policy if exists "modules_write" on public.modules;
create policy "modules_read"  on public.modules for select using (true);
create policy "modules_write" on public.modules for all to authenticated using (true) with check (true);

drop policy if exists "members_read" on public.members;
drop policy if exists "members_register" on public.members;
drop policy if exists "members_admin_write" on public.members;
drop policy if exists "members_admin_delete" on public.members;
create policy "members_read"        on public.members for select using (true);
create policy "members_register"    on public.members for insert with check (true);
create policy "members_admin_write" on public.members for update to authenticated using (true) with check (true);
create policy "members_admin_delete" on public.members for delete to authenticated using (true);

drop policy if exists "access_read" on public.member_module_access;
drop policy if exists "access_admin_write" on public.member_module_access;
create policy "access_read"        on public.member_module_access for select using (true);
create policy "access_admin_write" on public.member_module_access for all to authenticated using (true) with check (true);

-- CATATAN: login peserta memakai username + kata sandi biasa di tabel members,
-- sehingga tabel ini dapat dibaca lewat anon key. Cocok untuk skala kecil/pribadi;
-- untuk keamanan lebih kuat, sandi sebaiknya di-hash / memakai Supabase Auth.

-- ------------------------------------------------------------
-- Diagnosa (opsional): lihat semua policy yang aktif
--   select tablename, policyname, cmd, roles from pg_policies where schemaname = 'public';
-- ------------------------------------------------------------
