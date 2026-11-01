/* [TILLAGT v5.1376.0] THE HAUNTED HOUSE (Chris 2026-10-30): Halloween-dungeon, spegel av The Deepshaft (samma zon i Voxholm,
   samma tider, styrka, bossantal och chanser). Bara Normal och Heroic, inga Rifts. Oppen bara medan eventet pagar
   (event_key). Sista bossen: 10 % (Heroic 20 %) att dropen blir en Ghost Sheet (chest, alla rariteter) - extra_item.
   Tva dungeons i samma zon: spelaren valjer i dungeonrutan (dungeon_pick -> characters.dg_pick), dungeon_here valjer. */

alter table public.pve_dungeon_config add column if not exists event_key text references public.season_events(key);
alter table public.pve_dungeon_config add column if not exists extra_item text;
alter table public.pve_dungeon_config add column if not exists extra_chance numeric not null default 0;
alter table public.pve_dungeon_config add column if not exists h_extra_chance numeric not null default 0;
alter table public.pve_dungeon_config add column if not exists no_rift boolean not null default false;
alter table public.characters add column if not exists dg_pick text;

/* Ghost Sheet: en vanlig chest i alla rariteter som aldrig faller i varlden */
insert into public.item_config (key, name, slot_idx, rarities, bag_slots, drop_rarities, two_hand, region)
values ('ghost_sheet', 'Ghost Sheet', 1, '{0,1,2,3,4,5}', null, '{}', false, null)
on conflict (key) do update set name = excluded.name, slot_idx = excluded.slot_idx, rarities = excluded.rarities, drop_rarities = excluded.drop_rarities;

insert into public.pve_dungeon_config
select 'hauntedhouse', region, zone, 'The Haunted House', minutes, revive_max, gear_chance_boss, gear_chance_final, w_common, w_uncommon, w_rare,
       xp_mult_boss, xp_mult_final, scrap_trash, scrap_boss, scrap_final, sig_chance, h_minutes, h_revive_max, h_hp_mult, h_atk_mult,
       h_gear_chance_boss, h_gear_chance_final, h_sig_chance, h_w_uncommon, h_w_rare, h_w_epic,
       'halloween_2026', 'ghost_sheet', 0.10, 0.20, true
from public.pve_dungeon_config where id = 'deepshaft'
on conflict (id) do update set name = excluded.name, event_key = excluded.event_key, extra_item = excluded.extra_item,
  extra_chance = excluded.extra_chance, h_extra_chance = excluded.h_extra_chance, no_rift = excluded.no_rift;

insert into public.pve_dungeon_fight_config (dungeon_id, ord, minute, kind, name, ptype, level, hp_mult, atk_mult)
select 'hauntedhouse', f.ord, f.minute, f.kind,
  case f.name when 'Pit Crawlers' then 'Cellar Spiders' when 'Tunnel Scrappers' then 'Cursed Butlers' when 'Stray Minecarts' then 'Possessed Toy Soldiers'
              when 'Dust Devils' then 'Cold Drafts' when 'Faded Miners' then 'Wailing Portraits' when 'Foreman Blockjaw' then 'Count Nocturne'
              when 'Rustshell Borer' then 'Old Tock' when 'Pale Greta' then 'The Lady in White' when 'Magma Sump' then 'Sir Rattlebones'
              when 'Old Gnash' then 'Grimfang' else f.name end,
  case when f.name = 'Magma Sump' then 'humanoid' else f.ptype end,   /* skelettet ar en humanoid */
  f.level, f.hp_mult, f.atk_mult
from public.pve_dungeon_fight_config f where f.dungeon_id = 'deepshaft'
on conflict do nothing;

/* vilken dungeon som galler i en zon for en karaktar: valet (dg_pick) om det finns dar och ar oppet, annars den vanliga */
create or replace function public.dungeon_here(p_character uuid, p_region text, p_zone text)
 returns text language sql stable security definer set search_path to 'public', 'pg_temp'
as $f$
  select d.id from public.pve_dungeon_config d
  where d.region = p_region and d.zone = p_zone and (d.event_key is null or d.event_key = public.event_now_key())
  order by (d.id = (select c.dg_pick from public.characters c where c.id = p_character)) desc nulls last, (d.event_key is null) desc, d.id
  limit 1
