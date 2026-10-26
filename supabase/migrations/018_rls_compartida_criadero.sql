-- Migración 018 — RLS compartida de un solo criadero
-- Todos los usuarios autenticados comparten los datos del criadero.
-- El rol solo define pantallas/permisos en la app, no visibilidad de filas.
-- Idempotente: segura de re-ejecutar.

begin;

drop policy if exists owners_only on public.conejo;
drop policy if exists owners_only on public.alimentacion;
drop policy if exists owners_only on public.reproduccion;
drop policy if exists owners_only on public.births;
drop policy if exists owners_only on public.kits;
drop policy if exists owners_only on public.metas_mensuales;

drop policy if exists authenticated_all on public.conejo;
drop policy if exists authenticated_all on public.alimentacion;
drop policy if exists authenticated_all on public.reproduccion;
drop policy if exists authenticated_all on public.births;
drop policy if exists authenticated_all on public.kits;
drop policy if exists authenticated_all on public.metas_mensuales;

create policy authenticated_all on public.conejo
  for all to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy authenticated_all on public.alimentacion
  for all to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy authenticated_all on public.reproduccion
  for all to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy authenticated_all on public.births
  for all to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy authenticated_all on public.kits
  for all to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy authenticated_all on public.metas_mensuales
  for all to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

notify pgrst, 'reload schema';

commit;
