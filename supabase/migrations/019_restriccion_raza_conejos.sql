-- Migración 019 — Restringir la raza a conejos válidos
-- Evita que se registren otros animales (perros, gatos, etc.) como conejos.
-- Normaliza los valores existentes fuera de la lista a 'Otra' para poder
-- aplicar la restricción sin perder registros.

-- Normaliza variantes conocidas antes del fallback.
update public.conejo
set raza = 'Cabeza de León'
where lower(btrim(raza)) in ('cabeza de leon', 'cabeza de león');

update public.conejo
set raza = 'Rex'
where lower(btrim(raza)) in ('rex', 'rexx');

update public.conejo
set raza = 'Otra'
where raza is null
   or btrim(raza) = ''
   or raza not in (
     'Nueva Zelanda',
     'California',
     'Rex',
     'Mariposa',
     'Cabeza de León',
     'Angora',
     'Gigante de Flandes',
     'Chinchilla',
     'Otra'
   );

alter table public.conejo
  drop constraint if exists conejo_raza_valida;

alter table public.conejo
  add constraint conejo_raza_valida
  check (
    raza is not null
    and raza in (
      'Nueva Zelanda',
      'California',
      'Rex',
      'Mariposa',
      'Cabeza de León',
      'Angora',
      'Gigante de Flandes',
      'Chinchilla',
      'Otra'
    )
  );

notify pgrst, 'reload schema';
