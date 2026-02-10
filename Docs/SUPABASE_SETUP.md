# Configuración de Supabase para Business & Habit Dashboard

## 1) Crear proyecto

1. Entra a https://supabase.com
2. Crea un proyecto gratuito.
3. Copia:
   - Project URL
   - anon public key

## 2) Crear tablas

```sql
create table if not exists habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  title text not null,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  category text not null,
  amount numeric(10,2) not null,
  created_at timestamptz not null default now()
);
```

## 3) Activar RLS y políticas

```sql
alter table habits enable row level security;
alter table expenses enable row level security;

create policy "Users can read own habits"
on habits for select
using (auth.uid() = user_id);

create policy "Users can insert own habits"
on habits for insert
with check (auth.uid() = user_id);

create policy "Users can update own habits"
on habits for update
using (auth.uid() = user_id);

create policy "Users can delete own habits"
on habits for delete
using (auth.uid() = user_id);

create policy "Users can read own expenses"
on expenses for select
using (auth.uid() = user_id);

create policy "Users can insert own expenses"
on expenses for insert
with check (auth.uid() = user_id);
```

## 4) Configurar app

En `SupabaseConfig.swift` agrega tus valores.

## 5) Validar endpoints

- `GET /rest/v1/habits`
- `POST /rest/v1/habits`
- `PATCH /rest/v1/habits?id=eq.<uuid>`
- `DELETE /rest/v1/habits?id=eq.<uuid>`
- `GET /rest/v1/expenses`
- `POST /rest/v1/expenses`
