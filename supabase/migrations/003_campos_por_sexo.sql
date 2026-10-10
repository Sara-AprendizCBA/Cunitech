-- Migración 003 — Campos por sexo + identificación física
-- Basado en formato SENA GFPI-F-004
-- ADITIVA. No modifica datos existentes.

-- 1. Identificación física del conejo
alter table public.conejo
  add column if not exists chapeta text;
alter table public.conejo
  add column if not exists placa_inventario text;
alter table public.conejo
  add column if not exists color text;

-- 2. Estado reproductivo (hembras)
alter table public.conejo
  add column if not exists reproductive_status text not null default 'Vacía';
alter table public.conejo
  add column if not exists expected_birth_date date;

-- 3. Estado reproductivo (machos)
alter table public.conejo
  add column if not exists is_active_breeder boolean not null default true;
alter table public.conejo
  add column if not exists last_weight_kg numeric(5,2);

-- 4. Índice para filtrar por estado reproductivo
create index if not exists conejo_reproductive_status_idx
  on public.conejo (reproductive_status);

notify pgrst, 'reload schema';