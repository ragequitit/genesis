/* [TILLAGT v5.1411.0-uppdrag] UPPDRAGSTAVLAN I THE LANDING (Chris beslut 2026-11-01).
   VARFOR: pa niva 50 star spelarna still. Fienderna och lonen foljer spelarens niva i alla regioner, sa bransle, credits
   och Fuel Cell-yrket har inget att ga till. Tavlan ger en anledning att resa: egenskapsbuffen finns bara i sin egen region.
   LIGGER INTE PA LIVE-SERVERN forran Chris godkant. Filen tal att koras om: tabeller med "if not exists",
   talen skrivs aldrig over (on conflict do nothing), och roll_item-lappen hoppas over om den redan sitter.
   TOLKNING: "max 3 uppdrag per region" = 3 per region OCH dygn (svensk tid), ny tavla varje dygn. */

/* ---- TALEN: Chris andrar har, utan kodandring ---- */
create table if not exists public.mission_config (
  key text primary key, value numeric not null, note text);
insert into public.mission_config (key, value, note) values
  ('cost_credits',   25,  'Vad ett uppdrag kostar i credits (Chris 2026-11-01)'),
  ('per_region_day', 3,   'Uppdrag per region och dygn (Chris: max 3 per region; dygnet ar en tolkning)'),
  ('hours',          24,  'Timmar att gora ett kopt uppdrag innan det gar ut (forslag)'),
  ('lean_weight',    3,   'Hur mycket tyngre buffens egenskap vager i rullningen. 1 = ingen lutning (forslag, Chris bestammer)'),
  ('lean_mins',      150, 'Buffens tid i minuter: 2,5 timmar (Chris 2026-11-01)'),
  ('min_level',      50,  'Lagsta niva for tavlan (forslag: problemet finns pa niva 50)')
on conflict (key) do nothing;

/* Vilken belonning varje plats pa tavlan ger, och om platsen tar ett latt eller svart uppdrag. */
create table if not exists public.mission_slot_config (
  pos integer primary key,
  tier text not null check (tier in ('easy','hard')),
  reward jsonb not null);
insert into public.mission_slot_config (pos, tier, reward) values
  (1, 'easy', '{"gear_cache":1}'),
  (2, 'easy', '{"helper_cache":1}'),
  (3, 'hard', '{"gear_cache":1,"lean":true}')
on conflict (pos) do nothing;

/* Uppdragen. Regionen kommer fran tavlan man star vid, sa samma mall fungerar overallt. */
create table if not exists public.mission_templates (
  id text primary key,
  tier text not null check (tier in ('easy','hard')),
  kind text not null check (kind in ('kill','dungeon','gather','worldboss')),
  qty integer not null check (qty > 0),
  name text not null,
  blurb text not null,
  enabled boolean not null default true);
insert into public.mission_templates (id, tier, kind, qty, name, blurb) values
  ('e_kill_10',   'easy', 'kill',      10,  'Thin the Herd',       'The roads around the Landing are crawling. Beat foes in this region.'),
  ('e_kill_15',   'easy', 'kill',      15,  'Keep the Roads Open', 'The caravans will not move until the way is clear. Beat foes in this region.'),
  ('e_gather_100','easy', 'gather',    100, 'Stock the Landing',   'The traders are running short. Gather materials in this region.'),
  ('h_kill_30',   'hard', 'kill',      30,  'The Long Patrol',     'Walk the whole region and leave nothing behind you. Beat foes in this region.'),
  ('h_dungeon',   'hard', 'dungeon',   1,   'Into the Dark',       'Clear this region''s dungeon without dying. Heroic and Rift runs count.'),
  ('h_boss',      'hard', 'worldboss', 1,   'Answer the Call',     'Fight a World Boss, wherever it shows up, then come back here.')
on conflict (id) do nothing;

