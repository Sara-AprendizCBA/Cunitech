-- Migración 004 — Campos del ciclo reproductivo
-- ADITIVA. No modifica datos existentes.

alter table public.conejo
  add column if not exists mating_date date;
alter table public.conejo
  add column if not exists actual_birth_date date;
alter table public.conejo
  add column if not exists actual_litter_size integer;
alter table public.conejo
  add column if not exists discard_reason text;
alter table public.conejo
  add column if not exists discard_date date;

notify pgrst, 'reload schema';