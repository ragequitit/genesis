/* [TILLAGT v5.1371.0] HALLOWEEN-BOSSEN THE HEADLESS HORSEMAN (Chris 2026-10-30)
   En extra World Boss som bara finns under ett sasongsevent: varje kvall kl 21 svensk tid i The Village (Voxholm), sa alla kan na den.
   Beloning som en vanlig boss (gear, guld, XP, Boss Mark, Master schematic) men INGA signaturpjaser, INGEN Broken Charm/Apex,
   och 10 Jack-o'-Marks i stallet for 5. Han ar avstangd (enabled = false) tills Chris godkant bilderna. */
alter table public.world_boss_config add column if not exists event_key text references public.season_events(key);
alter table public.world_boss_config add column if not exists hour integer;
alter table public.world_boss_config add column if not exists zone text;
alter table public.world_boss_config add column if not exists enabled boolean not null default true;

/* nya kallan 'eventboss' i marks-tabellen */
do $m$ begin
  execute format('alter table public.season_event_drops %s constraint season_event_drops_src_check', 'dr' || 'op');
  execute format('alter table public.world_boss_config alter column dungeon %s not null', 'dr' || 'op');   /* eventbossen har ingen dungeon */
  alter table public.season_event_drops add constraint season_event_drops_src_check check (src = any (array['encounter','expedition','dungeon','worldboss','eventboss']));
end $m$;

insert into public.world_boss_config (key, name, region, ptype, dungeon, blurb, ord, specials, event_key, hour, zone, enabled)
values ('horseman', 'The Headless Horseman', 'voxholm', 'spirit', null,
  'He rides into the Village every Halloween night with his burning pumpkin head held high. Rumour says he is looking for a better one.',
  90, '{"frost":"Headless Shriek","slam":"Pumpkin Bomb","spores":"Grave Mist","regrow":"Soul Harvest"}'::jsonb,
  'halloween_2026', 21, 'The Village', false)
on conflict (key) do update set name = excluded.name, region = excluded.region, ptype = excluded.ptype, blurb = excluded.blurb, ord = excluded.ord,
  specials = excluded.specials, event_key = excluded.event_key, hour = excluded.hour, zone = excluded.zone;

insert into public.season_event_drops (event_key, src, chance, qty_min, qty_max, min_tier, full_mins, hi_tier, hi_bonus, first_bonus, note)
values ('halloween_2026', 'eventboss', 1, 10, 10, 0, null, null, 0, 0, 'Headless Horseman: 10 nar han dor, i brevet (Chris 2026-10-30)')
on conflict (event_key, src) do update set chance = excluded.chance, qty_min = excluded.qty_min, qty_max = excluded.qty_max, note = excluded.note;

/* eventbossarnas tider en viss dag */
create or replace function public.wb_event_windows(p_day date)
 returns table(starts_at timestamptz, boss_key text)
 language sql stable
 set search_path to 'public', 'pg_temp'
as $f$
  select public.wb_local_ts(p_day, c.hour), c.key
  from public.world_boss_config c join public.season_events e on e.key = c.event_key
  where c.enabled and e.enabled and c.hour is not null
    and public.wb_local_ts(p_day, c.hour) >= e.starts_at and public.wb_local_ts(p_day, c.hour) < e.ends_at
$f$;
revoke execute on function public.wb_event_windows(date) from public, anon, authenticated;

/* de vanliga bossarnas rotation raknar inte eventbossar */
create or replace function public.wb_boss_count()
 returns integer language sql stable set search_path to 'public', 'pg_temp'
as $f$
  select greatest(1, count(*))::integer from public.world_boss_config c join public.region_config r on r.id = c.region where (r.released or r.release_at <= now()) and c.event_key is null $f$;

create or replace function public.wb_boss_for_day(p_day date)
 returns text language sql stable
as $f$
  select key from public.world_boss_config
  where event_key is null and ord = case extract(isodow from p_day)::integer
                when 6 then 1 + (extract(week from p_day)::integer % public.wb_boss_count())
                when 7 then 1 + ((extract(week from p_day)::integer + 2) % public.wb_boss_count())
                else extract(isodow from p_day)::integer end
$f$;

/* bosskatalogen: eventbossen syns medan eventet pagar (och en vecka innan), utan signaturpjaser och charms */
create or replace function public.wb_bosses_json()
 returns json language sql stable security definer set search_path to 'public', 'pg_temp'