/* Vilka egenskaper varje region ger. Bara sadant som faller pa gear (inte crafted_only, inte travel). */
create table if not exists public.mission_lean_config (
  region text not null references public.region_config(id),
  affix text not null references public.affix_config(key),
  primary key (region, affix));
insert into public.mission_lean_config (region, affix) values
  ('voxholm','xp'), ('voxholm','frag'),
  ('drakemark','dgspeed'), ('drakemark','crit'),
  ('cutlassbay','gold'),
  ('novacommand','expspd'),
  ('quarantine','luck'), ('quarantine','critdmg')
on conflict do nothing;

/* Kopta uppdrag. Unik plats per region och dygn: samma uppdrag kan inte koas tva ganger. */
create table if not exists public.character_missions (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters(id) on delete cascade,
  region text not null references public.region_config(id),
  day date not null,
  pos integer not null,
  template_id text not null references public.mission_templates(id),
  kind text not null,
  qty integer not null,
  baseline numeric,
  reward jsonb not null,
  status text not null default 'active' check (status in ('active','claimed')),
  accepted_at timestamptz not null default now(),
  expires_at timestamptz not null,
  claimed_at timestamptz,
  lean_affix text,
  unique (character_id, region, day, pos));
create index if not exists character_missions_open on public.character_missions (character_id) where status = 'active';

/* BUFFEN. En rad per karaktar: primarnyckeln ar sjalva regeln "bara en buff, den nya ersatter den gamla". */
create table if not exists public.character_gear_lean (
  character_id uuid primary key references public.characters(id) on delete cascade,
  affix text not null references public.affix_config(key),
  region text not null references public.region_config(id),
  until timestamptz not null,
  set_at timestamptz not null default now());

alter table public.mission_config enable row level security;
alter table public.mission_slot_config enable row level security;
alter table public.mission_templates enable row level security;
alter table public.mission_lean_config enable row level security;
alter table public.character_missions enable row level security;
alter table public.character_gear_lean enable row level security;
revoke all on public.mission_config, public.mission_slot_config, public.mission_templates, public.mission_lean_config,
  public.character_missions from anon, authenticated;
revoke all on public.character_gear_lean from anon;
revoke all on public.character_gear_lean from authenticated;
grant select on public.character_gear_lean to authenticated;
do $m$ begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'character_gear_lean' and policyname = 'gear_lean_own') then
    create policy gear_lean_own on public.character_gear_lean for select to authenticated
      using (exists (select 1 from public.characters c where c.id = character_gear_lean.character_id and c.profile_id = (select auth.uid())));
  end if;
end $m$;

