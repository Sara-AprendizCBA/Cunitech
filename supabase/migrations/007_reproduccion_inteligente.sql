-- Migración 007 — Campos para reproducción inteligente
-- ADITIVA

-- Fecha auto-calculada de palpación
alter table public.conejo
  add column if not exists palpation_date date;

-- Fecha límite (monta + 33 días)
alter table public.conejo
  add column if not exists max_birth_date date;

-- Post-parto: cuándo puede volver a servir
alter table public.conejo
  add column if not exists next_mating_date date;

notify pgrst, 'reload schema';