-- Migración 017 — Tabla de insights/recomendaciones generadas por IA
create table public.ai_insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  contexto jsonb not null default '{}'::jsonb,
  recomendaciones jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index ai_insights_user_idx on public.ai_insights (user_id, created_at desc);

alter table public.ai_insights enable row level security;

create policy ai_insights_select on public.ai_insights
  for select to authenticated using (user_id = auth.uid());

create policy ai_insights_insert on public.ai_insights
  for insert to authenticated with check (user_id = auth.uid());

create policy ai_insights_update on public.ai_insights
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy ai_insights_delete on public.ai_insights
  for delete to authenticated using (user_id = auth.uid());

notify pgrst, 'reload schema';
