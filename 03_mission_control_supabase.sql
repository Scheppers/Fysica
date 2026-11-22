-- Mission Control: execute in Supabase SQL Editor after the existing physics/chemistry schema.
-- Existing public.profiles(id uuid, coins integer) is reused; no new currency.
create table if not exists public.physics_mc_cards (
 uid bigint generated always as identity primary key,
 user_id uuid not null references auth.users(id) on delete cascade,
 card_id text not null,
 created_at timestamptz not null default now()
);
create index if not exists physics_mc_cards_user_idx on public.physics_mc_cards(user_id);
create table if not exists public.physics_mc_progress (
 user_id uuid not null references auth.users(id) on delete cascade,
 mission integer not null check (mission between 0 and 3),
 level integer not null default 0 check (level between 0 and 10),
 primary key(user_id,mission)
);
create table if not exists public.physics_mc_runs (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 mission integer not null check (mission between 0 and 3),
 level integer not null check (level between 1 and 10),
 started_at timestamptz not null default now(),
 finished_at timestamptz,
 deck jsonb not null,
 result boolean
);
create index if not exists physics_mc_runs_daily_idx on public.physics_mc_runs(user_id,started_at);
create table if not exists public.physics_mc_destroyed (
 run_id uuid not null references public.physics_mc_runs(id),
 card_uid bigint not null,
 primary key(run_id,card_uid)
);
alter table public.physics_mc_cards enable row level security;
alter table public.physics_mc_progress enable row level security;
alter table public.physics_mc_runs enable row level security;
alter table public.physics_mc_destroyed enable row level security;
-- No direct client table permissions: use security-definer RPCs below.
revoke all on public.physics_mc_cards,public.physics_mc_progress,public.physics_mc_runs,public.physics_mc_destroyed from anon,authenticated;

create or replace function public.physics_mc_catalog() returns jsonb language sql immutable as $$
 select '[
 ["newton","rare",28,3,1],["einstein","epic",48,5,0],["curie","rare",30,3,2],
 ["faraday","uncommon",20,1,4],["blackhole","legendary",65,2,2],["tunnel","epic",45,2,1],
 ["accelerator","epic",45,1,3],["converter","uncommon",20,2,2],["expansion","rare",30,1,1],
 ["simplify","common",10,2,0],["gravity","common",10,3,0],["battery","common",10,0,4],
 ["solar","common",10,0,3],["optics","uncommon",20,3,1],["fusion","rare",30,1,6],
 ["tesla","rare",30,1,5],["wave","common",10,2,1],["thermo","common",10,1,2],
 ["orbit","uncommon",20,2,3],["heisenberg","rare",30,4,0],["rocket","uncommon",20,0,5],
 ["galileo","uncommon",20,3,1],["induction","common",10,1,3],["prism","common",10,2,1]
 ]'::jsonb
$$;
revoke all on function public.physics_mc_catalog() from public;

create or replace function public.physics_mc_snapshot() returns jsonb
language plpgsql security definer set search_path = public as $$
declare u uuid:=auth.uid(); c integer; coll jsonb; prog jsonb; used_count integer;
begin
 if u is null then raise exception 'Aanmelden vereist'; end if;
 select coins into c from public.profiles where id=u;
 if c is null then raise exception 'Profiel ontbreekt'; end if;
 -- A starter collection is granted once, including when the player owns zero cards later.
 if not exists(select 1 from public.physics_mc_progress where user_id=u) then
   insert into public.physics_mc_progress(user_id,mission,level) select u,x,0 from generate_series(0,3) x on conflict do nothing;
   insert into public.physics_mc_cards(user_id,card_id)
   select u,x from unnest(array['newton','faraday','gravity','battery','solar','optics','thermo','induction','wave','galileo','simplify','orbit']) x;
 end if;
 select coalesce(jsonb_agg(jsonb_build_object('uid',uid,'id',card_id) order by uid),'[]'::jsonb) into coll from public.physics_mc_cards where user_id=u;
 select jsonb_agg(level order by mission) into prog from public.physics_mc_progress where user_id=u;
 select count(*) into used_count from public.physics_mc_runs where user_id=u and (started_at at time zone 'Europe/Brussels')::date=(now() at time zone 'Europe/Brussels')::date;
 return jsonb_build_object('coins',c,'collection',coll,'progress',prog,'used',used_count);
end $$;

