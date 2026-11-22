-- Fysica Escape: nieuwe tabellen, geen wijzigingen aan bestaande chemiegegevens.
-- Voer uit in hetzelfde Supabase-project als Chemie Escape.
begin;
create table if not exists public.physics_puzzles (
 level_id text not null check(level_id in ('classical','industrial','modern','space')),
 object_id text not null check(object_id in ('object1','object2','object3','object4','object5','object6')),
 title text not null, active boolean not null default true,
 questions_required integer not null default 3 check(questions_required in (3,5,10)),
 primary key(level_id,object_id)
);
insert into public.physics_puzzles(level_id,object_id,title,active) values
('classical','object1','Krachten',true),
('classical','object2','Beweging',true),
('classical','object3','Zwaartekracht',true),
('classical','object4','Optica',false),
('classical','object5','Golven',false),
('classical','object6','Meetkunde en metingen',false),
('industrial','object1','Elektrische stroom',true),
('industrial','object2','Spanning en weerstand',true),
('industrial','object3','Magnetisme',true),
('industrial','object4','Energie',false),
('industrial','object5','Warmte en arbeid',false),
('industrial','object6','Inductie',false),
('modern','object1','Golven',true),
('modern','object2','Atoommodellen',true),
('modern','object3','Straling',true),
('modern','object4','Relativiteit',false),
('modern','object5','Optica',false),
('modern','object6','Kwantumfysica',false),
('space','object1','Raketten',true),
('space','object2','Satellieten',true),
('space','object3','Baanbeweging',true),
('space','object4','Ruimteonderzoek',false),
('space','object5','Zwaartekracht',false),
('space','object6','Kosmologie',false)
on conflict do nothing;
create table if not exists public.physics_questions (
 id uuid primary key default gen_random_uuid(),level_id text not null,object_id text not null,
 question_text text not null,question_type text not null check(question_type in ('multiple_choice','numeric','short_answer')),
 difficulty text not null default 'basis' check(difficulty in ('basis','gemiddeld','moeilijk')),
 options jsonb not null default '[]'::jsonb,correct_answer text not null,
 active boolean not null default true,
 foreign key(level_id,object_id) references public.physics_puzzles(level_id,object_id)
);
create table if not exists public.physics_attempts (
 id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,
 level_id text not null,object_id text not null,difficulty text not null,
 question_ids uuid[] not null,answered jsonb not null default '[]'::jsonb,
 completed_at timestamptz,perfect boolean not null default false,created_at timestamptz not null default now(),
 foreign key(level_id,object_id) references public.physics_puzzles(level_id,object_id)
);
create table if not exists public.physics_progress (
 user_id uuid not null references auth.users(id) on delete cascade,
 level_id text not null,object_id text not null,completions integer not null default 0,
 first_completed_at timestamptz not null default now(),primary key(user_id,level_id,object_id)
);
create index if not exists physics_attempts_user_idx on public.physics_attempts(user_id,level_id,object_id);
create or replace function public.physics_is_teacher() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='teacher');
$$;
-- RLS: geen rechtstreekse toegang tot correcte antwoorden.
alter table public.physics_puzzles enable row level security;
alter table public.physics_questions enable row level security;
alter table public.physics_attempts enable row level security;
alter table public.physics_progress enable row level security;
revoke all on public.physics_questions from anon,authenticated;
revoke all on public.physics_attempts from anon,authenticated;
revoke all on public.physics_progress from anon,authenticated;
grant select on public.physics_puzzles to authenticated;
drop policy if exists physics_puzzles_read on public.physics_puzzles;
create policy physics_puzzles_read on public.physics_puzzles for select to authenticated using(true);
create or replace function public.physics_get_progress(p_level text) returns jsonb language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'Meld je aan.';end if;
 return (select coalesce(jsonb_agg(jsonb_build_object('object_id',p.object_id,'title',p.title,'active',p.active,'required',p.questions_required,'completions',coalesce(pr.completions,0),'total_questions',(select count(*) from public.physics_questions q where q.level_id=p.level_id and q.object_id=p.object_id and q.active)) order by p.object_id),'[]'::jsonb)
 from public.physics_puzzles p left join public.physics_progress pr on pr.user_id=auth.uid() and pr.level_id=p.level_id and pr.object_id=p.object_id where p.level_id=p_level);
