-- Migración 002 — Identificación básica del conejo + flexibilización
-- Basado en formato SENA GFPI-F-004 (Registro Hembras y Machos)
-- ADITIVA. No modifica datos existentes.

-- 1. Permitir partos sin madre registrada (huérfanos, compras sin papeles)
alter table public.births alter column mother_id drop not null;
alter table public.kits   alter column mother_id drop not null;

-- 2. Gazapos adoptados entre camadas
alter table public.births
  add column if not exists adopted_kits integer not null default 0;

-- 3. Identificación del conejo (encabezado del formato SENA)
alter table public.conejo
  add column if not exists father_id integer references public.conejo(id_conejo) on delete set null;
alter table public.conejo
  add column if not exists mother_id integer references public.conejo(id_conejo) on delete set null;
alter table public.conejo
  add column if not exists entry_date date;
alter table public.conejo
  add column if not exists origin text;
alter table public.conejo
  add column if not exists registry_number text;
alter table public.conejo
  add column if not exists cage_number text;

-- 4. Índices para las nuevas FKs
create index if not exists conejo_father_id_idx on public.conejo (father_id);
create index if not exists conejo_mother_id_idx on public.conejo (mother_id);

notify pgrst, 'reload schema';