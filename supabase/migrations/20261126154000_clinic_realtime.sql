create table if not exists public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.clinic_members (
  user_id uuid primary key references auth.users (id) on delete cascade,
  clinic_id uuid not null references public.clinics (id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  created_at timestamptz not null default now()
);

create table if not exists public.app_records (
  clinic_id uuid not null references public.clinics (id) on delete cascade,
  collection text not null check (
    collection in ('profile', 'prescriptions', 'patients', 'advice', 'medicines')
  ),
  record_id text not null check (length(record_id) > 0),
  payload jsonb,
  is_deleted boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null,
  primary key (clinic_id, collection, record_id),
  check (
    (is_deleted and payload is null)
    or (not is_deleted and jsonb_typeof(payload) = 'object')
  )
);

create index if not exists app_records_clinic_collection_idx
  on public.app_records (clinic_id, collection);

create or replace function public.is_clinic_member(target_clinic_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.clinic_members
    where clinic_id = target_clinic_id
      and user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_clinic_member(uuid) from public;
grant execute on function public.is_clinic_member(uuid) to authenticated;

create or replace function public.set_app_record_metadata()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  new.updated_by = (select auth.uid());
  return new;
end;
$$;

drop trigger if exists set_app_record_metadata on public.app_records;
create trigger set_app_record_metadata
before insert or update on public.app_records
for each row execute function public.set_app_record_metadata();

alter table public.clinic_members enable row level security;
alter table public.clinics enable row level security;
alter table public.app_records enable row level security;

drop policy if exists clinic_members_read_self on public.clinic_members;
create policy clinic_members_read_self
  on public.clinic_members
  for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists app_records_read_clinic on public.app_records;
create policy app_records_read_clinic
  on public.app_records
  for select
  to authenticated
  using (public.is_clinic_member(clinic_id));

drop policy if exists app_records_insert_clinic on public.app_records;
create policy app_records_insert_clinic
  on public.app_records
  for insert
  to authenticated
  with check (public.is_clinic_member(clinic_id));

drop policy if exists app_records_update_clinic on public.app_records;
create policy app_records_update_clinic
  on public.app_records
  for update
  to authenticated
  using (public.is_clinic_member(clinic_id))
  with check (public.is_clinic_member(clinic_id));

revoke all on public.clinics, public.clinic_members, public.app_records
  from anon, authenticated;
grant select on public.clinic_members to authenticated;
grant select, insert, update on public.app_records to authenticated;
revoke all on function public.set_app_record_metadata()
  from public, anon, authenticated;

do $$
begin
  alter publication supabase_realtime add table public.app_records;
exception
  when duplicate_object then null;
END
$$;