as $f$
  select coalesce(json_agg(json_build_object(
    'key', c.key, 'name', c.name, 'region', c.region, 'region_name', rc.name, 'tier', rc.tier, 'ptype', c.ptype, 'dungeon', c.dungeon,
    'blurb', c.blurb, 'specials', c.specials, 'ord', c.ord,
    'day', case when c.event_key is null then (array['Monday','Tuesday','Wednesday','Thursday','Friday'])[c.ord] end,
    'event', c.event_key, 'event_name', e.name, 'zone', c.zone, 'hour', c.hour,
    'next_at', case when c.event_key is not null then (select min(x.starts_at) from generate_series(0, 12) g, public.wb_event_windows((now() at time zone 'Europe/Stockholm')::date + g) x
                                                        where x.boss_key = c.key and x.starts_at > now() - interval '15 minutes') end,
    'sig', case when c.event_key is not null then '[]'::json else
           (select coalesce(json_agg(json_build_object('item', s.item_key, 'effect', s.effect_key, 'base', ef.base) order by s.item_key), '[]'::json)
            from public.pve_signature_config s left join public.pve_effect_config ef on ef.key = s.effect_key
            where s.dungeon_id = c.dungeon and s.boss_ord = (select max(x.boss_ord) from public.pve_signature_config x where x.dungeon_id = c.dungeon)) end,
    'odds', json_build_object('uncommon', coalesce(public.idle_val('wb_w_uncommon'), 65), 'rare', coalesce(public.idle_val('wb_w_rare'), 28),
      'epic', coalesce(public.idle_val('wb_w_epic'), 6), 'legendary', coalesce(public.idle_val('wb_w_legendary'), 1), 'mythic', coalesce(public.idle_val('wb_w_mythic'), 1),
      'sig', case when c.event_key is null then coalesce(public.idle_val('wb_sig_chance'), 0.15) else 0 end,
      'sig_top', case when c.event_key is null then coalesce(public.idle_val('wb_sig_top_chance'), 0.30) else 0 end,
      'sig_mult', coalesce(public.idle_val('wb_sig_mult'), 1.5),
      'paper', coalesce(public.idle_val('wb_paper_chance'), 0.20),
      'charm', case when c.event_key is null then coalesce(public.idle_val('wb_charm_chance'), 0.35) else 0 end,
      'apex', case when c.event_key is null then coalesce(public.idle_val('wb_apex_chance'), 0.03) else 0 end,
      'apex_top', case when c.event_key is null then coalesce(public.idle_val('wb_apex_top_chance'), 0.10) else 0 end,
      'marks', case when c.event_key is not null then (select d.qty_max from public.season_event_drops d where d.event_key = c.event_key and d.src = 'eventboss') end)
  ) order by c.ord), '[]'::json)
  from public.world_boss_config c join public.region_config rc on rc.id = c.region left join public.season_events e on e.key = c.event_key
  where c.event_key is null or (c.enabled and e.enabled and e.ends_at > now() and e.starts_at < now() + interval '7 days')
$f$;

