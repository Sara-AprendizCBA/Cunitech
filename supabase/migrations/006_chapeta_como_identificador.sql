-- Migración 006 — Chapeta como identificador principal
-- En cunicultura los conejos no tienen nombre, se identifican
-- por chapeta (N° físico en la oreja o jaula)

-- 1. Hacer "nombre" opcional (ya no es obligatorio)
alter table public.conejo
  alter column nombre drop not null;

-- 2. Asignar chapeta temporal a Copito (u otros sin chapeta)
--    El usuario podrá editarla después.
update public.conejo
  set chapeta = 'SIN-ID-' || id_conejo
  where chapeta is null;

-- 3. Hacer chapeta obligatoria
alter table public.conejo
  alter column chapeta set not null;

-- 4. Asegurar que no se repita dentro del mismo criadero
--    (usa user_id + chapeta como combinación única)
alter table public.conejo
  drop constraint if exists conejo_user_chapeta_unique;
alter table public.conejo
  add constraint conejo_user_chapeta_unique
  unique (user_id, chapeta);

-- 5. Índice para búsquedas por chapeta
create index if not exists conejo_chapeta_idx
  on public.conejo (chapeta);

notify pgrst, 'reload schema';