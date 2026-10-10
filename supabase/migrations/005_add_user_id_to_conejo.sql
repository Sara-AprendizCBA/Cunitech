-- Migración 005 — user_id automático en conejo
-- ADITIVA. No modifica datos existentes.

-- 1. Añadir columna user_id (sin FK para evitar conflictos)
alter table public.conejo
  add column if not exists user_id uuid;

-- 2. Índice para filtros rápidos
create index if not exists conejo_user_id_idx
  on public.conejo (user_id);

-- 3. Función que auto-asigna user_id en insert
create or replace function public.set_user_id_on_insert()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.user_id is null then
    new.user_id := auth.uid();
  end if;
  return new;
end;
$$;

-- 4. Trigger en conejo
drop trigger if exists conejo_set_user_id on public.conejo;
create trigger conejo_set_user_id
  before insert on public.conejo
  for each row
  execute function public.set_user_id_on_insert();

-- 5. Poblar las filas existentes con el user_id del admin
-- (usando subconsulta para no hardcodear UUID)
update public.conejo
  set user_id = (
    select id from auth.users
    where email = 'admin@gmail.com'
    limit 1
  )
  where user_id is null;

notify pgrst, 'reload schema';