end;$$;
create or replace function public.physics_start(p_level text,p_object text,p_difficulty text) returns jsonb language plpgsql security definer set search_path=public as $$
declare a public.physics_attempts%rowtype; req integer; ids uuid[]; items jsonb;
begin
 if auth.uid() is null then raise exception 'Meld je aan.';end if;
 if p_difficulty not in ('basis','gemiddeld','moeilijk') then raise exception 'Ongeldige moeilijkheid.';end if;
 select questions_required into req from public.physics_puzzles where level_id=p_level and object_id=p_object and active;
 if not found then raise exception 'Puzzel is niet actief.';end if;
 select * into a from public.physics_attempts where user_id=auth.uid() and level_id=p_level and object_id=p_object and completed_at is null order by created_at desc limit 1;
 if not found then
  select array_agg(id) into ids from (select id from public.physics_questions where level_id=p_level and object_id=p_object and difficulty=p_difficulty and active order by random() limit req) x;
  if coalesce(cardinality(ids),0)<req then raise exception 'Niet genoeg actieve vragen voor deze moeilijkheid: minstens % nodig.',req;end if;
  insert into public.physics_attempts(user_id,level_id,object_id,difficulty,question_ids) values(auth.uid(),p_level,p_object,p_difficulty,ids) returning * into a;
 end if;
 select jsonb_agg(jsonb_build_object('id',q.id,'text',q.question_text,'type',q.question_type,'options',q.options) order by x.ord) into items
 from unnest(a.question_ids) with ordinality x(id,ord) join public.physics_questions q on q.id=x.id;
 return jsonb_build_object('attempt_id',a.id,'questions',coalesce(items,'[]'::jsonb),'answered',a.answered,'difficulty',a.difficulty);
end;$$;
create or replace function public.physics_answer(p_attempt uuid,p_question uuid,p_answer text) returns jsonb language plpgsql security definer set search_path=public as $$
declare a public.physics_attempts%rowtype;q public.physics_questions%rowtype; idx integer; ok boolean; done boolean; perfect boolean; responses jsonb;
begin
 select * into a from public.physics_attempts where id=p_attempt and user_id=auth.uid() for update;
 if not found or a.completed_at is not null then raise exception 'Poging niet beschikbaar.';end if;
 idx:=jsonb_array_length(a.answered)+1;
 if idx>cardinality(a.question_ids) or a.question_ids[idx]<>p_question then raise exception 'Vraag is niet aan de beurt of al beantwoord.';end if;
 select * into q from public.physics_questions where id=p_question and level_id=a.level_id and object_id=a.object_id;
 if not found then raise exception 'Vraag niet gevonden.';end if;
 if q.question_type='numeric' then
   ok:=trim(coalesce(p_answer,'')) ~ '^-?[0-9]+([.,][0-9]+)?$' and replace(trim(p_answer),',','.')::numeric=replace(q.correct_answer,',','.')::numeric;
 else
   ok:=lower(regexp_replace(trim(coalesce(p_answer,'')),'\s+',' ','g'))=lower(regexp_replace(trim(q.correct_answer),'\s+',' ','g'));
 end if;
 responses:=a.answered||jsonb_build_array(jsonb_build_object('id',p_question,'correct',ok));
 done:=jsonb_array_length(responses)=cardinality(a.question_ids);
 perfect:=done and not exists(select 1 from jsonb_array_elements(responses) x where (x->>'correct')::boolean=false);
 update public.physics_attempts set answered=responses,completed_at=case when done then now() else null end,perfect=perfect where id=a.id;
 if perfect then
 insert into public.physics_progress(user_id,level_id,object_id,completions) values(auth.uid(),a.level_id,a.object_id,1)
 on conflict(user_id,level_id,object_id) do update set completions=public.physics_progress.completions+1;
 end if;
 return jsonb_build_object('correct',ok,'completed',done,'perfect',perfect,'answered_count',jsonb_array_length(responses),'required_count',cardinality(a.question_ids),'correct_answer',case when done then q.correct_answer else null end);
