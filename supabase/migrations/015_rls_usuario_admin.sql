-- Migración 015 — RLS de usuario con soporte admin
-- Permite:
--   * Admin leer TODOS los usuarios
--   * Admin actualizar CUALQUIER usuario (cambiar rol, activo)
--   * Usuario editar su propio perfil (nombre)
--   * Usuario insertar su propia fila al registrarse
--   * Solo admin eliminar usuarios
-- Necesario para la pantalla "Gestión de Usuarios".

create or replace function public.get_user_rol()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select rol from public.usuario where id_usuario = auth.uid()
$$;

drop policy if exists "Usuarios pueden ver su propio registro" on public.usuario;
drop policy if exists "Usuarios pueden actualizar su propio registro" on public.usuario;
drop policy if exists "Usuarios pueden crear su propio registro" on public.usuario;

create policy usuarios_select on public.usuario
  for select to authenticated using (true);

create policy usuarios_update on public.usuario
  for update to authenticated
  using (auth.uid() = id_usuario or public.get_user_rol() = 'admin')
  with check (auth.uid() = id_usuario or public.get_user_rol() = 'admin');

create policy usuarios_insert on public.usuario
  for insert to authenticated
  with check (auth.uid() = id_usuario);

create policy usuarios_delete on public.usuario
  for delete to authenticated
  using (public.get_user_rol() = 'admin');

notify pgrst, 'reload schema';
