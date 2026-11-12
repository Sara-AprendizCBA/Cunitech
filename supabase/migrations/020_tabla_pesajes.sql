-- Migración 020 — Historial de pesajes por conejo
-- Guarda la evolución del peso de cada conejo para poder graficarla.
-- Cada pesaje es el peso (kg) que tenía el animal en una fecha.

create table public.pesajes (
  id uuid primary key default gen_random_uuid(),
  conejo_id integer not null references public.conejo(id_conejo) on delete cascade,
  fecha date not null default current_date,
  peso_kg numeric(6,3) not null check (peso_kg > 0),
  notas text,
  user_id uuid not null default auth.uid(),
  created_at timestamptz default now()
);

create index pesajes_conejo_idx on public.pesajes (conejo_id);
create index pesajes_conejo_fecha_idx on public.pesajes (conejo_id, fecha);

alter table public.pesajes enable row level security;

-- Igual que el resto del criadero: todos los usuarios autenticados comparten
-- los datos (ver migración 018).
create policy authenticated_all on public.pesajes
  for all to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

notify pgrst, 'reload schema';