create or replace function public.physics_mc_buy_box(p_box integer) returns jsonb
language plpgsql security definer set search_path=public as $$
declare u uuid:=auth.uid(); price integer; weights integer[]; i integer; roll integer; tier text; chosen text; opened text[]:=array[]::text[]; catalog jsonb:=public.physics_mc_catalog();
begin
 if u is null then raise exception 'Aanmelden vereist'; end if;
 if p_box=0 then price:=100;weights:=array[76,20,3,1];
 elsif p_box=1 then price:=250;weights:=array[45,37,15,3];
 elsif p_box=2 then price:=600;weights:=array[15,35,35,15];
 else raise exception 'Ongeldige mystery box'; end if;
 update public.profiles set coins=coins-price where id=u and coins>=price;
 if not found then raise exception 'Onvoldoende LabCoins'; end if;
 for i in 1..3 loop
   roll:=floor(random()*100)::int;
   tier:=case when roll<weights[1] then 'common' when roll<weights[1]+weights[2] then 'uncommon' when roll<weights[1]+weights[2]+weights[3] then 'rare' else 'epic' end;
   select v->>0 into chosen from jsonb_array_elements(catalog) v
   where (v->>1)=tier or (tier='epic' and (v->>1)='legendary') order by random() limit 1;
   insert into public.physics_mc_cards(user_id,card_id) values(u,chosen);
   opened:=array_append(opened,chosen);
 end loop;
 return jsonb_build_object('cards',opened);
end $$;

create or replace function public.physics_mc_start(p_mission integer,p_level integer) returns jsonb
language plpgsql security definer set search_path=public as $$
declare u uuid:=auth.uid(); used_count integer; unlocked integer; cards jsonb; runid uuid;
begin
 if u is null then raise exception 'Aanmelden vereist'; end if;
 perform pg_advisory_xact_lock(hashtext(u::text));
 if p_mission not between 0 and 3 or p_level not between 1 and 10 then raise exception 'Ongeldige missie'; end if;
 select level into unlocked from public.physics_mc_progress where user_id=u and mission=p_mission;
 if unlocked is null or p_level>unlocked+1 then raise exception 'Level nog vergrendeld'; end if;
 select count(*) into used_count from public.physics_mc_runs where user_id=u and (started_at at time zone 'Europe/Brussels')::date=(now() at time zone 'Europe/Brussels')::date;
 if used_count>=3 then raise exception 'Drie dagelijkse pogingen verbruikt'; end if;
 if not exists(select 1 from public.physics_mc_cards where user_id=u) then raise exception 'Geen kaarten in je deck'; end if;
 select jsonb_agg(jsonb_build_object('uid',uid,'id',card_id) order by random()) into cards from public.physics_mc_cards where user_id=u;
 insert into public.physics_mc_runs(user_id,mission,level,deck) values(u,p_mission,p_level,cards) returning id into runid;
 return jsonb_build_object('run_id',runid,'deck',cards);
end $$;

create or replace function public.physics_mc_destroy(p_run uuid,p_card bigint) returns jsonb
language plpgsql security definer set search_path=public as $$
declare u uuid:=auth.uid(); cardname text; reward integer;
begin
 if u is null then raise exception 'Aanmelden vereist'; end if;
 perform 1 from public.physics_mc_runs where id=p_run and user_id=u and finished_at is null for update;
 if not found then raise exception 'Geen actieve run'; end if;
 if not exists(select 1 from public.physics_mc_runs r,jsonb_array_elements(r.deck) d where r.id=p_run and (d->>'uid')::bigint=p_card) then raise exception 'Kaart zit niet in deze run'; end if;
 delete from public.physics_mc_cards where uid=p_card and user_id=u returning card_id into cardname;
 if cardname is null then raise exception 'Kaart is al vernietigd'; end if;
 select (v->>2)::integer into reward from jsonb_array_elements(public.physics_mc_catalog()) v where v->>0=cardname;
 if reward is null then raise exception 'Onbekende kaart'; end if;
 insert into public.physics_mc_destroyed(run_id,card_uid) values(p_run,p_card);
 update public.profiles set coins=coins+reward where id=u;
 return jsonb_build_object('reward',reward);
end $$;