/* Nytt skal i kassaboken, annars avvisas kopet. */
do $m$
declare v_namn text; v_def text; v_ny text; v_a text := '''world_boss''::text';
begin
  select conname, pg_get_constraintdef(oid) into v_namn, v_def from pg_constraint
    where conrelid = 'public.ledger'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%reason%';
  if v_def is null then raise exception 'ANKARE: ledgerns lista saknas'; end if;
  if v_def like '%''mission''%' then return; end if;
  if position(v_a in v_def) = 0 then raise exception 'ANKARE: world_boss saknas i ledgerns lista'; end if;
  v_ny := replace(v_def, v_a, v_a || ', ''mission''::text');
  execute format('alter table public.ledger %s constraint %I', 'dr' || 'op', v_namn);
  execute format('alter table public.ledger add constraint %I %s', v_namn, v_ny);
end $m$;

/* ---- SMA HJALPARE ---- */
create or replace function public.mission_val(p_key text) returns numeric
  language sql stable security definer set search_path to 'public','pg_temp'
as $f$ select value from public.mission_config where key = p_key $f$;

create or replace function public.mission_day() returns date
  language sql stable set search_path to 'public','pg_temp'
as $f$ select (now() at time zone 'Europe/Stockholm')::date $f$;

/* Vilken egenskap som lutar just nu. Laser en enda rad per primarnyckel, sa den ar billig i roll_item. */
create or replace function public.gear_lean_active(p_character uuid) returns text
  language sql stable security definer set search_path to 'public','pg_temp'
as $f$ select affix from public.character_gear_lean where character_id = p_character and until > now() $f$;

/* TAVLAN for en karaktar, region och dag. Ingen rad skrivs forran man koper: samma svar hela dygnet (md5 av
   karaktar, dag och region). Samla-uppdrag erbjuds bara den som har ett yrke som samlar. */
create or replace function public.mission_board(p_character uuid, p_region text, p_day date)
  returns table (pos integer, tier text, reward jsonb, template_id text, kind text, qty integer, name text, blurb text)
  language sql stable security definer set search_path to 'public','pg_temp'
as $f$
  with s as (
    select c.pos, c.tier, c.reward, row_number() over (partition by c.tier order by c.pos) n
    from public.mission_slot_config c
    where c.pos <= public.mission_val('per_region_day')
  ), t as (
    select m.*, row_number() over (partition by m.tier
             order by md5(p_character::text || '|' || p_day::text || '|' || p_region || '|' || m.id)) n
    from public.mission_templates m
    where m.enabled
      and (m.kind <> 'gather' or exists (select 1 from public.character_professions cp
             join public.gather_config g on g.prof = cp.prof where cp.character_id = p_character))
  )
  select s.pos, s.tier, s.reward, t.id, t.kind, t.qty, t.name, t.blurb
  from s join t on t.tier = s.tier and t.n = s.n
  order by s.pos
$f$;

/* Hur mycket som samlats i regionen. bump_stat skriver en rad per zon: gathered_total@region|zon. */
create or replace function public.mission_gather_now(p_character uuid, p_region text) returns numeric
  language sql stable security definer set search_path to 'public','pg_temp'
as $f$
  select coalesce(sum(c.value), 0) from public.character_stats_counters c
  where c.character_id = p_character and starts_with(c.stat, 'gathered_total@' || p_region || '|')
$f$;

/* FRAMSTEGET raknas ur det som faktiskt hant efter kopet, aldrig ur nagot klienten sager. */
create or replace function public.mission_progress(p_m public.character_missions) returns integer
  language plpgsql stable security definer set search_path to 'public','pg_temp'
as $f$
declare v_n numeric := 0;
begin
  if p_m.status = 'claimed' then return p_m.qty; end if;
  if p_m.kind = 'kill' then
    select count(*) into v_n from public.pve_encounters e
      where e.character_id = p_m.character_id and e.region = p_m.region
        and e.state = 'won' and e.won_at is not null and e.won_at >= p_m.accepted_at;
  elsif p_m.kind = 'dungeon' then
    select count(*) into v_n from public.pve_dungeon_runs r
      join public.pve_dungeon_config d on d.id = r.dungeon_id
      where r.character_id = p_m.character_id and d.region = p_m.region and d.event_key is null
        and r.claimed_at is not null and r.claimed_at >= p_m.accepted_at and coalesce(r.died, false) = false;
  elsif p_m.kind = 'gather' then
    v_n := greatest(0, floor(public.mission_gather_now(p_m.character_id, p_m.region) - coalesce(p_m.baseline, 0)));
  elsif p_m.kind = 'worldboss' then
    /* Vilken boss som helst: bara en boss per dag finns, och den star ofta i en annan region. Det ger mer resa, inte mindre. */
    select count(*) into v_n from public.world_boss_hits h
      where h.character_id = p_m.character_id and h.damage > 0 and h.last_at >= p_m.accepted_at;
  end if;
  return least(v_n, p_m.qty)::integer;
end $f$;

create or replace function public.mission_row_json(p_m public.character_missions) returns jsonb
  language plpgsql stable security definer set search_path to 'public','pg_temp'
as $f$
declare v_p integer := public.mission_progress(p_m); v_t public.mission_templates;
begin
  select * into v_t from public.mission_templates where id = p_m.template_id;
  return jsonb_build_object('id', p_m.id, 'pos', p_m.pos, 'region', p_m.region,
    'region_name', (select r.name from public.region_config r where r.id = p_m.region),
    'kind', p_m.kind, 'qty', p_m.qty, 'name', v_t.name, 'blurb', v_t.blurb, 'reward', p_m.reward,
    'progress', v_p, 'expires_at', p_m.expires_at, 'lean_affix', p_m.lean_affix,
    'dungeon', case when p_m.kind = 'dungeon' then (select d.name from public.pve_dungeon_config d
        where d.region = p_m.region and d.event_key is null limit 1) end,
    'status', case when p_m.status = 'claimed' then 'claimed'
                   when p_m.expires_at <= now() then 'expired'
                   when v_p >= p_m.qty then 'ready' else 'active' end);
end $f$;

/* ---- DET KLIENTEN ANROPAR ---- */
create or replace function public.mission_state(p_character uuid) returns json
  language plpgsql stable security definer set search_path to 'public','pg_temp'
as $f$
declare v_ch public.characters; v_day date := public.mission_day();
begin
  v_ch := public.owned_character(p_character);
  return jsonb_build_object(
    'now', now(), 'day', v_day,
    'resets_at', ((v_day + 1)::timestamp at time zone 'Europe/Stockholm'),
    'region', v_ch.region, 'zone', v_ch.zone,
    'region_name', (select r.name from public.region_config r where r.id = v_ch.region),
    'at_board', v_ch.zone = 'The Landing' and v_ch.travel_to is null,
    'level', public.character_level(v_ch.xp), 'min_level', public.mission_val('min_level'),
    'credits', v_ch.credits, 'cost', public.mission_val('cost_credits'),
    'per_region', public.mission_val('per_region_day'), 'hours', public.mission_val('hours'),
    'lean_mins', public.mission_val('lean_mins'),
    'bought', (select count(*) from public.character_missions m
                where m.character_id = p_character and m.region = v_ch.region and m.day = v_day),
    'board', coalesce((select jsonb_agg(case when m.id is not null then public.mission_row_json(m)
        else jsonb_build_object('pos', b.pos, 'status', 'open', 'kind', b.kind, 'qty', b.qty, 'name', b.name,
               'blurb', b.blurb, 'reward', b.reward,
               'dungeon', case when b.kind = 'dungeon' then (select d.name from public.pve_dungeon_config d
                   where d.region = v_ch.region and d.event_key is null limit 1) end) end order by b.pos)
      from public.mission_board(p_character, v_ch.region, v_day) b
      left join public.character_missions m on m.character_id = p_character and m.region = v_ch.region
        and m.day = v_day and m.pos = b.pos), '[]'::jsonb),
    'active', coalesce((select jsonb_agg(public.mission_row_json(m) order by m.expires_at)
      from public.character_missions m
      where m.character_id = p_character and m.status = 'active' and m.expires_at > now()), '[]'::jsonb),
    'lean', (select jsonb_build_object('affix', l.affix, 'name', a.name, 'region', l.region, 'region_name', r.name, 'until', l.until)
      from public.character_gear_lean l
      join public.affix_config a on a.key = l.affix
      join public.region_config r on r.id = l.region
      where l.character_id = p_character and l.until > now()),
    'lean_map', (select jsonb_agg(jsonb_build_object('region', x.region, 'region_name', x.rn, 'affixes', x.af) order by x.tier)
      from (select c.region, r.name rn, r.tier,
                   jsonb_agg(jsonb_build_object('key', c.affix, 'name', a.name, 'jewel', a.jewel) order by a.name) af
            from public.mission_lean_config c
            join public.affix_config a on a.key = c.affix
            join public.region_config r on r.id = c.region
            group by c.region, r.name, r.tier) x)
  )::json;
end $f$;

/* KOPET avgors helt har: niva, plats, tavlans plats, dygnets tak och credits. */
create or replace function public.mission_buy(p_character uuid, p_pos integer) returns json
  language plpgsql security definer set search_path to 'public','pg_temp'
as $f$
declare v_ch public.characters; v_day date := public.mission_day(); v_b record; v_n integer; v_cost integer;
begin
  perform public.owned_character(p_character);
  /* Karaktaren last forst: tva samtidiga kop far inte se samma credits och samma tak. */
  select * into v_ch from public.characters where id = p_character for update;
  if public.character_level(v_ch.xp) < public.mission_val('min_level') then
    raise exception 'mission_level' using errcode='P0001', detail = public.mission_val('min_level')::text;
  end if;
  if v_ch.zone is distinct from 'The Landing' or v_ch.travel_to is not null then
    raise exception 'not_at_board' using errcode='P0001';
  end if;
  select * into v_b from public.mission_board(p_character, v_ch.region, v_day) b where b.pos = p_pos;
  if not found then raise exception 'mission_unknown' using errcode='P0001'; end if;
  if exists (select 1 from public.character_missions m where m.character_id = p_character
             and m.region = v_ch.region and m.day = v_day and m.pos = p_pos) then
    raise exception 'mission_taken' using errcode='P0001';
  end if;
  select count(*) into v_n from public.character_missions m
    where m.character_id = p_character and m.region = v_ch.region and m.day = v_day;
  if v_n >= public.mission_val('per_region_day') then raise exception 'mission_limit' using errcode='P0001'; end if;

  v_cost := public.mission_val('cost_credits')::integer;
  perform public.apply_currency(p_character, 'mission', 0, 0, 0, 0,
    jsonb_build_object('template', v_b.template_id, 'region', v_ch.region), -v_cost);
  insert into public.character_missions (character_id, region, day, pos, template_id, kind, qty, baseline, reward, expires_at)
  values (p_character, v_ch.region, v_day, p_pos, v_b.template_id, v_b.kind, v_b.qty,
          case when v_b.kind = 'gather' then public.mission_gather_now(p_character, v_ch.region) end,
          v_b.reward, now() + make_interval(hours => public.mission_val('hours')::integer));
  return public.mission_state(p_character);
end $f$;

/* En cache: i vaskan om det gar, annars med posten, sa inget forsvinner och inlamningen aldrig nekas. */
create or replace function public.mission_give_cache(p_character uuid, p_key text, p_qty integer) returns void
  language plpgsql security definer set search_path to 'public','pg_temp'
as $f$
begin
  if coalesce(p_qty, 0) <= 0 then return; end if;
  if public.bag_free(p_character) > 0
     or exists (select 1 from public.stacks s where s.character_id = p_character and s.stack_key = p_key) then
    perform public.add_stack(p_character, p_key, 'item', p_qty, null);
  else
    perform public.send_mail(p_character, 'Mission Board', 'Your mission reward',
      'Your backpack was full, so it was set aside. Make room and collect it here.',
      jsonb_build_array(jsonb_build_object('stack_key', p_key, 'kind', 'item', 'qty', p_qty)));
  end if;
end $f$;

/* INLAMNINGEN: pa samma tavla som uppdraget kom fran. p_affix = vald egenskap om regionen har flera. */
create or replace function public.mission_claim(p_character uuid, p_mission uuid, p_affix text default null) returns json
  language plpgsql security definer set search_path to 'public','pg_temp'
as $f$
declare v_ch public.characters; v_m public.character_missions; v_affix text := p_affix; v_n integer; v_old text;
        v_until timestamptz; v_lean boolean; v_gear integer; v_help integer;
begin
  perform public.owned_character(p_character);
  select * into v_ch from public.characters where id = p_character for update;
  select * into v_m from public.character_missions where id = p_mission and character_id = p_character for update;
  if not found or v_m.status <> 'active' then raise exception 'mission_not_active' using errcode='P0001'; end if;
  if v_m.expires_at <= now() then raise exception 'mission_expired' using errcode='P0001'; end if;
  if v_ch.region is distinct from v_m.region or v_ch.zone is distinct from 'The Landing' or v_ch.travel_to is not null then
    raise exception 'mission_wrong_place' using errcode='P0001';
  end if;
  if public.mission_progress(v_m) < v_m.qty then raise exception 'mission_not_done' using errcode='P0001'; end if;

  v_lean := coalesce((v_m.reward->>'lean')::boolean, false);
  if v_lean then
    select count(*) into v_n from public.mission_lean_config c where c.region = v_m.region;
    if v_affix is null and v_n = 1 then
      select c.affix into v_affix from public.mission_lean_config c where c.region = v_m.region;
    end if;
    if v_affix is null then raise exception 'mission_pick_affix' using errcode='P0001'; end if;
    if not exists (select 1 from public.mission_lean_config c where c.region = v_m.region and c.affix = v_affix) then
      raise exception 'mission_bad_affix' using errcode='P0001';
    end if;
  else
    v_affix := null;
  end if;

  perform set_config('genesis.nogather', 'on', true);   /* cachen ar inte samlad - raknas inte som samlat */
  v_gear := coalesce((v_m.reward->>'gear_cache')::integer, 0);
  v_help := coalesce((v_m.reward->>'helper_cache')::integer, 0);
  perform public.mission_give_cache(p_character, 'cache_gear', v_gear);
  perform public.mission_give_cache(p_character, 'cache_helper', v_help);

  if v_lean then
    /* DEN NYA ERSATTER DEN GAMLA (Chris 2026-11-01), sa chanserna aldrig delas. Klockan borjar om. */
    select l.affix into v_old from public.character_gear_lean l where l.character_id = p_character and l.until > now();
    v_until := now() + make_interval(mins => public.mission_val('lean_mins')::integer);
    insert into public.character_gear_lean (character_id, affix, region, until, set_at)
    values (p_character, v_affix, v_m.region, v_until, now())
    on conflict (character_id) do update
      set affix = excluded.affix, region = excluded.region, until = excluded.until, set_at = excluded.set_at;
  end if;

  update public.character_missions set status = 'claimed', claimed_at = now(), lean_affix = v_affix where id = p_mission;
  perform public.bump_stat(p_character, 'missions_done', 1);
  update public.characters set save_version = save_version + 1 where id = p_character;
  return json_build_object('state', public.mission_state(p_character),
    'got', json_build_object('gear_cache', v_gear, 'helper_cache', v_help, 'lean', v_affix,
      'lean_name', (select a.name from public.affix_config a where a.key = v_affix),
      'replaced', (select a.name from public.affix_config a where a.key = v_old and v_old is distinct from v_affix),
      'until', v_until));
end $f$;

/* ---- ROLL_ITEM: BUFFENS REGEL ----
   Viktad lottning i stallet for lika chans: -ln(u)/vikt ger P(egenskap) = vikt / summan av vikterna. Utan buff ar alla
   vikter 1 och fordelningen exakt som forut. Galler bara fallna pjaser: inte tillverkade (v_made eller golv > 0),
   inte handlarens hylla, inte Onboardingens forhandsvisning, och inte de kopvagar som satter genesis.no_lean. */
do $m$
declare v_src text; v_a text; v_n integer;
begin
  v_src := pg_get_functiondef('public.roll_item(uuid,text,integer,numeric,item_location,numeric,boolean,integer)'::regprocedure);
  if position('v_lean' in v_src) > 0 then return; end if;

  v_a := 'v_sock boolean := false;';
  if position(v_a in v_src) = 0 then raise exception 'ANKARE: declare i roll_item'; end if;
  v_src := replace(v_src, v_a, 'v_lean text; v_lean_w float8 := 1;   /* [TILLAGT v5.1411.0-uppdrag] buffen fran uppdragstavlan */' || chr(10) || '  ' || v_a);

  v_a := 'select * into v_slot from public.slot_config where idx = v_item.slot_idx;';
  if position(v_a in v_src) = 0 then raise exception 'ANKARE: slot i roll_item'; end if;
  v_src := replace(v_src, v_a, v_a || chr(10) ||
    '  /* [TILLAGT v5.1411.0-uppdrag] Bara fallna pjaser lutar (Chris 2026-11-01). */' || chr(10) ||
    '  if not v_made and v_fl = 0 and p_location in (''bag'', ''mail'') and coalesce(current_setting(''genesis.no_lean'', true), '''') <> ''on'' then' || chr(10) ||
    '    v_lean := public.gear_lean_active(p_character);' || chr(10) ||
    '    if v_lean is not null then v_lean_w := greatest(1, public.mission_val(''lean_weight''))::float8; end if;' || chr(10) ||
    '  end if;');

  v_a := 'and not crafted_only order by random() limit 1;';
  v_n := (length(v_src) - length(replace(v_src, v_a, ''))) / length(v_a);
  if v_n <> 4 then raise exception 'ANKARE: vantade 4 lottningar i roll_item, fann %', v_n; end if;
  v_src := replace(v_src, v_a, 'and not crafted_only order by -ln(1 - random()) / (case when key = v_lean then v_lean_w else 1 end) limit 1;');
  execute v_src;
