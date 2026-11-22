-- Voer dit uit wanneer 01_fysica_basis.sql eerder al uitgevoerd is.
-- De vier bestaande puzzelplekken blijven bestaan; alleen plekken 4-6 worden standaard verborgen.
begin;
do $$ declare c record; begin for c in select conname from pg_constraint where conrelid='public.physics_puzzles'::regclass and contype='c' and pg_get_constraintdef(oid) like '%object_id%' loop execute format('alter table public.physics_puzzles drop constraint %I',c.conname); end loop; end $$;
alter table public.physics_puzzles add constraint physics_puzzles_object_id_six_check check (object_id in ('object1','object2','object3','object4','object5','object6'));
insert into public.physics_puzzles(level_id,object_id,title,active) values
('classical','object5','Golven',false),
('classical','object6','Meetkunde en metingen',false),
('industrial','object5','Warmte en arbeid',false),
('industrial','object6','Inductie',false),
('modern','object5','Optica',false),
('modern','object6','Kwantumfysica',false),
('space','object5','Zwaartekracht',false),
('space','object6','Kosmologie',false)
on conflict (level_id,object_id) do nothing;
update public.physics_puzzles set active=false where object_id='object4';
commit;
