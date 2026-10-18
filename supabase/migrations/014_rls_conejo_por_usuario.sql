-- Migración 014 — RLS de conejo por usuario
-- Reemplaza las policies USING(true) por owners_only

-- 1. Eliminar las policies viejas
drop policy if exists conejo_select on public.conejo;
drop policy if exists conejo_insert on public.conejo;
drop policy if exists conejo_update on public.conejo;
drop policy if exists conejo_delete on public.conejo;

-- 2. Crear la nueva policy unificada
drop policy if exists owners_only on public.conejo;
create policy owners_only on public.conejo
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 3. Verificar que user_id esté poblado (todas las filas deben
--    tener dueño)
--    Si esta consulta devuelve filas, el ALTER fallaría:
--    select count(*) from public.conejo where user_id is null;
--
--    Si hay filas huérfanas, ejecutar el backfill comentado:
--    update public.conejo
--      set user_id = (select id from auth.users where email = 'admin@gmail.com' limit 1)
--      where user_id is null;

notify pgrst, 'reload schema';
