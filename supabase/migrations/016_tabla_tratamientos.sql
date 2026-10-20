-- Migración 016 — Tabla de tratamientos y vacunas
create table public.tratamientos (
  id uuid primary key default gen_random_uuid(),
  conejo_id integer references public.conejo(id_conejo) on delete cascade,
  jaula_grupo text,
  tipo text not null check (tipo in ('vacuna', 'tratamiento', 'desparasitacion')),
  producto text not null,
  dosis text,
  via text check (via in ('SC', 'IM', 'Oral', 'Tópica')),
  fecha_aplicacion date not null,
  fecha_proxima date,
  veterinario_id uuid references auth.users(id),
  notas text,
  user_id uuid not null default auth.uid(),
  created_at timestamptz default now(),
  constraint tratamientos_destino_check check (conejo_id is not null or jaula_grupo is not null)
);

create index tratamientos_conejo_idx on public.tratamientos (conejo_id);
create index tratamientos_fecha_prox_idx on public.tratamientos (fecha_proxima);

alter table public.tratamientos enable row level security;

create policy tratamientos_select on public.tratamientos
  for select to authenticated using (true);

create policy tratamientos_insert on public.tratamientos
  for insert to authenticated
  with check (public.get_user_rol() = 'veterinario');

create policy tratamientos_update on public.tratamientos
  for update to authenticated
  using (public.get_user_rol() = 'veterinario');

create policy tratamientos_delete on public.tratamientos
  for delete to authenticated
  using (public.get_user_rol() = 'veterinario');

notify pgrst, 'reload schema';