$f$;
revoke execute on function public.dungeon_here(uuid, text, text) from public, anon, authenticated;

create or replace function public.dungeon_pick(p_character uuid, p_dungeon text)
 returns json language plpgsql security definer set search_path to 'public', 'pg_temp'
as $f$
begin
  perform public.owned_character(p_character);
  if not exists (select 1 from public.pve_dungeon_config where id = p_dungeon and (event_key is null or event_key = public.event_now_key())) then
    raise exception 'no_dungeon_here' using errcode = 'P0001';
  end if;
  update public.characters set dg_pick = p_dungeon where id = p_character;
  return json_build_object('ok', true, 'dungeon', p_dungeon);
end $f$;
grant execute on function public.dungeon_pick(uuid, text) to authenticated;
revoke execute on function public.dungeon_pick(uuid, text) from public, anon;

/* veckans Rift och dungeonbetygen raknar inte eventdungeons */
create or replace function public.rift_dungeon_for_week(p_day date DEFAULT ((now() AT TIME ZONE 'Europe/Stockholm'::text))::date)
 returns text language sql stable
as $f$
  select id from (
    select d.id, row_number() over (order by rc.tier, d.id) - 1 as rn, count(*) over () as n
    from public.pve_dungeon_config d join public.region_config rc on rc.id = d.region where (rc.released or rc.release_at <= now()) and d.event_key is null) x   /* [ANDRAT v5.1376.0] eventdungeons utanfor */
  where x.rn = (extract(week from p_day)::integer + extract(isoyear from p_day)::integer * 53) % x.n
$f$;