-- IMPORTANT: This version verifies card ownership, field limits and basic mission totals.
-- It does not yet cryptographically validate every phase-1 action; see README security note.
create or replace function public.physics_mc_finish(p_run uuid,p_placed bigint[],p_knowledge integer,p_energy integer,p_lower integer,p_slots integer) returns jsonb
language plpgsql security definer set search_path=public as $$
declare u uuid:=auth.uid(); r public.physics_mc_runs%rowtype; n integer; k integer:=0; e integer:=0; domains integer; ok boolean; basek integer; basee integer; maxslots integer; domainrequired text; v jsonb; cname text; domain text; domainlist text[]:=array[]::text[]; cards jsonb:=public.physics_mc_catalog();
begin
 if u is null then raise exception 'Aanmelden vereist'; end if;
 select * into r from public.physics_mc_runs where id=p_run and user_id=u and finished_at is null for update;
 if not found then raise exception 'Run ontbreekt of is al beëindigd'; end if;
 n:=coalesce(array_length(p_placed,1),0);
 maxslots:=case when r.mission=2 then greatest(3,4-case when r.level>=8 then 1 else 0 end) else greatest(4,5-case when r.level>=8 then 1 else 0 end) end;
 if n>p_slots or n>maxslots+4 or p_slots<maxslots or p_slots>maxslots+4 then raise exception 'Ongeldige veldjes'; end if;
 if (select count(distinct x) from unnest(p_placed) x)<>n then raise exception 'Dubbele kaartplaatsing'; end if;
 if exists(select 1 from unnest(p_placed) x where not exists(select 1 from public.physics_mc_runs z,jsonb_array_elements(z.deck) d where z.id=p_run and (d->>'uid')::bigint=x)) then raise exception 'Onbekende kaart in veld'; end if;
 if exists(select 1 from unnest(p_placed) x join public.physics_mc_destroyed d on d.run_id=p_run and d.card_uid=x) then raise exception 'Vernietigde kaart in veld'; end if;
 foreach n in array p_placed loop
   select d->>'id' into cname from public.physics_mc_runs z,jsonb_array_elements(z.deck) d where z.id=p_run and (d->>'uid')::bigint=n;
   select x into v from jsonb_array_elements(cards) x where x->>0=cname;
   k:=k+(v->>3)::integer;e:=e+(v->>4)::integer;
   domain:=case when cname in ('newton','gravity','galileo') then 'Mechanica' when cname in ('battery','tesla') then 'Elektriciteit' when cname in ('solar') then 'Energie' when cname in ('faraday','induction') then 'Elektromagnetisme' when cname in ('einstein') then 'Relativiteit' when cname in ('curie','accelerator','fusion') then 'Kernfysica' when cname in ('blackhole') then 'Astrofysica' when cname in ('tunnel','heisenberg') then 'Quantumfysica' when cname in ('converter','thermo') then 'Thermodynamica' when cname in ('expansion') then 'Technologie' when cname in ('simplify') then 'Theorie' when cname in ('optics','prism') then 'Optica' when cname in ('wave') then 'Golven' else 'Ruimtevaart' end;
   if not domain=any(domainlist) then domainlist:=array_append(domainlist,domain); end if;
 end loop;
 basek:=(case r.mission when 0 then 5 when 1 then 3 when 2 then 7 else 7 end)+round((r.level-1)*(case when r.mission=0 then 1.5 else 2 end))::integer;
 basee:=(case r.mission when 0 then 2 when 1 then 7 when 2 then 4 else 6 end)+round((r.level-1)*(case when r.mission=1 then 2.5 else 1.7 end))::integer;
 -- Client-reported action bonuses are capped; full event replay remains a later hardening step.
 ok:=p_knowledge>=basek-least(greatest(p_lower,0),8) and p_energy>=basee and p_knowledge>=0 and p_energy>=0 and p_knowledge<=k+24 and p_energy<=e+40 and (r.mission<>1 or 'Elektriciteit'=any(domainlist)) and (r.mission<>3 or array_length(domainlist,1)>=least(4,2+(r.level-1)/4));
 update public.physics_mc_runs set finished_at=now(),result=ok where id=p_run;
 if ok then update public.physics_mc_progress set level=greatest(level,r.level) where user_id=u and mission=r.mission; end if;
 return jsonb_build_object('success',ok);
end $$;

revoke all on function public.physics_mc_snapshot(),public.physics_mc_buy_box(integer),public.physics_mc_start(integer,integer),public.physics_mc_destroy(uuid,bigint),public.physics_mc_finish(uuid,bigint[],integer,integer,integer,integer) from public;
grant execute on function public.physics_mc_snapshot(),public.physics_mc_buy_box(integer),public.physics_mc_start(integer,integer),public.physics_mc_destroy(uuid,bigint),public.physics_mc_finish(uuid,bigint[],integer,integer,integer,integer) to authenticated;
