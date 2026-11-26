create or replace function public.add_clinic_creator_as_admin()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  creator_id uuid := (select auth.uid());
begin
  if creator_id is null then
    raise exception 'An authenticated user is required.'
      using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.clinic_members
    where user_id = creator_id
  ) then
    raise exception 'This account already has a workspace.'
      using errcode = '23505';
  end if;

  insert into public.clinic_members (user_id, clinic_id, role)
  values (creator_id, new.id, 'admin');

  return new;
end;
$$;

revoke all on function public.add_clinic_creator_as_admin()
  from public, anon, authenticated;

drop trigger if exists add_clinic_creator_as_admin on public.clinics;
create trigger add_clinic_creator_as_admin
after insert on public.clinics
for each row execute function public.add_clinic_creator_as_admin();

drop policy if exists clinics_create_personal_workspace on public.clinics;
create policy clinics_create_personal_workspace
  on public.clinics
  for insert
  to authenticated
  with check ((select auth.uid()) is not null);

grant insert on public.clinics to authenticated;