end;$$;
create or replace function public.physics_teacher_questions(p_level text,p_object text) returns jsonb language plpgsql security definer set search_path=public as $$
begin
 if not public.physics_is_teacher() then raise exception 'Alleen leerkrachten.';end if;
 return (select coalesce(jsonb_agg(to_jsonb(q) order by q.difficulty,q.question_text),'[]'::jsonb) from public.physics_questions q where q.level_id=p_level and q.object_id=p_object);
end;$$;
create or replace function public.physics_teacher_save_question(p_id uuid,p_level text,p_object text,p_text text,p_type text,p_difficulty text,p_options jsonb,p_answer text,p_active boolean) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
 if not public.physics_is_teacher() then raise exception 'Alleen leerkrachten.';end if;
 if length(trim(coalesce(p_text,'')))<5 or length(p_text)>1000 then raise exception 'Vraaglengte: 5 tot 1000 tekens.';end if;
 if p_type not in ('multiple_choice','numeric','short_answer') or p_difficulty not in ('basis','gemiddeld','moeilijk') then raise exception 'Ongeldig type of moeilijkheid.';end if;
 if p_type='multiple_choice' and (jsonb_typeof(p_options) is distinct from 'array' or jsonb_array_length(p_options)<>4 or p_answer not in ('1','2','3','4')) then raise exception 'Vier antwoordopties en correct antwoord 1 t/m 4 vereist.';end if;
 if p_id is null then
  insert into public.physics_questions(level_id,object_id,question_text,question_type,difficulty,options,correct_answer,active)
  values(p_level,p_object,trim(p_text),p_type,p_difficulty,coalesce(p_options,'[]'::jsonb),trim(p_answer),p_active) returning id into v_id;
 else
  if exists(select 1 from public.physics_attempts where completed_at is null and p_id=any(question_ids)) then raise exception 'Vraag zit in een lopende poging.';end if;
  update public.physics_questions set question_text=trim(p_text),question_type=p_type,difficulty=p_difficulty,options=coalesce(p_options,'[]'::jsonb),correct_answer=trim(p_answer),active=p_active where id=p_id and level_id=p_level and object_id=p_object returning id into v_id;
  if v_id is null then raise exception 'Vraag niet gevonden in deze puzzel.';end if;
 end if;
 return v_id;
end;$$;
create or replace function public.physics_teacher_settings(p_level text,p_object text,p_title text,p_active boolean,p_required integer) returns void language plpgsql security definer set search_path=public as $$
begin
 if not public.physics_is_teacher() then raise exception 'Alleen leerkrachten.';end if;
 if length(trim(p_title))<2 or p_required not in (3,5,10) then raise exception 'Ongeldige instellingen.';end if;
 update public.physics_puzzles set title=trim(p_title),active=p_active,questions_required=p_required where level_id=p_level and object_id=p_object;
 if not found then raise exception 'Onbekende puzzel.';end if;
end;$$;
grant execute on function public.physics_is_teacher() to authenticated;
grant execute on function public.physics_get_progress(text),public.physics_start(text,text,text),public.physics_answer(uuid,uuid,text),public.physics_teacher_questions(text,text),public.physics_teacher_save_question(uuid,text,text,text,text,text,jsonb,text,boolean),public.physics_teacher_settings(text,text,text,boolean,integer) to authenticated;
commit;