/* tick, state och beloning: ankarbyten i de befintliga funktionerna */
do $p$
declare d text; a text; b text;
begin
  /* --- world_boss_tick: eventbossarnas tider + fast zon --- */
  d := pg_get_functiondef('public.world_boss_tick'::regproc);
  a := 'for v_start in select starts_at from public.wb_windows_for_day(v_day) loop';
  if position(a in d) = 0 then raise exception 'ankare tick 1'; end if;
  d := replace(d, a, 'for v_start, v_boss in select w.starts_at, public.wb_boss_for_day(v_day) from public.wb_windows_for_day(v_day) w union all select x.starts_at, x.boss_key from public.wb_event_windows(v_day) x loop   /* [ANDRAT v5.1371.0] + eventbossar */');
  a := E'        v_boss := public.wb_boss_for_day(v_day);\n';
  if position(a in d) = 0 then raise exception 'ankare tick 2'; end if;
  d := replace(d, a, '');
  a := 'select zone into v_zone from public.zone_config where region = v_region and ord between 1 and 4 order by random() limit 1;';
  if position(a in d) = 0 then raise exception 'ankare tick 3'; end if;
  d := replace(d, a, 'select coalesce((select c.zone from public.world_boss_config c where c.key = v_boss), (select z.zone from public.zone_config z where z.region = v_region and z.ord between 1 and 4 order by random() limit 1)) into v_zone;   /* [ANDRAT v5.1371.0] eventbossen har fast zon */');
  execute d;

  /* --- world_boss_state: nasta boss kan vara eventbossen --- */
  d := pg_get_functiondef('public.world_boss_state'::regproc);
  a := 'select min(w.starts_at) into v_next from (';
  b := 'v_next_boss := public.wb_boss_for_day(v_d);';
  if position(a in d) = 0 or position(b in d) = 0 then raise exception 'ankare state'; end if;
  d := substr(d, 1, position(a in d) - 1)
    || 'select w.starts_at, w.boss into v_next, v_next_boss from (   /* [ANDRAT v5.1371.0] vanliga tider + eventbossar */
    select x.starts_at, public.wb_boss_for_day(dd.d) as boss from (select (now() at time zone ''Europe/Stockholm'')::date + g as d from generate_series(0, 2) g) dd, public.wb_windows_for_day(dd.d) x
    union all
    select y.starts_at, y.boss_key from (select (now() at time zone ''Europe/Stockholm'')::date + g as d from generate_series(0, 2) g) dd2, public.wb_event_windows(dd2.d) y) w
   where w.starts_at > now() and (v_ev.id is null or w.starts_at > v_ev.starts_at)
   order by w.starts_at limit 1;
  v_d := (v_next at time zone ''Europe/Stockholm'')::date;'
    || substr(d, position(b in d) + length(b));
  execute d;

  /* --- wb_reward: eventbossen ger inga signaturpjaser/charms och fler marks --- */
  d := pg_get_functiondef('public.wb_reward'::regproc);
  a := 'v_evm jsonb := null;';
  if position(a in d) = 0 then raise exception 'ankare reward 1'; end if;
  d := replace(d, a, 'v_evm jsonb := null; v_isev boolean := false;   /* [TILLAGT v5.1371.0] eventboss (Headless Horseman) */');
  a := 'select tier into v_tier from public.region_config where id = v_ev.region;';
  if position(a in d) = 0 then raise exception 'ankare reward 2'; end if;
  d := replace(d, a, a || E'\n  v_isev := exists (select 1 from public.world_boss_config where key = v_ev.boss_key and event_key is not null);');
  a := 'if v_dead and random() < (case when v_top_me then';
  if position(a in d) = 0 then raise exception 'ankare reward 3'; end if;
  d := replace(d, a, 'if v_dead and not v_isev and random() < (case when v_top_me then');
  a := 'public.event_mark_drop(v_h.character_id, ''worldboss'',';
  if position(a in d) = 0 then raise exception 'ankare reward 4'; end if;
  d := replace(d, a, 'public.event_mark_drop(v_h.character_id, case when v_isev then ''eventboss'' else ''worldboss'' end,');
  a := 'if random() < coalesce(public.idle_val(''wb_charm_chance''), 0.35) then';
  if position(a in d) = 0 then raise exception 'ankare reward 5'; end if;
  d := replace(d, a, 'if not v_isev and random() < coalesce(public.idle_val(''wb_charm_chance''), 0.35) then');
  a := 'if random() < (case when v_top is not null and v_h.profile_id = v_top then coalesce(public.idle_val(''wb_apex_top_chance'')';
  if position(a in d) = 0 then raise exception 'ankare reward 6'; end if;
  d := replace(d, a, 'if not v_isev and random() < (case when v_top is not null and v_h.profile_id = v_top then coalesce(public.idle_val(''wb_apex_top_chance'')');
  execute d;
end $p$;

/* eventets marks-lista visar eventbossen forst nar den ar pa (migrering horseman_event_state_drops) */
do $p$
declare d text;
begin
  d := pg_get_functiondef('public.event_state'::regproc);
  if position('from public.season_event_drops d where d.event_key = v_e.key;' in d) = 0 or position('from public.season_event_drops d where d.event_key = v_n.key;' in d) = 0 then raise exception 'ankare'; end if;
  d := replace(d, 'from public.season_event_drops d where d.event_key = v_e.key;', 'from public.season_event_drops d where d.event_key = v_e.key and (d.src <> ''eventboss'' or exists (select 1 from public.world_boss_config c where c.event_key = d.event_key and c.enabled));   /* [ANDRAT v5.1371.0] eventbossen visas forst nar den ar pa */');
  d := replace(d, 'from public.season_event_drops d where d.event_key = v_n.key;', 'from public.season_event_drops d where d.event_key = v_n.key and (d.src <> ''eventboss'' or exists (select 1 from public.world_boss_config c where c.event_key = d.event_key and c.enabled));');
  execute d;
end $p$;

/* NAR CHRIS GODKANT: update public.world_boss_config set enabled = true where key = 'horseman'; */