do $p$
declare d text; a text; b text;
begin
  /* --- dungeon_choices --- */
  d := pg_get_functiondef('public.dungeon_choices'::regproc);
  a := E'  select * into v_dg from public.pve_dungeon_config\n   where region = v_reg and zone = v_zon;';
  if position(a in d) = 0 then raise exception 'ankare choices 1'; end if;
  d := replace(d, a, '  select * into v_dg from public.pve_dungeon_config where id = public.dungeon_here(p_character, v_reg, v_zon);   /* [ANDRAT v5.1376.0] valet i zonen */');
  a := E'return json_build_object(''here'', true, ''dungeon'', v_dg.id, ''name'', v_dg.name,';
  if position(a in d) = 0 then raise exception 'ankare choices 2'; end if;
  d := replace(d, a, a || E'\n    ''choices'', (select json_agg(json_build_object(''id'', x.id, ''name'', x.name, ''event'', x.event_key) order by x.event_key nulls first, x.id) from public.pve_dungeon_config x where x.region = v_dg.region and x.zone = v_dg.zone and (x.event_key is null or x.event_key = public.event_now_key())),\n    ''event'', v_dg.event_key, ''no_rift'', v_dg.no_rift,\n    ''extra'', case when v_dg.extra_item is not null then json_build_object(''item'', v_dg.extra_item, ''chance'', v_dg.extra_chance, ''h_chance'', v_dg.h_extra_chance) end,   /* [TILLAGT v5.1376.0] */');
  execute d;

  /* --- pve_dungeon_start --- */
  d := pg_get_functiondef('public.pve_dungeon_start'::regproc);
  a := E'(select c.id from public.pve_dungeon_config c join public.characters ch on ch.id = p_character\n        where c.region = ch.region and c.zone = ch.zone)';
  if position(a in d) = 0 then raise exception 'ankare start 1'; end if;
  d := replace(d, a, '(select public.dungeon_here(p_character, ch.region, coalesce(ch.zone, '''')) from public.characters ch where ch.id = p_character)');
  a := '(select c.id from public.pve_dungeon_config c where c.region = v_ch.region and c.zone = coalesce(v_ch.zone, ''''))';
  if position(a in d) = 0 then raise exception 'ankare start 2'; end if;
  d := replace(d, a, 'public.dungeon_here(p_character, v_ch.region, coalesce(v_ch.zone, ''''))');
  a := E'  select * into v_dg from public.pve_dungeon_config\n    where region = v_ch.region and zone = coalesce(v_ch.zone,'''');\n  if not found then raise exception ''no_dungeon_here'' using errcode=''P0001''; end if;';
  if position(a in d) = 0 then raise exception 'ankare start 3'; end if;
  d := replace(d, a, E'  select * into v_dg from public.pve_dungeon_config where id = public.dungeon_here(p_character, v_ch.region, coalesce(v_ch.zone,''''));   /* [ANDRAT v5.1376.0] */\n  if not found then raise exception ''no_dungeon_here'' using errcode=''P0001''; end if;\n  if v_rift > 0 and v_dg.no_rift then raise exception ''no_rift_here'' using errcode=''P0001''; end if;   /* [TILLAGT v5.1376.0] eventdungeons har inga Rifts */');
  execute d;

  /* --- pve_dungeon_state --- */
  d := pg_get_functiondef('public.pve_dungeon_state'::regproc);
  a := E'  select * into v_dg from public.pve_dungeon_config\n    where region = v_ch.region and zone = coalesce(v_ch.zone,'''');';
  if position(a in d) = 0 then raise exception 'ankare state'; end if;
  d := replace(d, a, '  select * into v_dg from public.pve_dungeon_config where id = public.dungeon_here(p_character, v_ch.region, coalesce(v_ch.zone,''''));   /* [ANDRAT v5.1376.0] */');
  execute d;

  /* --- pve_dungeon_ratings: bara oppna dungeons --- */
  d := pg_get_functiondef('public.pve_dungeon_ratings'::regproc);
  a := 'for r in select id from public.pve_dungeon_config order by id loop';
  if position(a in d) = 0 then raise exception 'ankare ratings'; end if;
  d := replace(d, a, 'for r in select id from public.pve_dungeon_config where event_key is null or event_key = public.event_now_key() order by id loop   /* [ANDRAT v5.1376.0] */');
  execute d;

  /* --- pve_dungeon_sim: sista bossens extra pjas (Ghost Sheet) --- */
  d := pg_get_functiondef('public.pve_dungeon_sim'::regproc);
  a := E'          if v_loot_key is null then\n            v_loot_key := public.pick_item_key_r(v_loot_rar, p_character);\n          end if;\n        end if;\n      end if;\n';
  if position(a in d) = 0 then raise exception 'ankare sim'; end if;
  d := replace(d, a, a || E'      /* [TILLAGT v5.1376.0] EVENTDUNGEONENS EXTRA PJAS (Chris): sista bossen, extra_chance (Heroic h_extra_chance) - dropen blir\n         extra_item. Fanns ingen drop rullas rariteten som en vanlig bossdrop (Heroic aldrig Common). Aldrig i Rift. */\n      if v_ft.kind = ''final'' and v_dg.extra_item is not null and v_rift = 0\n         and random() < (case when p_heroic then v_dg.h_extra_chance else v_dg.extra_chance end) then\n        if v_loot_rar is null then\n          declare v_gw integer[]; v_gt numeric := 0; v_gp numeric; v_gk integer;\n          begin\n            v_gw := public.gear_weights_for(p_character, coalesce(v_tier, 0));\n            if p_heroic then v_gw[1] := 0; end if;\n            for v_gk in 1..6 loop v_gt := v_gt + v_gw[v_gk]; end loop;\n            v_gp := random() * v_gt; v_loot_rar := 0;\n            for v_gk in 1..6 loop v_gp := v_gp - v_gw[v_gk]; if v_gp < 0 then v_loot_rar := v_gk - 1; exit; end if; end loop;\n          end;\n        end if;\n        v_loot_key := v_dg.extra_item; v_sig := false; v_fx_key := null;\n      end if;\n');
  execute d;
end $p$;

/* [ANDRAT v5.1376.0] Chris: sista bossen ar spoket (det ar det som slapper Ghost Sheet) - varulven tar spokets plats (migrering haunted_house_ghost_final) */
update public.pve_dungeon_fight_config set name = 'Grimfang', ptype = 'creature' where dungeon_id = 'hauntedhouse' and ord = 9;
update public.pve_dungeon_fight_config set name = 'The Lady in White', ptype = 'spirit' where dungeon_id = 'hauntedhouse' and ord = 15;
