
-- UNIVERSITY OF PENNSYLVANIA RPG
-- Campos adicionais do perfil de jogador.

alter table public.profiles
  add column if not exists player_age integer,
  add column if not exists availability text,
  add column if not exists sample_scene text;

-- Campos adicionais da ficha do personagem.

alter table public.characters
  add column if not exists character_age integer,
  add column if not exists society text,
  add column if not exists sport_extracurricular text,
  add column if not exists academic_extracurricular text,
  add column if not exists payment_status text,
  add column if not exists personality text,
  add column if not exists history text,
  add column if not exists risk_acknowledged boolean not null default false;

-- Área independente para segredos, traumas e fobias.

create table if not exists public.character_secrets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  character_name text not null,
  secret_text text not null,
  trauma_phobia text not null,
  created_at timestamptz not null default now()
);

-- Ativa segurança por linha.

alter table public.profiles enable row level security;
alter table public.characters enable row level security;
alter table public.character_secrets enable row level security;

-- Cada jogador só pode consultar o próprio perfil.

drop policy if exists "players read own profile" on public.profiles;
create policy "players read own profile"
on public.profiles for select to authenticated
using (id = auth.uid());

drop policy if exists "players insert own profile" on public.profiles;
create policy "players insert own profile"
on public.profiles for insert to authenticated
with check (id = auth.uid());

drop policy if exists "players update own profile" on public.profiles;
create policy "players update own profile"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Cada jogador só pode criar e consultar as próprias fichas.

drop policy if exists "players read own characters" on public.characters;
create policy "players read own characters"
on public.characters for select to authenticated
using (user_id = auth.uid());

drop policy if exists "players insert own characters" on public.characters;
create policy "players insert own characters"
on public.characters for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "players update own pending characters" on public.characters;
create policy "players update own pending characters"
on public.characters for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Segredos: cada jogador só acessa os próprios registros.

drop policy if exists "players read own secrets" on public.character_secrets;
create policy "players read own secrets"
on public.character_secrets for select to authenticated
using (user_id = auth.uid());

drop policy if exists "players insert own secrets" on public.character_secrets;
create policy "players insert own secrets"
on public.character_secrets for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "players update own secrets" on public.character_secrets;
create policy "players update own secrets"
on public.character_secrets for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Bucket de fotos dos personagens.
-- Este exemplo cria um bucket público para permitir URLs públicas.
-- Só faça isso se estiver de acordo com a exposição das imagens.

insert into storage.buckets (id, name, public)
values ('character-photos', 'character-photos', true)
on conflict (id) do nothing;

drop policy if exists "players upload own character photos" on storage.objects;
create policy "players upload own character photos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'character-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "players view own character photos" on storage.objects;
create policy "players view own character photos"
on storage.objects for select to authenticated
using (
  bucket_id = 'character-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);