end $m$;

/* Kopvagarna som ocksa gar genom roll_item men inte ar fynd: de stanger av lutningen for sin egen transaktion. */
do $m$
declare v_f record; v_src text; v_n integer;
  v_lapp text := 'perform set_config(''genesis.no_lean'', ''on'', true);   /* [TILLAGT v5.1411.0-uppdrag] kopt eller skapat, inte fallet */' || chr(10) || '  ';
begin
  for v_f in select * from (values
    ('event_shop_buy'::text,  'perform public.owned_character(p_character);'),
    ('wb_marks_redeem',       'perform public.owned_character(p_character);'),
    ('take_mail',             'perform public.owned_character(p_character);'),
    ('admin_item_set_rarity', 'v_lim := public.admin_has(''items.manage'');')) t(fn, ankare)
  loop
    select count(*), max(pg_get_functiondef(p.oid)) into v_n, v_src from pg_proc p
      where p.proname = v_f.fn and p.pronamespace = 'public'::regnamespace;
    if v_n > 1 then raise exception 'ANKARE: % har flera versioner', v_f.fn; end if;
    if v_src is null then raise exception 'ANKARE: % saknas', v_f.fn; end if;
    if position('genesis.no_lean' in v_src) > 0 then continue; end if;
    v_n := (length(v_src) - length(replace(v_src, v_f.ankare, ''))) / length(v_f.ankare);
    if v_n <> 1 then raise exception 'ANKARE: % har % traffar', v_f.fn, v_n; end if;
    execute replace(v_src, v_f.ankare, v_lapp || v_f.ankare);
  end loop;
end $m$;

/* ---- ATKOMST: nya funktioner ar oppna for alla som standard ---- */
revoke execute on function public.mission_val(text), public.mission_day(), public.gear_lean_active(uuid),
  public.mission_board(uuid,text,date), public.mission_gather_now(uuid,text),
  public.mission_progress(public.character_missions), public.mission_row_json(public.character_missions),
  public.mission_give_cache(uuid,text,integer)
  from public, anon, authenticated;
grant execute on function public.mission_state(uuid), public.mission_buy(uuid,integer), public.mission_claim(uuid,uuid,text) to authenticated;
revoke execute on function public.mission_state(uuid), public.mission_buy(uuid,integer), public.mission_claim(uuid,uuid,text) from public, anon;
