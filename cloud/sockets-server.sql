-- ============================================================================
-- GENESIS v5.1358.0 — SOCKETS: Sockets och Mod Chips (v1)
-- ============================================================================
-- Kors i Supabase SQL Editor pa projektet genesis, i ETT svep (hela filen). Bara CREATE OR REPLACE / INSERT ... ON CONFLICT /
-- ALTER TABLE ADD COLUMN IF NOT EXISTS - ingen DROP, inget som tar bort data. Gar att kora flera ganger.
-- Funktionerna som ANDRAS ar byggda ur serverns nuvarande kod (hamtad 2026-10-29) med de rader som laggs till markerade
-- [TILLAGT v5.1358.0] / [ANDRAT v5.1358.0]. Ankarstrangarna star i cloud/SOCKETS-README.md.
-- Nya security definer-funktioner: revoke execute from public, anon; grant execute to authenticated.
-- ============================================================================

-- ============================================================================
-- 1. Kolumner och tabeller
-- ============================================================================
/* [TILLAGT v5.1358.0] SOCKETS OCH MOD CHIPS (Chris beslut). Varfor egna kolumner och inte items.socket:
   items har redan socket_kind/socket_idx som betyder VASKPLATS (en vaska som sitter i ett fack). Att ateranvanda
   ordet hade gett tva olika saker med samma namn i samma tabell. Darfor mod_socket (har pjasen en socket),
   mod_chip (chipet som sitter i: {"key","k","v","r","salv"}) och bound (Bind on Pickup - borrad pjas, Salvaged chip,
   uttaget/fusionerat chip). */
alter table public.items add column if not exists mod_socket boolean not null default false;
alter table public.items add column if not exists mod_chip jsonb;
alter table public.items add column if not exists bound boolean not null default false;
/* Dolt otursskydd: pjaser i rad (Epic eller battre) utan socket. Syns aldrig for spelaren. */
alter table public.characters add column if not exists socket_pity integer not null default 0;
/* Stapelvaror kan vara bundna (Socket Drill). Materialen hade bop redan; stapelvarorna saknade det. */
alter table public.stack_item_config add column if not exists bop boolean not null default false;

/* Chipens egen "plats" i slot_config: items.slot_idx och item_config.slot_idx har FK hit. 15 ar ledigt (14 = Character Gem).
   jewel=false sa roll_item aldrig rullar smyckespoolen pa ett chip (roll_item ror aldrig chips, men for sakerhets skull). */
insert into public.slot_config (idx, id, name, jewel) values (15, 'modchip', 'Mod Chip', false)
  on conflict (idx) do nothing;

/* Sorterna. vals = varde per raritet Rare/Epic/Legendary/Mythic (index = raritet - 1, dvs vals[1..4]). cap = tak for allt man bar.
   Samma tal i klientens MODCHIP. Andras de har MASTE klienten andras ocksa. */
create table if not exists public.modchip_config (
  sort text primary key,
  affix text not null,
  name text not null,
  gem text not null,
  cap numeric not null,
  vals numeric[] not null
);
insert into public.modchip_config (sort, affix, name, gem, cap, vals) values
  ('crit',    'crit',    'Crit Chance',   'ruby',     18, array[1.3, 1.7, 2.3, 3.0]),
  ('critdmg', 'critdmg', 'Crit Damage',   'sapphire', 25, array[1.8, 2.4, 3.2, 4.2]),
  ('gold',    'gold',    'Gold Find',     'diamond',  40, array[2.8, 3.7, 5.0, 6.5]),
  ('dgspeed', 'dgspeed', 'Dungeon Speed', 'sapphire', 12, array[0.9, 1.1, 1.5, 2.0])
  on conflict (sort) do update set affix = excluded.affix, name = excluded.name, gem = excluded.gem, cap = excluded.cap, vals = excluded.vals;

/* Droppchanser per kalla (andel 0-1). Loot Luck paverkar INTE. expedition = vid 8 h tier 4, skalas i modchip_world_drops. */
create table if not exists public.modchip_drop_config (
  src text primary key,
  salvaged numeric not null default 0,
  epic numeric not null default 0,
  legendary numeric not null default 0,
  mythic numeric not null default 0
);
insert into public.modchip_drop_config (src, salvaged, epic, legendary, mythic) values
  ('encounter',  0.0005, 0.0005, 0.00015, 0.00003),
  ('expedition', 0.01,   0.015,  0.005,   0.001),
  ('dungeon',    0.03,   0.03,   0.01,    0.004),
  ('worldboss',  0,      0.04,   0.015,   0.006)
  on conflict (src) do update set salvaged = excluded.salvaged, epic = excluded.epic, legendary = excluded.legendary, mythic = excluded.mythic;

/* Pappren (Mod Chip Design). sorts = vilka sorter pappret kan lara ut (Mythic: tva, den som lar sig valjer). lvl = yrkesniva. */
create table if not exists public.modchip_design_config (
  key text primary key,
  rarity integer not null,
  sorts text[] not null,
  lvl integer not null
);
insert into public.modchip_design_config (key, rarity, sorts, lvl) values
  ('design_modchip_crit_epic',         3, array['crit'],    8),
  ('design_modchip_critdmg_epic',      3, array['critdmg'], 8),
  ('design_modchip_gold_epic',         3, array['gold'],    8),
  ('design_modchip_dgspeed_epic',      3, array['dgspeed'], 8),
  ('design_modchip_crit_legendary',    4, array['crit'],    12),
  ('design_modchip_critdmg_legendary', 4, array['critdmg'], 12),
  ('design_modchip_gold_legendary',    4, array['gold'],    12),
  ('design_modchip_dgspeed_legendary', 4, array['dgspeed'], 12),
  ('design_modchip_mythic_crit_critdmg',    5, array['crit','critdmg'],    16),
  ('design_modchip_mythic_crit_gold',       5, array['crit','gold'],       16),
  ('design_modchip_mythic_crit_dgspeed',    5, array['crit','dgspeed'],    16),
  ('design_modchip_mythic_critdmg_gold',    5, array['critdmg','gold'],    16),
  ('design_modchip_mythic_critdmg_dgspeed', 5, array['critdmg','dgspeed'], 16),
  ('design_modchip_mythic_gold_dgspeed',    5, array['gold','dgspeed'],    16)
  on conflict (key) do update set rarity = excluded.rarity, sorts = excluded.sorts, lvl = excluded.lvl;

/* Rattar: chip_fusion_gold i KOPPAR (250000 = 25 guld, Chris satter talet senare), socket_drill_marks = pris i Boss Marks,
   socket_pity = otursskyddets langd. */
insert into public.idle_config (key, value) values ('chip_fusion_gold', 250000) on conflict (key) do nothing;
insert into public.idle_config (key, value) values ('socket_drill_marks', 15) on conflict (key) do nothing;
insert into public.idle_config (key, value) values ('socket_pity', 150) on conflict (key) do nothing;

/* Chipen ar FOREMAL (items) - varje chip har sitt eget rullade varde, och det ryms inte i en stapel.
   drop_rarities ar tom: pick_item_key, pick_item_key_r, gear_drop_pick och vendor_restock valjer bara ur drop_rarities,
   sa ett chip kan aldrig falla som vanlig gear. rarities = de steg chipet finns i. */
insert into public.item_config (key, name, slot_idx, rarities, bag_slots, drop_rarities, two_hand, region) values
  ('modchip_crit_rare',         'Crit Chance Mod Chip',   15, '{2}', null, '{}', false, null),
  ('modchip_crit_epic',         'Crit Chance Mod Chip',   15, '{3}', null, '{}', false, null),
  ('modchip_crit_legendary',    'Crit Chance Mod Chip',   15, '{4}', null, '{}', false, null),
  ('modchip_crit_mythic',       'Crit Chance Mod Chip',   15, '{5}', null, '{}', false, null),
  ('modchip_critdmg_rare',      'Crit Damage Mod Chip',   15, '{2}', null, '{}', false, null),
  ('modchip_critdmg_epic',      'Crit Damage Mod Chip',   15, '{3}', null, '{}', false, null),
  ('modchip_critdmg_legendary', 'Crit Damage Mod Chip',   15, '{4}', null, '{}', false, null),
  ('modchip_critdmg_mythic',    'Crit Damage Mod Chip',   15, '{5}', null, '{}', false, null),
  ('modchip_gold_rare',         'Gold Find Mod Chip',     15, '{2}', null, '{}', false, null),
  ('modchip_gold_epic',         'Gold Find Mod Chip',     15, '{3}', null, '{}', false, null),
  ('modchip_gold_legendary',    'Gold Find Mod Chip',     15, '{4}', null, '{}', false, null),
  ('modchip_gold_mythic',       'Gold Find Mod Chip',     15, '{5}', null, '{}', false, null),
  ('modchip_dgspeed_rare',      'Dungeon Speed Mod Chip', 15, '{2}', null, '{}', false, null),
  ('modchip_dgspeed_epic',      'Dungeon Speed Mod Chip', 15, '{3}', null, '{}', false, null),
  ('modchip_dgspeed_legendary', 'Dungeon Speed Mod Chip', 15, '{4}', null, '{}', false, null),
  ('modchip_dgspeed_mythic',    'Dungeon Speed Mod Chip', 15, '{5}', null, '{}', false, null),
  ('salvaged_modchip',          'Salvaged Mod Chip',      15, '{2,3}', null, '{}', false, null)
  on conflict (key) do nothing;

/* Stapelvarorna: borren (bunden, saljs inte = kan inte laggas pa auktion), extraktorerna (saljbara) och pappren (saljbara). */
insert into public.stack_item_config (key, name, sell, vendor_sells, bop) values
  ('socket_drill',             'Socket Drill',             0,      false, true),
  ('chip_extractor_rare',      'Chip Extractor (Rare)',      5000,  false, false),
  ('chip_extractor_epic',      'Chip Extractor (Epic)',      15000, false, false),
  ('chip_extractor_legendary', 'Chip Extractor (Legendary)', 40000, false, false),
  ('chip_extractor_mythic',    'Chip Extractor (Mythic)',    100000,false, false),
  ('design_modchip_crit_epic',         'Epic Mod Chip Design: Crit Chance',        45000,  false, false),
  ('design_modchip_critdmg_epic',      'Epic Mod Chip Design: Crit Damage',        45000,  false, false),
  ('design_modchip_gold_epic',         'Epic Mod Chip Design: Gold Find',          45000,  false, false),
  ('design_modchip_dgspeed_epic',      'Epic Mod Chip Design: Dungeon Speed',      45000,  false, false),
  ('design_modchip_crit_legendary',    'Legendary Mod Chip Design: Crit Chance',   120000, false, false),
  ('design_modchip_critdmg_legendary', 'Legendary Mod Chip Design: Crit Damage',   120000, false, false),
  ('design_modchip_gold_legendary',    'Legendary Mod Chip Design: Gold Find',     120000, false, false),
  ('design_modchip_dgspeed_legendary', 'Legendary Mod Chip Design: Dungeon Speed', 120000, false, false),
  ('design_modchip_mythic_crit_critdmg',    'Mythic Mod Chip Design: Crit Chance or Crit Damage',   320000, false, false),
  ('design_modchip_mythic_crit_gold',       'Mythic Mod Chip Design: Crit Chance or Gold Find',     320000, false, false),
  ('design_modchip_mythic_crit_dgspeed',    'Mythic Mod Chip Design: Crit Chance or Dungeon Speed', 320000, false, false),
  ('design_modchip_mythic_critdmg_gold',    'Mythic Mod Chip Design: Crit Damage or Gold Find',     320000, false, false),
  ('design_modchip_mythic_critdmg_dgspeed', 'Mythic Mod Chip Design: Crit Damage or Dungeon Speed', 320000, false, false),
  ('design_modchip_mythic_gold_dgspeed',    'Mythic Mod Chip Design: Gold Find or Dungeon Speed',   320000, false, false)
  on conflict (key) do update set name = excluded.name, sell = excluded.sell, bop = excluded.bop;
update public.stack_item_config set bop = true where key = 'socket_drill';

/* RECEPTEN. Jewelcrafter: fyra Rare vid Apprentice (1), Epic Gold Find + Epic Dungeon Speed vid Adept (8) - kanda fran start.
   Epic Crit Chance, Epic Crit Damage och alla Legendary/Mythic = drop (bara via papper). INGET guld, inga kits (Chris).
   Weaponsmith: Chip Extractor per raritet, kanda fran start, Phase Scrap 50/100/200/400 + Charged Scrap 0/10/20/40.
   xp som charm-recepten pa samma steg. */
insert into public.recipe_config (id, prof, name, item_key, rarity, source, cost, lvl, drop_rarity, rank, perk, xp, out_qty) values
  ('cr_jc_modchip_crit_rare',         'jewelcrafter', 'Rare Crit Chance Mod Chip',        'modchip_crit_rare',         2, 'known', '{"ruby":10,"quartz_crystal":10,"charged_scrap":4}',     1,  null, 2, null, 150,  1),
  ('cr_jc_modchip_critdmg_rare',      'jewelcrafter', 'Rare Crit Damage Mod Chip',        'modchip_critdmg_rare',      2, 'known', '{"sapphire":10,"quartz_crystal":10,"charged_scrap":4}', 1,  null, 2, null, 150,  1),
  ('cr_jc_modchip_gold_rare',         'jewelcrafter', 'Rare Gold Find Mod Chip',          'modchip_gold_rare',         2, 'known', '{"diamond":10,"quartz_crystal":10,"charged_scrap":4}',  1,  null, 2, null, 150,  1),
  ('cr_jc_modchip_dgspeed_rare',      'jewelcrafter', 'Rare Dungeon Speed Mod Chip',      'modchip_dgspeed_rare',      2, 'known', '{"sapphire":10,"quartz_crystal":10,"charged_scrap":4}', 1,  null, 2, null, 150,  1),
  ('cr_jc_modchip_crit_epic',         'jewelcrafter', 'Epic Crit Chance Mod Chip',        'modchip_crit_epic',         3, 'drop',  '{"ruby":25,"prism_crystal":10,"phase_scrap":4}',        8,  null, 3, null, 350,  1),
  ('cr_jc_modchip_critdmg_epic',      'jewelcrafter', 'Epic Crit Damage Mod Chip',        'modchip_critdmg_epic',      3, 'drop',  '{"sapphire":25,"prism_crystal":10,"phase_scrap":4}',    8,  null, 3, null, 350,  1),
  ('cr_jc_modchip_gold_epic',         'jewelcrafter', 'Epic Gold Find Mod Chip',          'modchip_gold_epic',         3, 'known', '{"diamond":25,"prism_crystal":10,"phase_scrap":4}',     8,  null, 3, null, 350,  1),
  ('cr_jc_modchip_dgspeed_epic',      'jewelcrafter', 'Epic Dungeon Speed Mod Chip',      'modchip_dgspeed_epic',      3, 'known', '{"sapphire":25,"prism_crystal":10,"phase_scrap":4}',    8,  null, 3, null, 350,  1),
  ('cr_jc_modchip_crit_legendary',    'jewelcrafter', 'Legendary Crit Chance Mod Chip',   'modchip_crit_legendary',    4, 'drop',  '{"ruby":60,"signal_crystal":10,"phase_crystal":5,"phase_scrap":8}',     12, null, 4, null, 800,  1),
  ('cr_jc_modchip_critdmg_legendary', 'jewelcrafter', 'Legendary Crit Damage Mod Chip',   'modchip_critdmg_legendary', 4, 'drop',  '{"sapphire":60,"signal_crystal":10,"phase_crystal":5,"phase_scrap":8}', 12, null, 4, null, 800,  1),
  ('cr_jc_modchip_gold_legendary',    'jewelcrafter', 'Legendary Gold Find Mod Chip',     'modchip_gold_legendary',    4, 'drop',  '{"diamond":60,"signal_crystal":10,"phase_crystal":5,"phase_scrap":8}',  12, null, 4, null, 800,  1),
  ('cr_jc_modchip_dgspeed_legendary', 'jewelcrafter', 'Legendary Dungeon Speed Mod Chip', 'modchip_dgspeed_legendary', 4, 'drop',  '{"sapphire":60,"signal_crystal":10,"phase_crystal":5,"phase_scrap":8}', 12, null, 4, null, 800,  1),
  ('cr_jc_modchip_crit_mythic',       'jewelcrafter', 'Mythic Crit Chance Mod Chip',      'modchip_crit_mythic',       5, 'drop',  '{"ruby":140,"phase_crystal":10,"genesis_crystal":4,"phase_scrap":16}',     16, null, 5, null, 1500, 1),
  ('cr_jc_modchip_critdmg_mythic',    'jewelcrafter', 'Mythic Crit Damage Mod Chip',      'modchip_critdmg_mythic',    5, 'drop',  '{"sapphire":140,"phase_crystal":10,"genesis_crystal":4,"phase_scrap":16}', 16, null, 5, null, 1500, 1),
  ('cr_jc_modchip_gold_mythic',       'jewelcrafter', 'Mythic Gold Find Mod Chip',        'modchip_gold_mythic',       5, 'drop',  '{"diamond":140,"phase_crystal":10,"genesis_crystal":4,"phase_scrap":16}',  16, null, 5, null, 1500, 1),
  ('cr_jc_modchip_dgspeed_mythic',    'jewelcrafter', 'Mythic Dungeon Speed Mod Chip',    'modchip_dgspeed_mythic',    5, 'drop',  '{"sapphire":140,"phase_crystal":10,"genesis_crystal":4,"phase_scrap":16}', 16, null, 5, null, 1500, 1),
  ('cr_ws_chip_extractor_rare',      'weaponsmith', 'Chip Extractor (Rare)',      'chip_extractor_rare',      2, 'known', '{"phase_scrap":50}',                       1,  null, 2, null, 100, 1),
  ('cr_ws_chip_extractor_epic',      'weaponsmith', 'Chip Extractor (Epic)',      'chip_extractor_epic',      3, 'known', '{"phase_scrap":100,"charged_scrap":10}',   8,  null, 3, null, 200, 1),
  ('cr_ws_chip_extractor_legendary', 'weaponsmith', 'Chip Extractor (Legendary)', 'chip_extractor_legendary', 4, 'known', '{"phase_scrap":200,"charged_scrap":20}',   12, null, 4, null, 400, 1),
  ('cr_ws_chip_extractor_mythic',    'weaponsmith', 'Chip Extractor (Mythic)',    'chip_extractor_mythic',    5, 'known', '{"phase_scrap":400,"charged_scrap":40}',   16, null, 5, null, 800, 1)
  on conflict (id) do update set prof = excluded.prof, name = excluded.name, item_key = excluded.item_key, rarity = excluded.rarity,
    source = excluded.source, cost = excluded.cost, lvl = excluded.lvl, rank = excluded.rank, xp = excluded.xp, out_qty = excluded.out_qty;

-- ============================================================================
-- 2. Nya hjalpfunktioner (chipens varden, tak, otursskydd)
-- ============================================================================
/* Raritetens namn i NYCKLAR: spelet skriver 'mythic' i nycklar (charm_mythic), rarity_config.id sager 'mythical'. */
create or replace function public.modchip_rar_key(p_rar integer)
 returns text language sql immutable set search_path to 'public', 'pg_temp'
as $function$ select (array['common','uncommon','rare','epic','legendary','mythic'])[least(5, greatest(0, coalesce(p_rar, 0))) + 1] $function$;

/* Grundvardet for en sort pa ett raritetssteg (Rare 2 .. Mythic 5). */
create or replace function public.modchip_base(p_sort text, p_rar integer)
 returns numeric language sql stable set search_path to 'public', 'pg_temp'
as $function$ select vals[greatest(2, least(5, p_rar)) - 1] from public.modchip_config where sort = p_sort $function$;

/* Chipens saljvarde hos handlaren i koppar: Rare 2 g, Epic 6 g, Legendary 18 g, Mythic 45 g. Salvaged 80 s. */
create or replace function public.modchip_gold(p_key text, p_rar integer)
 returns numeric language sql immutable set search_path to 'public', 'pg_temp'
as $function$ select case when p_key = 'salvaged_modchip' then 8000 else (array[0,0,20000,60000,180000,450000])[least(5, greatest(0, p_rar)) + 1] end $function$;

/* [TILLAGT v5.1358.0] CHIPENS BIDRAG TILL EN EGENSKAP, MED SORTENS TAK. Allt man bar raknas ihop per sort; over taket gor
   chipet ingenting. Spelets vanliga tak (crit_cap 60, dgspeed_cap 25, gold 100) ligger sedan ovanpa i de funktioner som
   redan har dem. Las av gear_bonus - sa allt som laser gear_bonus (pve_crit_of, gold_find_pct, pve_dungeon_start ...) far
   chipen utan att andras. */
create or replace function public.mod_chip_bonus(p_character uuid, p_key text)
 returns numeric language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce((
    select least(c.cap, sum((i.mod_chip->>'v')::numeric))
      from public.items i
      join public.modchip_config c on c.sort = i.mod_chip->>'k'
     where i.character_id = p_character and i.location = 'equipped' and i.mod_chip is not null and c.affix = p_key
     group by c.cap
  ), 0);
$function$;
revoke execute on function public.mod_chip_bonus(uuid, text) from public, anon;
grant execute on function public.mod_chip_bonus(uuid, text) to authenticated;

/* [TILLAGT v5.1358.0] SOCKETRULLNINGEN. Chans per raritet: Rare 1 %, Epic 2 %, Legendary 4 %, Mythic 8 %. Bara de 12 barbara
   platserna (aldrig vaska 10, transport 11, sten 14, chip 15). Aldrig pa tillverkat, aldrig pa handlarens hylla.
   Loot Luck paverkar inte. Dolt otursskydd: socket_pity raknar Epic-eller-battre utan socket; vid 150 (idle_config
   socket_pity) far nasta en socket. Raknaren nollas vid traff. */
create or replace function public.socket_roll(p_character uuid, p_rarity integer, p_slot integer, p_location public.item_location, p_crafted boolean)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ch numeric; v_pity integer; v_hit boolean := false; v_lim integer;
begin
  if coalesce(p_crafted, false) or p_location = 'vendor' or p_slot is null or p_slot in (10, 11, 14, 15) or p_slot > 15 then
    return false;
  end if;
  v_ch := case p_rarity when 2 then 0.01 when 3 then 0.02 when 4 then 0.04 when 5 then 0.08 else 0 end;
  if v_ch <= 0 then return false; end if;
  v_hit := random() < v_ch;
  if p_rarity >= 3 then
    v_lim := coalesce(nullif(public.idle_val('socket_pity'), 0), 150)::integer;
    select socket_pity into v_pity from public.characters where id = p_character;
    if not v_hit and coalesce(v_pity, 0) + 1 >= v_lim then v_hit := true; end if;
    update public.characters set socket_pity = case when v_hit then 0 else coalesce(socket_pity, 0) + 1 end where id = p_character;
  end if;
  return v_hit;
end $function$;
revoke execute on function public.socket_roll(uuid, integer, integer, public.item_location, boolean) from public, anon;
grant execute on function public.socket_roll(uuid, integer, integer, public.item_location, boolean) to authenticated;

/* [TILLAGT v5.1358.0] SKAPAR ETT CHIP-FOREMAL. p_mode: 'craft' = +-5 % runt grundvardet, obundet; 'salvaged' = -5 % (botten),
   bundet; 'fusion' = exakt grundvardet, bundet; 'extract' = p_val (vardet som satt i pjasen), bundet. Chipets egenskap
   ligger i affixes som pa gear ([{"k":"crit","v":1.72}]) sa kortet kan rita den med samma kod. */
create or replace function public.modchip_make(p_character uuid, p_key text, p_rar integer, p_sort text, p_mode text, p_location public.item_location default 'bag', p_val numeric default null)
 returns public.items language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_cfg public.modchip_config; v_base numeric; v_val numeric; v_row public.items;
begin
  select * into v_cfg from public.modchip_config where sort = p_sort;
  if not found then raise exception 'modchip_bad_sort' using errcode='P0001'; end if;
  if not exists (select 1 from public.item_config where key = p_key and slot_idx = 15) then raise exception 'modchip_bad_key' using errcode='P0001'; end if;
  v_base := public.modchip_base(p_sort, p_rar);
  v_val := case p_mode
             when 'craft'    then round((v_base * (0.95 + random() * 0.10))::numeric, 2)   /* random() ar double - cast fore round */
             when 'salvaged' then round(v_base * 0.95, 2)
             when 'extract'  then coalesce(p_val, v_base)
             else v_base end;
  insert into public.items (character_id, item_key, rarity, affixes, hp, gold_value, crafted, location, slot_idx, power, damage, item_level, bound)
  values (p_character, p_key, p_rar, jsonb_build_array(jsonb_build_object('k', v_cfg.affix, 'v', v_val)), 0,
          public.modchip_gold(p_key, p_rar), p_mode = 'craft', p_location, null, 0, 0, 1, p_mode <> 'craft')
  returning * into v_row;
  return v_row;
end $function$;
revoke execute on function public.modchip_make(uuid, text, integer, text, text, public.item_location, numeric) from public, anon;
grant execute on function public.modchip_make(uuid, text, integer, text, text, public.item_location, numeric) to authenticated;

-- ============================================================================
-- 3. Andrade funktioner: gear_bonus, roll_item, trg_loot_announce_item, chat_snapshot_item, can_be_traded
-- ============================================================================
CREATE OR REPLACE FUNCTION public.gear_bonus(p_character uuid, p_key text)
 RETURNS numeric
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select coalesce((
    select sum((e->>'v')::numeric * case when coalesce(ic.two_hand, false) then 1.5 else 1 end)   /* [ANDRAT v5.1188.0] tvahand x1.5 egenskaper (Chris) */
    from public.items i
    left join public.item_config ic on ic.key = i.item_key
    cross join lateral jsonb_array_elements(i.affixes) e
    where i.character_id = p_character and i.location = 'equipped' and e->>'k' = p_key
  ), 0)
  + public.mod_chip_bonus(p_character, p_key)   /* [TILLAGT v5.1358.0] Mod Chips med sortens tak - se mod_chip_bonus */
  + case p_key
      when 'frag'   then public.skill_pct(p_character,'player','p_frag')
                       + public.paragon_pct(p_character,'pg_frag')
      when 'gold'   then public.skill_pct(p_character,'player','p_gold')
                       + public.paragon_pct(p_character,'pg_gold')
                       + public.boost_pct(p_character,'worldsaver')   /* [TILLAGT v5.977.0] bossbuffen */
                       + public.guild_perk_pct(p_character,'gold')   /* [TILLAGT 2026-10-21] guildmal */
      when 'xp'     then public.boost_pct(p_character,'worldsaver')
                       + public.guild_perk_pct(p_character,'xp')   /* [TILLAGT 2026-10-21] guildmal */
      when 'luck'   then public.skill_pct(p_character,'player','p_luck')
      when 'expspd' then public.skill_pct(p_character,'player','p_expspd')
      else 0 end;
$function$
;

CREATE OR REPLACE FUNCTION public.roll_item(p_character uuid, p_item_key text, p_rarity integer, p_cap numeric DEFAULT 1, p_location item_location DEFAULT 'bag'::item_location, p_floor numeric DEFAULT 0, p_crafted boolean DEFAULT NULL::boolean, p_level integer DEFAULT NULL::integer)
 RETURNS items
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_item public.item_config; v_rar public.rarity_config; v_slot public.slot_config;
  v_pick text; v_aff jsonb := '[]'::jsonb; v_cfg public.affix_config;
  v_val numeric; v_i integer; v_hp integer; v_gold numeric; v_row public.items;
  v_cap numeric := greatest(0, least(1, coalesce(p_cap, 1)));
  v_fl  numeric := greatest(0, least(0.9, coalesce(p_floor, 0)));
  v_lvl integer; v_lm numeric; v_power integer; v_dmg integer;
  v_r integer := p_rarity; v_made boolean;
  v_god boolean := false; v_gidx integer; v_ntot integer; v_gk text; v_gcfg public.affix_config;
  v_chance numeric; v_hits integer := 0; v_best numeric;
  v_sock boolean := false;   /* [TILLAGT v5.1358.0] socket pa pjasen */
begin
  if p_level is null then
    raise exception 'roll_item_missing_level' using errcode='P0001', detail = p_item_key;
  end if;
  v_lvl := least(public.lvl_cap(), greatest(1, p_level));

  select * into v_item from public.item_config where key = p_item_key;
  if not found then raise exception 'unknown_item' using errcode='P0001'; end if;
  if v_item.bag_slots is not null and not (v_r = any(v_item.rarities)) then
    v_r := v_item.rarities[1];
  end if;
  select * into v_rar from public.rarity_config where idx = v_r;
  if not found then raise exception 'unknown_rarity' using errcode='P0001'; end if;
  if not (v_r = any(v_item.rarities)) then
    raise exception 'item_not_available_in_rarity' using errcode='P0001';
  end if;
  /* [TILLAGT v5.1358.0] Ett Mod Chip rullas aldrig som gear - det gors av modchip_make. */
  if v_item.slot_idx = 15 then raise exception 'use_modchip_make' using errcode='P0001'; end if;

  v_lm  := public.item_level_mult(v_lvl);
  v_made := coalesce(p_crafted, v_cap < 1);
  v_gold := floor((v_rar.gold_lo + random() * (v_rar.gold_hi - v_rar.gold_lo)) * v_lm / 5.9);

  if v_item.bag_slots is not null then
    insert into public.items (character_id, item_key, rarity, affixes, hp, gold_value,
                              crafted, location, slot_idx, power, damage, item_level)
    values (p_character, p_item_key, v_r, '[]'::jsonb, 0, floor((v_rar.gold_lo + v_rar.gold_hi) / 2.0 * public.item_level_mult(25) / 5.9) /* [ANDRAT v5.959.0] vaskor: fast pris per raritet (Chris) - ingen slump, ingen dold niva */,
            false, p_location, null, 0, 0, v_lvl)
    returning * into v_row;
    return v_row;
  end if;

  select * into v_slot from public.slot_config where idx = v_item.slot_idx;

  if v_item.slot_idx = 11 then
    v_pick := 'travel';
  elsif v_slot.jewel then
    select key into v_pick from public.affix_config where jewel and key <> 'travel' and not crafted_only order by random() limit 1;
  else
    select key into v_pick from public.affix_config where not jewel and key <> 'travel' and not crafted_only order by random() limit 1;
  end if;
  select * into v_cfg from public.affix_config where key = v_pick;
  v_val := (v_cfg.lo + (v_fl + random() * (1 - v_fl)) * (v_cfg.hi - v_cfg.lo) * v_cap) * v_rar.mult;
  v_aff := v_aff || jsonb_build_array(jsonb_build_object('k', v_pick, 'v', round(v_val, 2)));

  v_i := 1;
  while v_i < v_rar.affixes loop
    if v_slot.jewel then
      select key into v_pick from public.affix_config where key <> 'travel' and not crafted_only order by random() limit 1;
    else
      select key into v_pick from public.affix_config where not jewel and key <> 'travel' and not crafted_only order by random() limit 1;
    end if;
    select * into v_cfg from public.affix_config where key = v_pick;
    v_val := (v_cfg.lo + (v_fl + random() * (1 - v_fl)) * (v_cfg.hi - v_cfg.lo) * v_cap) * v_rar.mult;
    v_aff := v_aff || jsonb_build_array(jsonb_build_object('k', v_pick, 'v', round(v_val, 2)));
    v_i := v_i + 1;
  end loop;

  if v_made then
    v_chance := public.god_roll_chance(p_character);
    v_ntot := jsonb_array_length(v_aff);
    v_gidx := 0;
    while v_gidx < v_ntot loop
      if random() < v_chance then
        v_gk := v_aff->v_gidx->>'k';
        select * into v_gcfg from public.affix_config where key = v_gk;
        if found then
          v_god := true; v_hits := v_hits + 1;
          v_aff := jsonb_set(v_aff, array[v_gidx::text, 'v'],
                     to_jsonb(round(v_gcfg.hi * v_rar.mult * 1.20, 2)));
          v_aff := jsonb_set(v_aff, array[v_gidx::text, 'g'], to_jsonb(true));
        end if;
      end if;
      v_gidx := v_gidx + 1;
    end loop;
    if v_hits > 0 then
      perform public.bump_stat(p_character, 'god_rolls', v_hits);
      v_best := public.stat_of(p_character, 'god_roll_best');
      if v_hits > v_best then
        perform public.bump_stat(p_character, 'god_roll_best', v_hits - v_best);
      end if;
    end if;
  end if;

  v_hp    := round(24 * v_rar.mult * v_lm * (0.93 + 0.14 * (v_fl + random() * (1 - v_fl))));
  v_power := round(5  * v_rar.mult * v_lm * (1 + 0.06 * v_fl));
  v_dmg   := case when v_item.slot_idx in (5, 9)
                  then round(12
                       * (case when coalesce(v_item.two_hand, false)
                               then coalesce(public.pve_val('twohand_mult'), 1)
                               else 1 end)
                       * v_rar.mult * v_lm * (1 + 0.06 * v_fl))::integer
                  else 0 end;

  /* [TILLAGT v5.1358.0] SOCKETEN RULLAS FORE INSERT sa trg_loot_announce_item ser den (chattraden 'with a socket'). */
  v_sock := public.socket_roll(p_character, v_r, v_item.slot_idx, p_location, v_made);
  insert into public.items (character_id, item_key, rarity, affixes, hp, gold_value,
                            crafted, location, slot_idx, power, damage, item_level, god_roll, mod_socket)
  values (p_character, p_item_key, v_r, v_aff, v_hp, v_gold,
          v_made, p_location, null, v_power, v_dmg, v_lvl, v_god, v_sock)
  returning * into v_row;
  return v_row;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_loot_announce_item()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
/* [TILLAGT v5.845.0] LEGENDARY OCH MYTHIC ANNONSERAS I CHATTEN (Chris 2026-10-17). En ny pjas med raritet 4-5
   som hamnar hos en spelare (vaska, burna, post) blir en rad i General med pjasen lankad, sa alla kan se den.
   Handlarens lager och adelstenar raknas inte. Ett fel har far aldrig stoppa bytet. sender_tag LOOT = spelets markering. */
begin
  /* [ANDRAT v5.864.0] Tillverkat annonseras av craft_gear_make nar egenskaperna ar satta. */
  /* [ANDRAT v5.1358.0] Chips (plats 15) annonseras aldrig - ett tillverkat Epic-chip ar inget fynd. */
  if new.rarity >= 3 and new.location in ('bag','equipped','mail') and new.gem_region is null
     and coalesce(current_setting('genesis.crafting', true), '') <> 'on'
     and not exists (select 1 from public.item_config ic where ic.key = new.item_key and ic.slot_idx = 15) then
    begin
      insert into public.chat_messages (channel, shard, sender_profile, sender_char, sender_name, sender_tag, sender_handle, body, attach)
      select 'general', coalesce((select val from public.chat_config where key = 'shard'), 'main'), c.profile_id, c.id, c.name, 'LOOT',
             (select p.handle from public.profiles p where p.id = c.profile_id),
             /* [ANDRAT v5.1358.0] Legendary/Mythic MED socket sags i raden (Chris). Epic med socket far bara glimten pa kortet. */
             'found ' || case when new.rarity >= 5 then 'a Mythic' when new.rarity = 4 then 'a Legendary' else 'an Epic' end
                      || case when new.mod_socket and new.rarity >= 4 then ' item with a socket: [[item]]!' else ' item: [[item]]!' end,
             jsonb_build_array(jsonb_build_object('kind','gear','key',new.item_key,'rarity',new.rarity,'lvl',new.item_level,
               'slot',new.slot_idx,'hp',new.hp,'power',new.power,'damage',new.damage,'affixes',coalesce(new.affixes,'[]'::jsonb),
               'pve',new.pve_effect,'socket',new.socket_kind,'tune',new.tune_count,'crafted',new.crafted,
               'mod_socket',new.mod_socket,'mod_chip',new.mod_chip))
        from public.characters c where c.id = new.character_id and c.deleted_at is null;
    exception when others then null;
    end;
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.chat_snapshot_item(p_character uuid, p_item uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v public.items;
begin
  select * into v from public.items where id = p_item and character_id = p_character
    and location in ('bag','equipped','vault','sheet');   /* [ANDRAT 2026-10-24] lanka fran valvet och setlistan (Chris, Nightmare1) */
  if not found then raise exception 'link_item_not_owned' using errcode='P0001'; end if;
  return jsonb_build_object('kind','gear','key',v.item_key,'rarity',v.rarity,'lvl',v.item_level,
    'slot',v.slot_idx,'hp',v.hp,'power',v.power,'damage',v.damage,'affixes',coalesce(v.affixes,'[]'::jsonb),
    'pve',v.pve_effect,'socket',v.socket_kind,'tune',v.tune_count,'crafted',v.crafted,'charmed',v.charmed,'apex',v.apex,'skin',v.skin,
    'mod_socket',v.mod_socket,'mod_chip',v.mod_chip,   /* [TILLAGT v5.1358.0] socket och chip foljer med i chattlanken */
    'gem',v.gem_region,'gem_pct',v.gem_pct,'gem_good',v.gem_good,'gold',v.gold_value,'god',v.god_roll);
end $function$;

CREATE OR REPLACE FUNCTION public.can_be_traded(p_item uuid DEFAULT NULL::uuid, p_stack_key text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
/* EN kalla for auktion, post och byteshandel. [ANDRAT v5.1358.0] Tre nya regler:
   - en BUNDEN pjas (borrad, Salvaged chip, uttaget/fusionerat chip) ar Bind on Pickup;
   - en pjas med ett ISATT chip kan inte lamna kontot forran chipet ar uttaget (chip_inserted);
   - en bunden stapelvara (Socket Drill, stack_item_config.bop) ar ocksa Bind on Pickup. */
declare v_it public.items;
begin
  if p_stack_key is not null then
    if exists (select 1 from public.stack_item_config s
                where s.key = p_stack_key and coalesce(s.sell,0) = 0)
       or exists (select 1 from public.shard_config where key = p_stack_key) then
      raise exception 'cannot_be_listed' using errcode='P0001';
    end if;
    if coalesce((select bop from public.material_config where key = p_stack_key), false)
       or coalesce((select bop from public.stack_item_config where key = p_stack_key), false) then
      raise exception 'bind_on_pickup' using errcode='P0001';
    end if;
  end if;
  if p_item is not null then
    select * into v_it from public.items where id = p_item;
    if v_it.gem_region is not null or coalesce(v_it.bound, false) then
      raise exception 'bind_on_pickup' using errcode='P0001';
    end if;
    if v_it.mod_chip is not null then
      raise exception 'chip_inserted' using errcode='P0001';
    end if;
  end if;
end;
$function$;

-- ============================================================================
-- 4. Sparrar: sell_item, salvage_item, equip_item, tune_item, charm_apply, transmog_apply, buyback_take
-- ============================================================================
CREATE OR REPLACE FUNCTION public.sell_item(p_character uuid, p_item uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_it public.items; v_ch public.characters; v_gold numeric;
begin
  perform public.owned_character(p_character);
  select * into v_it from public.items
  where id = p_item and character_id = p_character for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  if v_it.favorite then raise exception 'item_favorite' using errcode='P0001'; end if;   /* [TILLAGT v5.1213.0] favoritstjarnan skyddar (Chris) */
  /* [TILLAGT v5.1358.0] En pjas med isatt chip saljs/skrotas inte forran chipet ar uttaget (Chris). */
  if v_it.mod_chip is not null then raise exception 'chip_inserted' using errcode='P0001'; end if;
  /* [TILLAGT] Den isatta stenen ar inte till salu - ta ur den forst. */
  if v_it.gem_region is not null and v_it.location = 'equipped' then
    raise exception 'gem_is_equipped' using errcode='P0001';
  end if;
  if v_it.socket_kind is not null then raise exception 'item_in_bag_socket' using errcode='P0001'; end if;
  if v_it.sheet_id is not null or v_it.location = 'sheet' then raise exception 'item_on_sheet' using errcode='P0001'; end if;   /* [TILLAGT gren loadout-sheets] */   /* [TILLAGT v5.802.0] */
  if v_it.location not in ('bag','equipped') then
    raise exception 'item_not_sellable_here' using errcode='P0001';
  end if;

  /* [ANDRAT] Saljbonusen gäller INTE pjaser man kopt av en handlare - annars
     var handlaren en penningpress for den som samlat pa sig bonusen. */
  v_gold := floor(v_it.gold_value * (case when v_it.from_vendor then 1
    else (1 + public.helper_bonus(p_character,'sellvalue') / 100) end));

  perform public.buyback_push(p_character, 'item', v_gold, v_it.item_key, v_it.rarity, 1,
    to_jsonb(v_it) - 'id' - 'character_id' - 'created_at' - 'location' - 'slot_idx'
      - 'socket_kind' - 'socket_idx');
  delete from public.items where id = v_it.id;

  v_ch := public.apply_currency(p_character, 'sell', v_gold, 0, 0, 0,
    jsonb_build_object('item_key', v_it.item_key, 'rarity', v_it.rarity,
                       'base', v_it.gold_value, 'from_vendor', v_it.from_vendor));

  perform public.bump_stat(p_character, 'gear_sold', 1);
  return json_build_object('sold', v_it.item_key, 'gold', v_gold,
    'gold_total', v_ch.gold_copper, 'version', v_ch.save_version);
end $function$
;

CREATE OR REPLACE FUNCTION public.salvage_item(p_character uuid, p_item uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_it public.items; v_prof text; v_qty numeric; v_pct numeric; v_xp numeric := 0; v_slot integer; v_row public.characters;
begin
  perform public.owned_character(p_character);
  select * into v_it from public.items where id = p_item and character_id = p_character for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  if v_it.favorite then raise exception 'item_favorite' using errcode='P0001'; end if;   /* [TILLAGT v5.1213.0] */
  /* [TILLAGT v5.1358.0] En pjas med isatt chip saljs/skrotas inte forran chipet ar uttaget (Chris). */
  if v_it.mod_chip is not null then raise exception 'chip_inserted' using errcode='P0001'; end if;
  /* [TILLAGT v5.1358.0] Ett Mod Chip (plats 15) ar inte gear: det satts i en socket, aldrig pa kroppen. */
  if exists (select 1 from public.item_config ic where ic.key = v_it.item_key and ic.slot_idx = 15) then raise exception 'chip_not_gear' using errcode='P0001'; end if;
  if v_it.location <> 'bag' then raise exception 'item_not_in_bag' using errcode='P0001'; end if;
  /* [TILLAGT v5.832.0] En vaska som sitter i en vaskplats gar inte att skrota (buggsvep 14) - ryggsacken
     krympte under det den holl. Samma regel som salj, auktion och post. */
  if v_it.socket_kind is not null then raise exception 'item_socketed' using errcode='P0001'; end if;
  /* Yrket ur SORTENS plats (items.slot_idx ar tom i vaskan). */
  select slot_idx into v_slot from public.item_config where key = v_it.item_key;
  v_prof := case when v_slot in (6,8,12,13) then 'jewelcrafter' when v_slot in (5,9,11) then 'weaponsmith' else 'outfitter' end;
  v_qty := (array[1,2,3,4,6,9])[v_it.rarity + 1];
  v_pct := public.skill_pct(p_character, v_prof, 'recycle') + public.gem_pct(p_character, 'recycle_yield');   /* [ANDRAT 2026-10-21] gem: Recycle yield */
  v_qty := greatest(1, round(v_qty * (1 + v_pct / 100)));
  v_row := public.apply_currency(p_character, 'salvage', 0, 0, v_qty::integer);
  if exists (select 1 from public.character_professions where character_id = p_character and prof = v_prof) then
    v_xp := 3 + v_it.rarity * 2;
    update public.character_professions set xp = xp + v_xp * (1 + public.skill_pct(p_character,'player','p_prof_xp') / 100.0)
      where character_id = p_character and prof = v_prof;
  end if;
  delete from public.items where id = p_item;
  perform public.bump_stat(p_character, 'salvaged', 1);
  update public.characters set save_version = save_version + 1 where id = p_character;
  return json_build_object('frags', v_qty, 'fragments', v_row.fragments, 'prof', v_prof, 'xp', round(v_xp));
end; $function$
;

CREATE OR REPLACE FUNCTION public.equip_item(p_character uuid, p_item uuid, p_slot integer DEFAULT NULL::integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_it public.items; v_slots integer[]; v_dest integer; v_old public.items; v_lvl integer;
        v_2h boolean; v_wep public.items; v_pushed uuid := null;
begin
  perform public.owned_character(p_character);
  select * into v_it from public.items
  where id = p_item and character_id = p_character for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  /* [TILLAGT v5.1358.0] Ett Mod Chip (plats 15) ar inte gear: det satts i en socket, aldrig pa kroppen. */
  if exists (select 1 from public.item_config ic where ic.key = v_it.item_key and ic.slot_idx = 15) then raise exception 'chip_not_gear' using errcode='P0001'; end if;
  if v_it.location <> 'bag' then raise exception 'item_not_in_bag' using errcode='P0001'; end if;

  select public.character_level(xp) into v_lvl from public.characters where id = p_character;
  if public.item_req_level(v_it.item_level, v_it.base_level, v_it.charmed, v_it.apex) > coalesce(v_lvl, 1) then   /* [ANDRAT tyst 2026-10-23] ramverket: kravet fran grundnivan */   /* [ANDRAT v5.876.0] Apex 60 bars pa niva 50 */
    raise exception 'level_too_low_for_item' using errcode='P0001',
      detail = v_it.item_level::text;
  end if;

  /* [TILLAGT] Stenplatsen har en egen vag in, med dygnets karens. Den far
     inte gа att na harifran. */
  if v_it.gem_region is not null then
    raise exception 'use_gem_slot' using errcode='P0001';
  end if;
  v_slots := public.allowed_slots(v_it.item_key);
  if p_slot is not null and p_slot = any(v_slots) then
    v_dest := p_slot;
  else
    select s into v_dest from unnest(v_slots) s
    where not exists (select 1 from public.items i
                      where i.character_id = p_character and i.location='equipped' and i.slot_idx = s)
    limit 1;
    v_dest := coalesce(v_dest, v_slots[1]);
  end if;

  select two_hand into v_2h from public.item_config where key = v_it.item_key;

  -- ANDRA HANDEN AR LAST sa lange ett tvahandsvapen sitter pa.
  if v_dest = 9 then
    select i.* into v_wep from public.items i
      join public.item_config c on c.key = i.item_key
     where i.character_id = p_character and i.location='equipped' and i.slot_idx = 5 and c.two_hand;
    if found then raise exception 'both_hands_in_use' using errcode='P0001'; end if;
  end if;

  select * into v_old from public.items
  where character_id = p_character and location='equipped' and slot_idx = v_dest for update;
  if found then
    update public.items set location='bag', slot_idx=null where id = v_old.id;
  end if;

  -- TVAHANDSVAPNET KNUFFAR UT andra handen, till vaskan och aldrig bort.
  if v_dest = 5 and coalesce(v_2h,false) then
    select * into v_wep from public.items
     where character_id = p_character and location='equipped' and slot_idx = 9 for update;
    if found then
      update public.items set location='bag', slot_idx=null where id = v_wep.id;
      v_pushed := v_wep.id;
    end if;
  end if;

  update public.items set location='equipped', slot_idx=v_dest where id = v_it.id;
  update public.characters set save_version = save_version + 1, last_seen_at = now()
  where id = p_character;

  perform public.bump_stat(p_character,'gear_equipped',1);
  if v_dest = 11 then perform public.bump_stat(p_character,'transport_equipped',1); end if;
  if v_dest = 10 then perform public.bump_stat(p_character,'bags_fitted',1); end if;

  perform public.expedition_resync(p_character);
  /* [TILLAGT v5.802.0] Aldrig fler saker an platser efter ett byte (buggsvep 10). */
  if public.bag_used(p_character) > public.bag_slots(p_character) then raise exception 'backpack_full' using errcode='P0001'; end if;
  return json_build_object('item', v_it.id, 'slot', v_dest,
    'swapped_out', case when v_old.id is not null then v_old.id else null end,
    'offhand_pushed', v_pushed);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.tune_item(p_character uuid, p_item uuid, p_idx integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_it public.items; v_ch public.characters; v_cfg public.affix_config;
  v_rar public.rarity_config; v_key text; v_old numeric; v_new numeric;
  v_price numeric; v_lvl integer; v_aff jsonb;
begin
  v_ch := public.owned_character(p_character);

  select public.character_level(xp) into v_lvl from public.characters where id = p_character;
  if coalesce(v_lvl,1) < 25 then raise exception 'tuning_locked' using errcode='P0001'; end if;

  select * into v_it from public.items where id = p_item and character_id = p_character for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  /* [TILLAGT v5.1358.0] Ett Mod Chip (plats 15) ar inte gear: det satts i en socket, aldrig pa kroppen. */
  if exists (select 1 from public.item_config ic where ic.key = v_it.item_key and ic.slot_idx = 15) then raise exception 'chip_not_gear' using errcode='P0001'; end if;
  if v_it.location not in ('bag','equipped') then
    raise exception 'item_must_be_in_bag' using errcode='P0001';
  end if;
  /* [BORTTAGET 2026-10-21] Inget tak langre (Chris): priset stiger 1,75x per forsok och tar stopp av sig sjalvt. */   /* [ANDRAT 2026-10-20] 5 -> 25, priset stiger 1,75x per forsok (guldsanka, Chris) */

  v_aff := v_it.affixes;
  if p_idx is null or p_idx < 0 or p_idx >= jsonb_array_length(v_aff) then
    raise exception 'no_such_affix' using errcode='P0001';
  end if;

  v_key := v_aff -> p_idx ->> 'k';
  v_old := (v_aff -> p_idx ->> 'v')::numeric;
  /* [TILLAGT v5.1087.0] EN GOD ROLL GAR INTE ATT REROLLA (Chris): den ligger over taket, en reroll kan bara bli samre. */
  if coalesce((v_aff -> p_idx ->> 'g')::boolean, false) then raise exception 'god_roll_locked' using errcode='P0001'; end if;
  select * into v_cfg from public.affix_config where key = v_key;
  if not found then raise exception 'unknown_affix' using errcode='P0001'; end if;
  select * into v_rar from public.rarity_config where idx = v_it.rarity;

  v_price := public.tune_price(v_it.rarity, v_it.tune_count);
  if v_ch.gold_copper < v_price then raise exception 'insufficient_gold' using errcode='P0001'; end if;

  -- [BUGG] round(double precision, 2) FINNS INTE i Postgres. random() ger
  -- double precision, sa hela uttrycket blev det, och funktionen foll pa sista
  -- raden innan den hann gora nagot. Tuning kunde alltsa aldrig lyckas.
  -- Uttrycket gors om till numeric FORE avrundningen.
  --
  -- Den gamla raden hade ocksa "case when v_it.crafted then 1.0 else 1.0 end" -
  -- en faktor som var 1 i bada fallen och alltsa inte gjorde nagot. Den var
  -- kvar fran tiden da craftat gear rullade nedre halvan av bandet; det
  -- straffet togs bort i v4.31.0. Ett dott tal som ser levande ut ar en falla,
  -- sa det ar borta. Regeln ar och forblir: tuning rullar HELA bandet, samma
  -- band som pjasen fods i, och kan aldrig ga forbi taket.
  v_new := round(((v_cfg.lo + random() * (v_cfg.hi - v_cfg.lo)) * v_rar.mult)::numeric, 2);

  v_ch := public.apply_currency(p_character, 'gear_tune', -v_price, 0, 0, 0,
            jsonb_build_object('item', p_item, 'affix', v_key,
                               'old', v_old, 'new', v_new, 'attempt', v_it.tune_count + 1));

  update public.items
  set tune_prev  = v_aff,
      tune_count = tune_count + 1,
      affixes    = jsonb_set(v_aff, array[p_idx::text], ((v_aff->p_idx) - 'g') || jsonb_build_object('v', v_new)),
      /* [ANDRAT v5.779.0] Stjarnan foljer egenskapen: en justerad gudarulle ar ingen gudarulle. */
      god_roll   = exists (select 1 from jsonb_array_elements(v_aff) with ordinality e(a, i)
                           where i - 1 <> p_idx and coalesce((e.a->>'g')::boolean, false))
  where id = p_item
  returning * into v_it;
  perform public.bump_stat(p_character, 'tunes', 1);   /* [TILLAGT 2026-10-21] raknare for bragder */

  return json_build_object('item', p_item, 'affix', v_key, 'old', v_old, 'new', v_new,
    'attempt', v_it.tune_count, 'left', null, 'paid', v_price,   /* [ANDRAT v5.1200.0] inget tak sedan 2026-10-21 - inga forsok kvar att visa (Chris) */
    'next_price', public.tune_price(v_it.rarity, v_it.tune_count),
    'gold', v_ch.gold_copper, 'version', v_ch.save_version);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.charm_apply(p_character uuid, p_item uuid, p_key text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
/* Spelaren satter charmen pa en pjas i vaskan eller pa kroppen. Raritet maste matcha, en gang per pjas. */
declare v_it public.items; v_ic public.item_config; v_old integer; v_new integer; v_ratio numeric; v_need integer;
begin
  perform public.owned_character(p_character);
  select * into v_it from public.items
   where id = p_item and character_id = p_character and location in ('bag', 'equipped') for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  select * into v_ic from public.item_config where key = v_it.item_key;
  if v_it.gem_region is not null or v_ic.bag_slots is not null or v_ic.slot_idx = 15 then   /* [ANDRAT v5.1358.0] inte pa ett Mod Chip */
    raise exception 'charm_not_gear' using errcode='P0001';
  end if;
  v_old := least(public.lvl_cap() + 10, greatest(1, coalesce(v_it.item_level, 1)));   /* [ANDRAT tyst 2026-10-24] nivatak + 10 (Balans 2) */
  if p_key = 'apex_charm' then
    if v_it.apex then raise exception 'charm_already_apex' using errcode='P0001'; end if;
    if v_old <> 50 then raise exception 'charm_needs_level_50' using errcode='P0001'; end if;
    v_new := public.lvl_cap() + 10;
  else
    v_need := case p_key when 'charm_epic' then 3 when 'charm_legendary' then 4 when 'charm_mythic' then 5 end;
    if v_need is null then raise exception 'not_a_charm' using errcode='P0001'; end if;
    if v_it.rarity < 3 then raise exception 'charm_needs_epic' using errcode='P0001'; end if;
    if v_it.rarity > v_need then raise exception 'charm_rarity_mismatch' using errcode='P0001'; end if;   /* [ANDRAT 2026-10-20] lagre raritet ar ok (Chris) */
    if v_it.charmed then raise exception 'charm_already_used' using errcode='P0001'; end if;
    /* [ANDRAT v5.976.0] CHARMERNA GAR TILL 60 (Chris alt A 2026-10-20): +10 nivaer, aldrig over 60. Apex delas inte ut langre. */
    if v_old >= public.lvl_cap() + 10 then raise exception 'charm_item_at_max' using errcode='P0001'; end if;
    v_new := least(public.lvl_cap() + 10, v_old + 10);
  end if;
  if not public.take_stack(p_character, p_key, 1, null) then
    raise exception 'not_enough_items' using errcode='P0001';
  end if;
  v_ratio := public.item_level_mult(v_new) / public.item_level_mult(v_old);
  update public.items
     set item_level = v_new,
         hp = round(hp * v_ratio)::integer,
         power = round(power * v_ratio)::integer,
         damage = round(damage * v_ratio)::integer,
         gold_value = floor(gold_value * v_ratio),
         charmed = charmed or (p_key <> 'apex_charm'),
         apex = apex or (p_key = 'apex_charm'),
         base_level = coalesce(base_level, public.item_base_level(item_level, base_level, charmed, apex))   /* [TILLAGT tyst 2026-10-23] ramverket */
   where id = v_it.id returning * into v_it;
  update public.characters set save_version = save_version + 1, last_seen_at = now() where id = p_character;
  perform public.bump_stat(p_character, 'charms_used', 1);
  if v_it.location = 'equipped' then perform public.expedition_resync(p_character); end if;
  return json_build_object('item', v_it.id, 'key', p_key, 'old_level', v_old, 'new_level', v_new,
    'hp', v_it.hp, 'power', v_it.power, 'damage', v_it.damage, 'gold_value', v_it.gold_value,
    'charmed', v_it.charmed, 'apex', v_it.apex);
end $function$
;

CREATE OR REPLACE FUNCTION public.transmog_apply(p_character uuid, p_item uuid, p_skin text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_it public.items; v_ic public.item_config; v_sc public.item_config;
begin
  perform public.owned_character(p_character);
  select * into v_it from public.items where id = p_item and character_id = p_character and location in ('bag','equipped') for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  select * into v_ic from public.item_config where key = v_it.item_key;
  if v_ic.bag_slots is not null or v_it.gem_region is not null or v_ic.slot_idx is null or v_ic.slot_idx = 15 then raise exception 'transmog_not_gear' using errcode='P0001'; end if;   /* [ANDRAT v5.1358.0] inte pa ett Mod Chip */
  if p_skin is not null then
    select * into v_sc from public.item_config where key = p_skin;
    if not found or v_sc.bag_slots is not null or v_sc.slot_idx is distinct from v_ic.slot_idx then raise exception 'transmog_wrong_slot' using errcode='P0001'; end if;
    if not exists (select 1 from public.character_appearances where character_id = p_character and item_key = p_skin) then raise exception 'transmog_not_unlocked' using errcode='P0001'; end if;
  end if;
  update public.items set skin = case when p_skin = v_it.item_key then null else p_skin end where id = v_it.id returning * into v_it;
  update public.characters set save_version = save_version + 1 where id = p_character;
  return json_build_object('item', v_it.id, 'skin', v_it.skin);
end $function$;

CREATE OR REPLACE FUNCTION public.buyback_take(p_character uuid, p_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_b public.buyback; v_ch public.characters; v_new uuid; v_kind text;
begin
  perform public.owned_character(p_character);
  perform set_config('genesis.nogather', 'on', true);   /* [TILLAGT v5.779.0] inget har ar samlat */
  select * into v_b from public.buyback
  where id = p_id and character_id = p_character and taken_at is null for update;
  if not found then raise exception 'buyback_gone' using errcode='P0001'; end if;
  if v_b.sold_at < now() - public.buyback_ttl() then
    raise exception 'buyback_expired' using errcode='P0001';
  end if;

  select * into v_ch from public.characters where id = p_character;
  if v_ch.gold_copper < v_b.price then
    raise exception 'not_enough_gold' using errcode='P0001';
  end if;

  if v_b.kind = 'item' then
    perform public.assert_bag_space(p_character, 1);
    insert into public.items (character_id, item_key, rarity, affixes, hp, gold_value, crafted,
                              location, power, damage, item_level, pve_effect, tune_count, tune_prev,
                              from_vendor, gem_region, gem_pct, gem_good, god_roll, base_level, charmed, apex,
                              mod_socket, mod_chip, bound)   /* [TILLAGT v5.1358.0] socket, chip och bindning foljer med vid aterkop */
    select p_character, v_b.item_key, v_b.rarity,
           (v_b.snapshot->'affixes'),
           (v_b.snapshot->>'hp')::integer,
           (v_b.snapshot->>'gold_value')::numeric,
           coalesce((v_b.snapshot->>'crafted')::boolean, false),
           'bag',
           (v_b.snapshot->>'power')::integer,
           (v_b.snapshot->>'damage')::integer,
           (v_b.snapshot->>'item_level')::integer,
           nullif(v_b.snapshot->'pve_effect', 'null'::jsonb),
           coalesce((v_b.snapshot->>'tune_count')::integer, 0),
           nullif(v_b.snapshot->'tune_prev', 'null'::jsonb),
           /* [TILLAGT v5.773.0] De fem flaggorna tappades: en bunden adelsten blev obunden och kunde
              saljas pa auktionshuset, gudarullen forsvann och handlarpjasen fick hjalparbonus igen. */
           coalesce((v_b.snapshot->>'from_vendor')::boolean, false),
           v_b.snapshot->>'gem_region',
           (v_b.snapshot->>'gem_pct')::numeric,
           coalesce((v_b.snapshot->>'gem_good')::boolean, false),
           coalesce((v_b.snapshot->>'god_roll')::boolean, false),
           /* [TILLAGT tyst 2026-10-23] grundniva + charm-flaggorna foljer med */
           public.item_base_level((v_b.snapshot->>'item_level')::integer, (v_b.snapshot->>'base_level')::integer, coalesce((v_b.snapshot->>'charmed')::boolean, false), coalesce((v_b.snapshot->>'apex')::boolean, false)),
           coalesce((v_b.snapshot->>'charmed')::boolean, false),
           coalesce((v_b.snapshot->>'apex')::boolean, false),
           coalesce((v_b.snapshot->>'mod_socket')::boolean, false),
           nullif(v_b.snapshot->'mod_chip', 'null'::jsonb),
           coalesce((v_b.snapshot->>'bound')::boolean, false)
    returning id into v_new;
  else
    v_kind := coalesce(v_b.snapshot->>'kind', 'material');
    /* [TILLAGT v5.779.0] Ny stapel tar en plats i vaskan, som i vault_stack_take. */
    if public.stack_needs_slot(p_character, v_b.item_key, v_b.rarity) then   /* [ANDRAT v5.812.0] samma regel overallt */
      perform public.assert_bag_space(p_character, 1);
    end if;
    perform public.add_stack(p_character, v_b.item_key, v_kind, v_b.qty, v_b.rarity);
  end if;

  v_ch := public.apply_currency(p_character, 'buy', -v_b.price, 0, 0, 0,
            jsonb_build_object('kind','buyback','key',v_b.item_key,'qty',v_b.qty));
  update public.buyback set taken_at = now() where id = v_b.id;
  return json_build_object('bought', v_b.item_key, 'qty', v_b.qty, 'price', v_b.price,
    'item', v_new, 'gold', v_ch.gold_copper, 'version', v_ch.save_version);
end $function$;

-- ============================================================================
-- 5. Spelarens handlingar (RPC fran klienten)
-- ============================================================================
/* [TILLAGT v5.1358.0] SOCKET DRILL. Borren (kops i World Boss-butiken for Boss Marks, bunden) gor en socket i en pjas av Rare
   eller battre som saknar socket. Misslyckas aldrig. Pjasen blir bunden (Bind on Pickup). Bara de 12 barbara platserna. */
create or replace function public.socket_drill_use(p_character uuid, p_item uuid)
 returns json language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_it public.items; v_ic public.item_config;
begin
  perform public.owned_character(p_character);
  select * into v_it from public.items where id = p_item and character_id = p_character and location in ('bag','equipped') for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  select * into v_ic from public.item_config where key = v_it.item_key;
  if v_ic.bag_slots is not null or v_it.gem_region is not null or v_ic.slot_idx is null or v_ic.slot_idx in (10, 11, 14, 15) then
    raise exception 'drill_not_gear' using errcode='P0001';
  end if;
  if v_it.rarity < 2 then raise exception 'drill_needs_rare' using errcode='P0001'; end if;
  if v_it.mod_socket then raise exception 'already_has_socket' using errcode='P0001'; end if;
  if not public.take_stack(p_character, 'socket_drill', 1, null) then
    raise exception 'not_enough_items' using errcode='P0001';
  end if;
  update public.items set mod_socket = true, bound = true where id = v_it.id returning * into v_it;
  update public.characters set save_version = save_version + 1, last_seen_at = now() where id = p_character;
  perform public.bump_stat(p_character, 'sockets_drilled', 1);
  return json_build_object('item', v_it.id, 'key', v_it.item_key, 'rarity', v_it.rarity, 'mod_socket', true, 'bound', true);
end $function$;
revoke execute on function public.socket_drill_use(uuid, uuid) from public, anon;
grant execute on function public.socket_drill_use(uuid, uuid) to authenticated;

/* [TILLAGT v5.1358.0] SATT I ETT CHIP. Gratis. Pjasen maste ha en tom socket, chipet ligga i vaskan, och chipets raritet far inte
   vara hogre an pjasens. Chipet forsvinner som foremal och bor i items.mod_chip pa pjasen tills det tas ut
   ({"key","k","v","r","salv"}). Ett isatt chip ar bundet - det kommer tillbaka bundet vid uttag. */
create or replace function public.modchip_insert(p_character uuid, p_item uuid, p_chip uuid)
 returns json language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_it public.items; v_ic public.item_config; v_ch public.items; v_cc public.item_config; v_sort text; v_val numeric;
begin
  perform public.owned_character(p_character);
  select * into v_it from public.items where id = p_item and character_id = p_character and location in ('bag','equipped') for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  select * into v_ic from public.item_config where key = v_it.item_key;
  if v_ic.bag_slots is not null or v_it.gem_region is not null or v_ic.slot_idx is null or v_ic.slot_idx in (10, 11, 14, 15) then
    raise exception 'drill_not_gear' using errcode='P0001';
  end if;
  if not v_it.mod_socket then raise exception 'no_socket' using errcode='P0001'; end if;
  if v_it.mod_chip is not null then raise exception 'socket_full' using errcode='P0001'; end if;
  select * into v_ch from public.items where id = p_chip and character_id = p_character and location = 'bag' for update;
  if not found then raise exception 'chip_not_found' using errcode='P0001'; end if;
  select * into v_cc from public.item_config where key = v_ch.item_key;
  if v_cc.slot_idx is distinct from 15 then raise exception 'not_a_modchip' using errcode='P0001'; end if;
  if v_ch.rarity > v_it.rarity then raise exception 'chip_rarity_too_high' using errcode='P0001'; end if;
  select c.sort into v_sort from public.modchip_config c where c.affix = v_ch.affixes->0->>'k';
  v_val := (v_ch.affixes->0->>'v')::numeric;
  if v_sort is null or v_val is null then raise exception 'not_a_modchip' using errcode='P0001'; end if;
  update public.items
     set mod_chip = jsonb_build_object('key', v_ch.item_key, 'k', v_sort, 'v', v_val, 'r', v_ch.rarity, 'salv', v_ch.item_key = 'salvaged_modchip')
   where id = v_it.id returning * into v_it;
  delete from public.items where id = v_ch.id;
  update public.characters set save_version = save_version + 1, last_seen_at = now() where id = p_character;
  perform public.bump_stat(p_character, 'chips_inserted', 1);
  if v_it.location = 'equipped' then perform public.expedition_resync(p_character); end if;
  return json_build_object('item', v_it.id, 'mod_chip', v_it.mod_chip);
end $function$;
revoke execute on function public.modchip_insert(uuid, uuid, uuid) from public, anon;
grant execute on function public.modchip_insert(uuid, uuid, uuid) to authenticated;

/* [TILLAGT v5.1358.0] TA UT ETT CHIP. Kraver en Chip Extractor (Weaponsmith) av chipets raritet eller hogre - den lagsta som
   racker forbrukas. Chipet kommer tillbaka som ett BUNDET foremal i vaskan med samma varde. Behover en ledig vaskplats.
   Chips forstors aldrig. */
create or replace function public.modchip_extract(p_character uuid, p_item uuid)
 returns json language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_it public.items; v_r integer; v_er integer; v_used text := null; v_new public.items; v_have integer;
begin
  perform public.owned_character(p_character);
  select * into v_it from public.items where id = p_item and character_id = p_character and location in ('bag','equipped') for update;
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  if v_it.mod_chip is null then raise exception 'no_chip' using errcode='P0001'; end if;
  v_r := greatest(2, least(5, (v_it.mod_chip->>'r')::integer));
  /* Finns en extraktor som racker? Kollas FORE vaskplatsen sa ingen extraktor forbrukas i onodan. */
  for v_er in v_r..5 loop
    select qty into v_have from public.stacks where character_id = p_character and stack_key = 'chip_extractor_' || public.modchip_rar_key(v_er) limit 1;
    if coalesce(v_have, 0) > 0 then v_used := 'chip_extractor_' || public.modchip_rar_key(v_er); exit; end if;
  end loop;
  if v_used is null then raise exception 'needs_chip_extractor' using errcode='P0001', detail = public.modchip_rar_key(v_r); end if;
  perform public.assert_bag_space(p_character, 1);
  if not public.take_stack(p_character, v_used, 1, null) then raise exception 'needs_chip_extractor' using errcode='P0001', detail = public.modchip_rar_key(v_r); end if;
  v_new := public.modchip_make(p_character, v_it.mod_chip->>'key', v_r, v_it.mod_chip->>'k', 'extract', 'bag', (v_it.mod_chip->>'v')::numeric);
  update public.items set mod_chip = null where id = v_it.id;
  update public.characters set save_version = save_version + 1, last_seen_at = now() where id = p_character;
  perform public.bump_stat(p_character, 'chips_extracted', 1);
  if v_it.location = 'equipped' then perform public.expedition_resync(p_character); end if;
  return json_build_object('item', v_it.id, 'chip', v_new.id, 'chip_key', v_new.item_key, 'used', v_used);
end $function$;
revoke execute on function public.modchip_extract(uuid, uuid) from public, anon;
grant execute on function public.modchip_extract(uuid, uuid) to authenticated;

/* [TILLAGT v5.1358.0] CHIP FUSION HOS HANDLAREN (alla spelare): tre Salvaged Mod Chips -> ett Epic-chip av valfri sort bland de tre,
   mot guld (idle_config chip_fusion_gold, koppar; 250000 = 25 guld). Man maste sta hos handlaren (som vendor_buy_stack).
   De tre aldsta Salvaged i vaskan tas. Resultatet ar bundet och har exakt Epic-grundvardet. */
create or replace function public.modchip_fusion(p_character uuid, p_region text, p_sort text)
 returns json language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ch public.characters; v_gold numeric; v_ids uuid[]; v_sorts text[]; v_new public.items;
begin
  v_ch := public.owned_character(p_character);
  if v_ch.region <> p_region then raise exception 'not_at_this_vendor' using errcode='P0001'; end if;
  if v_ch.travel_ends is not null and v_ch.travel_ends > now() then raise exception 'still_travelling' using errcode='P0001'; end if;
  if not exists (select 1 from public.modchip_config where sort = p_sort) then raise exception 'modchip_bad_sort' using errcode='P0001'; end if;
  v_gold := coalesce(nullif(public.idle_val('chip_fusion_gold'), 0), 250000);
  select array_agg(id), array_agg(s) into v_ids, v_sorts
    from (select i.id, c.sort as s from public.items i join public.modchip_config c on c.affix = i.affixes->0->>'k'
           where i.character_id = p_character and i.location = 'bag' and i.item_key = 'salvaged_modchip'
           order by i.created_at limit 3 for update) t;
  if coalesce(array_length(v_ids, 1), 0) < 3 then raise exception 'need_three_salvaged' using errcode='P0001'; end if;
  if not (p_sort = any(v_sorts)) then raise exception 'fusion_sort_not_in_set' using errcode='P0001'; end if;
  if v_ch.gold_copper < v_gold then raise exception 'insufficient_gold' using errcode='P0001'; end if;
  v_ch := public.apply_currency(p_character, 'buy', -v_gold, 0, 0, 0, jsonb_build_object('vendor', p_region, 'fusion', p_sort));
  delete from public.items where id = any(v_ids);
  v_new := public.modchip_make(p_character, 'modchip_' || p_sort || '_epic', 3, p_sort, 'fusion', 'bag');
  perform public.bump_stat(p_character, 'chips_fused', 1);
  return json_build_object('chip', v_new.id, 'key', v_new.item_key, 'affixes', v_new.affixes, 'paid', v_gold, 'gold', v_ch.gold_copper, 'version', v_ch.save_version);
end $function$;
revoke execute on function public.modchip_fusion(uuid, text, text) from public, anon;
grant execute on function public.modchip_fusion(uuid, text, text) to authenticated;

/* [TILLAGT v5.1358.0] LAR ETT MOD CHIP DESIGN (pappret). Bara Jewelcrafters, fran Adept 8 (Epic), Expert 12 (Legendary),
   Master 16 (Mythic). Mythic-pappret visar tva sorter - p_sort valjer. Pappret forbrukas. */
create or replace function public.learn_modchip_design(p_character uuid, p_key text, p_sort text default null)
 returns json language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_d public.modchip_design_config; v_rc public.recipe_config; v_lvl integer; v_sort text;
begin
  perform public.owned_character(p_character);
  select * into v_d from public.modchip_design_config where key = p_key;
  if not found then raise exception 'no_such_schematic' using errcode='P0001'; end if;
  v_sort := coalesce(p_sort, case when array_length(v_d.sorts, 1) = 1 then v_d.sorts[1] end);
  if v_sort is null or not (v_sort = any(v_d.sorts)) then raise exception 'design_bad_choice' using errcode='P0001'; end if;
  select * into v_rc from public.recipe_config where id = 'cr_jc_modchip_' || v_sort || '_' || public.modchip_rar_key(v_d.rarity);
  if not found then raise exception 'no_such_schematic' using errcode='P0001'; end if;
  if exists (select 1 from public.character_recipes where character_id = p_character and recipe_id = v_rc.id) then
    raise exception 'already_known' using errcode='P0001';
  end if;
  if not exists (select 1 from public.character_professions where character_id = p_character and prof = v_rc.prof) then
    raise exception 'wrong_profession' using errcode='P0001';
  end if;
  select public.prof_level(xp) into v_lvl from public.character_professions where character_id = p_character and prof = v_rc.prof;
  if coalesce(v_lvl, 1) < v_d.lvl then
    raise exception 'profession_level_too_low' using errcode='P0001', detail = v_d.lvl::text;
  end if;
  if not public.take_stack(p_character, p_key, 1, null) then
    raise exception 'not_enough_items' using errcode='P0001';
  end if;
  insert into public.character_recipes (character_id, recipe_id) values (p_character, v_rc.id) on conflict do nothing;
  return json_build_object('learned', v_rc.id, 'name', v_rc.name, 'prof', v_rc.prof);
end $function$;
revoke execute on function public.learn_modchip_design(uuid, text, text) from public, anon;
grant execute on function public.learn_modchip_design(uuid, text, text) to authenticated;

-- ============================================================================
-- 6. Droppar: Salvaged Mod Chip, Mod Chip Design, samlad rullning per kalla
-- ============================================================================
/* [TILLAGT v5.1358.0] SALVAGED MOD CHIP. Oftast Rare, 1 av 10 Epic, sort slumpad, vardet alltid i botten (-5 %), bundet.
   Vaskan eller posten. Aldrig fran lador eller World Boss - de kallarna anropar aldrig den har. */
create or replace function public.salvaged_modchip_drop(p_character uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_r integer; v_sort text; v_it public.items; v_mailed boolean := false;
begin
  v_r := case when random() < 0.10 then 3 else 2 end;
  select sort into v_sort from public.modchip_config order by random() limit 1;
  if public.bag_free(p_character) > 0 then
    v_it := public.modchip_make(p_character, 'salvaged_modchip', v_r, v_sort, 'salvaged', 'bag');
  else
    v_it := public.modchip_make(p_character, 'salvaged_modchip', v_r, v_sort, 'salvaged', 'mail');
    perform public.send_mail(p_character, 'Field Courier', 'Held for you - a Salvaged Mod Chip',
      'Your backpack was full, so this was set aside. Make room and collect it here.',
      jsonb_build_array(jsonb_build_object('item_id', v_it.id)));
    v_mailed := true;
  end if;
  perform public.bump_stat(p_character, 'salvaged_chips_found', 1);
  return jsonb_build_object('item', v_it.id, 'key', v_it.item_key, 'r', v_r, 'k', v_sort, 'v', (v_it.affixes->0->>'v')::numeric, 'mailed', v_mailed);
end $function$;
revoke execute on function public.salvaged_modchip_drop(uuid) from public, anon;
grant execute on function public.salvaged_modchip_drop(uuid) to authenticated;

/* [TILLAGT v5.1358.0] ETT MOD CHIP DESIGN FALLER. Epic/Legendary: sorten slumpas. Mythic: tva sorter slumpas (den som lar sig
   valjer) och en chattrad skrivs i General (sender_tag LOOT, ingen lank). p_deliver=false ger bara nyckeln (World Boss
   lagger den i brevet sjalv). Alla kan hitta - yrket kravs forst nar man laser. */
create or replace function public.modchip_design_drop(p_character uuid, p_rar integer, p_deliver boolean default true)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_key text; v_a text; v_b text; v_mailed boolean := false; v_ord text[] := array['crit','critdmg','gold','dgspeed'];
begin
  if p_rar = 5 then
    /* tva olika sorter, i kanonisk ordning (crit, critdmg, gold, dgspeed) sa nyckeln alltid finns i modchip_design_config */
    select min(s) filter (where rn = 1), min(s) filter (where rn = 2) into v_a, v_b
      from (select s, row_number() over (order by array_position(v_ord, s)) rn
              from (select sort s from public.modchip_config order by random() limit 2) t0) t;
    v_key := 'design_modchip_mythic_' || v_a || '_' || v_b;
  else
    select 'design_modchip_' || sort || '_' || public.modchip_rar_key(p_rar) into v_key from public.modchip_config order by random() limit 1;
  end if;
  if not exists (select 1 from public.modchip_design_config where key = v_key) then return null; end if;
  if p_deliver then
    if public.bag_free(p_character) > 0 or exists (select 1 from public.stacks where character_id = p_character and stack_key = v_key) then
      perform public.add_stack(p_character, v_key, 'item', 1, null);
    else
      perform public.send_mail(p_character, 'Field Courier', 'Held for you - a Mod Chip Design',
        'Your backpack was full, so this was set aside. Make room and collect it here.',
        jsonb_build_array(jsonb_build_object('stack_key', v_key, 'kind', 'item', 'qty', 1)));
      v_mailed := true;
    end if;
  end if;
  if p_rar = 5 then
    begin
      insert into public.chat_messages (channel, shard, sender_profile, sender_char, sender_name, sender_tag, sender_handle, body)
      select 'general', coalesce((select val from public.chat_config where key = 'shard'), 'main'), c.profile_id, c.id, c.name, 'LOOT',
             (select p.handle from public.profiles p where p.id = c.profile_id),
             'found a Mythic Mod Chip Design!'
        from public.characters c where c.id = p_character and c.deleted_at is null;
    exception when others then null;
    end;
  end if;
  perform public.bump_stat(p_character, 'chip_designs_found', 1);
  return jsonb_build_object('key', v_key, 'rarity', p_rar, 'mailed', v_mailed);
end $function$;
revoke execute on function public.modchip_design_drop(uuid, integer, boolean) from public, anon;
grant execute on function public.modchip_design_drop(uuid, integer, boolean) to authenticated;

/* [TILLAGT v5.1358.0] EN RULLNING PER KALLA. Laser modchip_drop_config. Loot Luck paverkar inte.
   encounter:  Salvaged alla regioner; Epic fran tier 1 (Drakemark+), Legendary fran tier 2 (Cutlass Bay+), Mythic fran tier 3 (Nova Command+).
   expedition: talen galler 8 h (480 min) i tier 4 och skalas med langd (min/480, hogst 1) och region (1 + 0.15*tier)/1.6 - som andra papper.
   dungeon:    slutbossen besegrad; Mythic bara tier 3-4.
   worldboss:  minst 20 slag (kollas av anroparen); inga Salvaged. p_deliver=false -> bara nycklar, anroparen postar.
   Ett papper per rullning: Mythic provas forst, sedan Legendary, sedan Epic (en random mot summan). */
create or replace function public.modchip_world_drops(p_character uuid, p_src text, p_tier integer, p_mins numeric default 0, p_deliver boolean default true)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_c public.modchip_drop_config; v_f numeric := 1; v_t integer := greatest(0, coalesce(p_tier, 0));
        v_e numeric; v_l numeric; v_m numeric; v_r numeric; v_salv jsonb := null; v_des jsonb := null;
begin
  select * into v_c from public.modchip_drop_config where src = p_src;
  if not found then return jsonb_build_object('salvaged', null, 'design', null); end if;
  if p_src = 'expedition' then
    v_f := least(1, greatest(0, coalesce(p_mins, 0)) / 480.0) * (1 + 0.15 * least(public.max_tier(), v_t)) / 1.6;
  end if;
  v_e := v_c.epic * v_f; v_l := v_c.legendary * v_f; v_m := v_c.mythic * v_f;
  if p_src = 'encounter' then
    if v_t < 1 then v_e := 0; end if;
    if v_t < 2 then v_l := 0; end if;
    if v_t < 3 then v_m := 0; end if;
  elsif p_src = 'dungeon' then
    if v_t < 3 then v_m := 0; end if;
  end if;
  if v_c.salvaged * v_f > 0 and random() < v_c.salvaged * v_f then
    begin v_salv := public.salvaged_modchip_drop(p_character); exception when others then v_salv := null; end;
  end if;
  v_r := random();
  if v_r < v_m then v_des := public.modchip_design_drop(p_character, 5, p_deliver);
  elsif v_r < v_m + v_l then v_des := public.modchip_design_drop(p_character, 4, p_deliver);
  elsif v_r < v_m + v_l + v_e then v_des := public.modchip_design_drop(p_character, 3, p_deliver);
  end if;
  return jsonb_build_object('salvaged', v_salv, 'design', v_des);
end $function$;
revoke execute on function public.modchip_world_drops(uuid, text, integer, numeric, boolean) from public, anon;
grant execute on function public.modchip_world_drops(uuid, text, integer, numeric, boolean) to authenticated;

-- ============================================================================
-- 7. Andrade: craft_output, wb_marks_redeem, pve_fight, claim_expedition, pve_dungeon_claim, wb_reward
-- ============================================================================
CREATE OR REPLACE FUNCTION public.craft_output(p_character uuid, p_recipe text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_rc public.recipe_config; v_mat public.material_config; v_flask public.flask_config;
  v_stack public.stack_item_config; v_item public.items; v_ic public.item_config;
  v_extra jsonb; v_xp numeric;
begin
  select * into v_rc from public.recipe_config where id = p_recipe;
  v_xp := public.craft_xp_for(p_recipe);
  update public.character_professions set xp = xp + v_xp * (1 + public.skill_pct(p_character,'player','p_prof_xp') / 100.0)
  where character_id = p_character and prof = v_rc.prof;
  update public.characters set save_version = save_version + 1, last_seen_at = now()
  where id = p_character;
  select * into v_mat from public.material_config where key = v_rc.item_key;
  if found then
    perform public.add_stack(p_character, v_rc.item_key, 'material', coalesce(v_rc.out_qty, 1), null);   /* [ANDRAT v5.1061.0] nedbrytning ger 3 */
    return json_build_object('crafted', v_rc.item_key, 'kind', 'material', 'xp_gained', v_xp);
  end if;
  select * into v_flask from public.flask_config where key = v_rc.item_key;
  if found then
    perform public.add_stack(p_character, v_rc.item_key, 'flask', 1, v_rc.rarity);
    return json_build_object('crafted', v_rc.item_key, 'kind', 'flask', 'rarity', v_rc.rarity, 'xp_gained', v_xp);
  end if;
  /* [TILLAGT v5.1358.0] MOD CHIPS gors av modchip_make (eget rullat varde +-5 %, obundet), aldrig av roll_item. */
  if v_rc.item_key like 'modchip\_%' then
    v_item := public.modchip_make(p_character, v_rc.item_key, v_rc.rarity, split_part(v_rc.item_key, '_', 2), 'craft', 'bag');
    return json_build_object('crafted', v_rc.item_key, 'kind', 'gear', 'item', v_item.id, 'rarity', v_item.rarity, 'affixes', v_item.affixes, 'xp_gained', v_xp);
  end if;
  select * into v_stack from public.stack_item_config where key = v_rc.item_key;
  if found then
    perform public.add_stack(p_character, v_rc.item_key, 'item', 1, null);
    return json_build_object('crafted', v_rc.item_key, 'kind', 'item', 'xp_gained', v_xp);
  end if;
  if v_rc.perk is not null then
    /* [ANDRAT v5.863.0] Nya hantverket - se craft_gear_make. */
    v_item := public.craft_gear_make(p_character, p_recipe, 'bag');
  else
  v_item := public.roll_item(p_character, v_rc.item_key, v_rc.rarity, 1, 'bag', 0.5, true, v_rc.lvl);
  select * into v_ic from public.item_config where key = v_rc.item_key;
  v_extra := public.roll_extra_affix_for(p_character, v_rc.prof, v_ic.slot_idx, v_rc.rarity);
  update public.items
  set crafted = true, gold_value = public.crafted_value(p_recipe),
      affixes = case when v_extra is null then affixes else affixes || jsonb_build_array(v_extra) end
  where id = v_item.id returning * into v_item;
  end if;
  return json_build_object('crafted', v_rc.item_key, 'kind', 'gear', 'item', v_item.id,
                           'rarity', v_item.rarity, 'affixes', v_item.affixes, 'xp_gained', v_xp);
end; $function$
;

CREATE OR REPLACE FUNCTION public.wb_marks_redeem(p_character uuid, p_what text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_cost integer; v_key text; v_it public.items; v_have integer; v_name text; v_rar integer;
begin
  perform public.owned_character(p_character);
  /* [ANDRAT v5.1108.0] NYA PRISER (Chris 2026-10-22): Legendary-pjas 3 marks (var Epic 5), Broken Charm Epic 5 / Legendary 7 / Mythic 10.
     'epic' ar kvar som namn sa en aldre klient far samma Legendary-pjas. */
  if p_what in ('epic', 'legendary') then v_cost := coalesce(public.idle_val('wb_marks_gear'), 2)::integer;   /* [ANDRAT tyst 2026-10-24] 2 marks (Chris) */
  elsif p_what = 'mythic' then v_cost := coalesce(public.idle_val('wb_marks_mythic'), 10)::integer;   /* [ANDRAT v5.1176.0] 10 marks = Mythic (Chris 2026-10-24, var 5) */
  elsif p_what = 'broken_charm_epic' then v_cost := coalesce(public.idle_val('wb_marks_charm_epic'), 5)::integer;
  elsif p_what = 'broken_charm_legendary' then v_cost := coalesce(public.idle_val('wb_marks_charm_legendary'), 7)::integer;
  elsif p_what = 'broken_charm_mythic' then v_cost := coalesce(public.idle_val('wb_marks_charm_mythic'), 10)::integer;
  elsif p_what = 'socket_drill' then v_cost := coalesce(nullif(public.idle_val('socket_drill_marks'), 0), 15)::integer;   /* [TILLAGT v5.1358.0] Socket Drill 15 marks (Chris), bunden */
  else raise exception 'wb_marks_bad' using errcode='P0001'; end if;
  select qty into v_have from public.stacks where character_id = p_character and stack_key = 'boss_mark' limit 1;
  if coalesce(v_have, 0) < v_cost then raise exception 'wb_marks_short' using errcode='P0001', detail = v_cost::text; end if;
  if not public.take_stack(p_character, 'boss_mark', v_cost, null) then raise exception 'wb_marks_short' using errcode='P0001', detail = v_cost::text; end if;
  if p_what in ('epic', 'legendary', 'mythic') then
    v_rar := case when p_what = 'mythic' then 5 else 4 end;
    /* [ANDRAT v5.1176.0] ALDRIG EN VASKA: vaskor har egen fast raritet, sa 10 marks kunde ge en gra vaska (matt 2026-10-24). Ny dragning tills det ar en riktig pjas. */
    for i in 1..40 loop
      v_key := public.pick_item_key_r(v_rar, p_character);
      exit when v_key is not null and (select bag_slots is null from public.item_config where key = v_key);
    end loop;
    if public.bag_free(p_character) > 0 then
      v_it := public.roll_item(p_character, v_key, v_rar, 1, 'bag', 0, false, least(public.lvl_cap(), greatest(1, public.character_level((select xp from public.characters where id = p_character)))));
    else
      v_it := public.roll_item(p_character, v_key, v_rar, 1, 'mail', 0, false, least(public.lvl_cap(), greatest(1, public.character_level((select xp from public.characters where id = p_character)))));
      perform public.send_mail(p_character, 'World Boss Courier', 'Your Boss Mark reward', 'Your backpack was full, so the piece waits here.', jsonb_build_array(jsonb_build_object('item_id', v_it.id)));
    end if;
    select name into v_name from public.item_config where key = v_key;
    return json_build_object('kind', 'item', 'item_id', v_it.id, 'name', v_name, 'rarity', v_it.rarity, 'mailed', public.bag_free(p_character) <= 0);
  else
    if public.bag_free(p_character) > 0 or exists (select 1 from public.stacks where character_id = p_character and stack_key = p_what) then
      perform public.add_stack(p_character, p_what, 'item', 1, null);
      return json_build_object('kind', 'stack', 'key', p_what, 'mailed', false);
    else
      perform public.send_mail(p_character, 'World Boss Courier', 'Your Boss Mark reward', 'Your backpack was full, so it waits here.', jsonb_build_array(jsonb_build_object('stack_key', p_what, 'kind', 'item', 'qty', 1)));   /* [ANDRAT v5.1358.0] aven borren */
      return json_build_object('kind', 'stack', 'key', p_what, 'mailed', true);
    end if;
  end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.pve_fight(p_character uuid, p_encounter uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_sch text; v_sch_got text := null;
  v_ch public.characters; v_enc public.pve_encounters;
  v_max integer; v_pct numeric; v_cur integer; v_atk integer; v_eatk integer;
  v_fx jsonb; v_lb numeric;
  v_sim jsonb; v_win boolean; v_new_pct numeric;
  v_lvl_fore integer; v_gear jsonb := null; v_try integer; v_onb jsonb := null;
  v_xp numeric := 0; v_scrap_key text; v_scrap_qty integer := 0; v_rep integer := 0;
  v_frags integer := 0; v_cache boolean := false; v_cache_forced boolean := false;
  v_tier integer; v_credits integer := 0; v_em numeric := 1;
  v_mc jsonb := null;   /* [TILLAGT v5.1358.0] Salvaged Mod Chip / Mod Chip Design */
  v_gold numeric := 0;   /* [TILLAGT v5.773.0] koppar ur motet */   /* [ELITE 2026-09-28] belöningsfaktor */
begin
  v_ch := public.owned_character(p_character);
  /* [TILLAGT v5.780.0] Ett fardigt men ohamtat lopp skriver over halsan vid hamtningen - en forlorad
     strid foljd av hamtningen gav gratis lakning. Hamta loppet forst. */
  if exists (select 1 from public.pve_dungeon_runs where character_id = p_character and state = 'running'
             and now() >= effective_end) then
    raise exception 'dungeon_unclaimed' using errcode='P0001';
  end if;
  if public.pve_dungeon_busy(p_character) then
    raise exception 'busy_in_dungeon' using errcode='P0001';
  end if;
  select * into v_enc from public.pve_encounters
    where id = p_encounter and character_id = p_character for update;
  if not found or v_enc.state <> 'open' then
    raise exception 'encounter_gone' using errcode='P0001';
  end if;
  if v_ch.travel_ends is not null and v_ch.travel_ends > now() then   /* [TILLAGT v5.802.0] som dungeonen */
    raise exception 'still_travelling' using errcode='P0001';
  end if;
  if v_ch.region <> v_enc.region or coalesce(v_ch.zone,'') <> v_enc.zone then
    raise exception 'not_in_zone' using errcode='P0001';
  end if;
  /* [TILLAGT v5.834.0] Ingen strid medan man vilar (Chris). */
  if exists (select 1 from public.characters where id = p_character and rest_until > now()) then
    raise exception 'resting' using errcode='P0001';
  end if;
  v_pct := public.pve_hp_touch(p_character);
  update public.characters set rest_start = null, rest_until = null, rest_from = null where id = p_character and rest_until is not null;
  v_max := public.character_health(p_character);
  v_cur := greatest(1, floor(v_max * v_pct / 100.0))::integer;
  v_fx := public.pve_effects_of(p_character);
  v_lb := coalesce((v_fx->>'loot_bonus')::numeric, 0);
  v_atk := round(public.character_attack(p_character)
           * (1 + coalesce((v_fx->>('vs_' || v_enc.ptype))::numeric, 0) / 100.0))::integer;
  v_eatk := greatest(1, round(v_enc.enemy_atk
            * (1 - least(60, coalesce((v_fx->>'armor')::numeric, 0)) / 100.0))::integer);
  v_sim := public.pve_sim(v_atk,
             coalesce((v_fx->>'opening_strike')::numeric, 0)::integer,
             v_cur, v_eatk, v_enc.enemy_hp, true,
             (public.pve_crit_of(p_character)->>'chance')::numeric,
             (public.pve_crit_of(p_character)->>'mult')::numeric);
  /* [TILLAGT v5.637.0] FORSTA MOTET VINNS ALLTID (onboarding-gear.md, steg 1).
     Uppmatt: en naken niva 1-spelare vann 66 % i The Grasslands. En forlust dar
     lamnar honom pa en procents halsa utan hjalpare - onboardingen tar slut
     innan den borjat. Striden kastas om tills den vinns, sa loggen som spelas
     upp ar en riktig strid och halsan en riktig kostnad. Samma raknare som den
     garanterade hjalparcachen: den satts forst vid vinsten. */
  /* [ANDRAT v5.637.1] SKYDDET GALLER TILLS FORSTA PJASEN AR VALD (Chris beslut B).
     Utan vapen vinner en ny spelare 2 av 3 - och en forlust ar ~50 minuters
     lakning under hans forsta tio minuter. Gamla karaktarer har ingen
     onboarding-rad och far bara det gamla skyddet (forsta vinsten). */
  if not (v_sim->>'win')::boolean
     and not coalesce(v_enc.elite, false)   /* [ANDRAT v5.843.0] inte mot eliter (buggsvep 15) */
     and (public.stat_of(p_character, 'pve_wins') = 0   /* [ANDRAT v5.832.0] forsta VINSTEN - lade fullt ryggsack aldrig raknaren gav skyddet for alltid */
          /* [ANDRAT v5.812.0] Bara de forsta tva timmarna - ett aldrig valt startpjasval gav forut
             vinstskydd for alltid, aven mot eliter (buggsvep 13). */
          or (exists (select 1 from public.character_onboarding o where o.character_id = p_character)
              and (select created_at from public.characters where id = p_character) > now() - interval '2 hours'
              and not exists (select 1 from public.character_onboarding_choices c
                              where c.character_id = p_character and c.chosen is not null))) then
    for v_try in 1..200 loop
      v_sim := public.pve_sim(v_atk,
                 coalesce((v_fx->>'opening_strike')::numeric, 0)::integer,
                 v_cur, v_eatk, v_enc.enemy_hp, true,
                 (public.pve_crit_of(p_character)->>'chance')::numeric,
                 (public.pve_crit_of(p_character)->>'mult')::numeric);
      exit when (v_sim->>'win')::boolean;
    end loop;
  end if;
  v_win := (v_sim->>'win')::boolean;
  if v_win then
    update public.pve_encounters set state = 'won', won_at = now()
      where id = v_enc.id;
    perform public.core_sync_add(p_character, 180);
    /* [TILLAGT 2026-09-15] EN VUNNEN STRID GER RYKTE I ZONENS REGION (Chris).
       VARFOR: fyra av fem regioner har uppdrag som gar ut pa att vinna moten -
       man fick alltsa rykte for att UPPDRAGET sa at en att slass, men inte for
       att slass. Talet star i idle_config som pve_rep_per_win. Rykte lagras som
       sekunder narvaro, samma valuta som uppdrag och expeditioner betalar i. */
    /* [ELITE 2026-09-28] Elitmotet betalar x3 pa allt det ger. */
    if v_enc.elite then v_em := coalesce(public.pve_val('elite_reward_mult'), 3); end if;
    v_rep := greatest(0, coalesce((select value::numeric from public.idle_config
                                    where key = 'pve_rep_per_win'), 5) * v_em)::integer;
    if v_rep > 0 then
      insert into public.character_regions (character_id, region, rep_secs, visited_at)
      values (p_character, v_enc.region, public.rep_secs_for(p_character, v_rep), now())
      on conflict (character_id, region)
        do update set rep_secs = public.character_regions.rep_secs + excluded.rep_secs;
    end if;
    v_new_pct := 100.0 * (v_sim->>'hp_left')::integer / v_max;
    /* Nivan FORE segerns XP: den avgor bade den tidiga gratispjasen OCH
       skillnaden mot fienden. Lases darfor forst av allt. */
    select public.character_level(xp) into v_lvl_fore from public.characters where id = p_character;
    v_xp := round(public.xp_award(v_lvl_fore, v_enc.level,
                       coalesce(public.pve_val('encounter_weight'), 1))
            * (1 + v_lb / 100.0) * v_em
            * (case when v_lvl_fore >= coalesce(public.level_val('level_cap'), 50) then coalesce(public.pve_val('encounter_cap_xp_mult'), 0.5) else 1 end));   /* [ANDRAT v5.986.0] */
    perform public.grant_xp(p_character, v_xp, 'mote');
    /* [RATTAT] Nivan lases FORE rullningen - se migreringens rubrik. */
    select tier into v_tier from public.region_config where id = v_enc.region;
  v_tier := public.world_tier(p_character, v_tier);   /* [TILLAGT v5.1104.0] niva 50: hela varlden ar hogsta nivan (Chris) */
    /* Egen pjaschans pa vinst - forut fanns gear bara pa expeditioner. */
    /* [ANDRAT 2026-09-08] Loot Luck hojer chansen till gear efter ett mote (Chris). */
  /* [TILLAGT v5.638.0] MOTET RAKNAS OCKSA (Chris): de fem forsta sakerna man
     klarar ger varsitt val, forsta motet inraknat. Ger valet nagot faller
     ingen slumpad pjas ovanpa. Fiendens niva, men aldrig over spelarens. */
  v_onb := public.onboarding_step(p_character, 'encounter', v_enc.level);
  if v_onb is null and random() < least(0.60, coalesce(public.pve_val('gear_chance'), 0) * (1 + public.loot_luck(p_character) / 2 + public.gear_bonus(p_character,'geardrop') / 100.0)) then   /* [ANDRAT tyst 2026-10-24] p_geardrop bort */
      v_gear := public.gear_drop_roll(p_character, coalesce(v_tier, 0), v_enc.level);
    end if;
    /* [TILLAGT] Motets egen ritning. */
    if random() < public.schematic_chance('encounter') then
      v_sch := public.pick_paper(p_character, public.paper_ranks(coalesce(v_tier,0), 'encounter', 0), null);
      if v_sch is not null then
        v_sch_got := v_sch;
        if public.bag_free(p_character) > 0
           or exists (select 1 from public.stacks
                      where character_id = p_character and stack_key = v_sch) then
          perform public.add_stack(p_character, v_sch, 'recipe', 1, null);
        else
          perform public.send_mail(p_character, 'Field Courier',
            'Held for you - a schematic',
            'Your backpack was full, so this was set aside. Make room and collect it here.',
            jsonb_build_array(jsonb_build_object('stack_key', v_sch, 'kind', 'recipe', 'qty', 1)));
        end if;
      end if;
    end if;
    /* [TILLAGT v5.1358.0] MOD CHIPS: Salvaged 0,05 % per vinst (alla regioner), papper Epic 0,05 % (Drakemark+), Legendary 0,015 % (Cutlass Bay+), Mythic 0,003 % (Nova Command+). Loot Luck paverkar inte. */
    begin v_mc := public.modchip_world_drops(p_character, 'encounter', coalesce(v_tier, 0), 0, true); exception when others then v_mc := null; end;
    v_scrap_qty := round(coalesce(public.pve_val('scrap_qty'), 0)
                   * (1 + v_lb / 100.0) * v_em)::integer;
    if v_scrap_qty > 0 then
      v_scrap_key := public.scrap_key_for_rank(public.pick_scrap_rank(coalesce(v_tier,0)));
      perform public.add_stack(p_character, v_scrap_key, 'material', v_scrap_qty, null);
    end if;
    /* [TILLAGT] Fragment ur ett vunnet mote (nivastegen punkt 26). Forut gav
       moten varken fragment eller hjalpare, sa forsta hjalparen gick bara att
       fa via expeditioner - som i sin tur kraver en hjalpare. Honan och agget. */
    /* [TILLAGT 2026-09-30] Credits ur ett vunnet mote. Elitmotet ger alltid; det vanliga
       ar ett kast. Talen bor i credit_drop_config, taket i grant_play_credits. */
    v_credits := public.grant_play_credits(p_character, 'encounter',
      case when coalesce(v_enc.elite, false) then 'encounter_elite' else 'encounter' end,
      jsonb_build_object('enc', v_enc.id));
    v_frags := round(coalesce(public.pve_val('frags_per_win'), 0) * v_em)::integer;
    /* [ANDRAT v5.1086.0] FRAGMENT FIND GALLER AVEN I VANLIGA STRIDER (Chris): samma regel som expeditioner, dungeons och
       uppdrag. Inte recycling. Bara nar mottet ger fragment alls - noll forblir noll. */
    if v_frags > 0 then v_frags := public.frag_with_find(p_character, v_frags); end if;
    /* [TILLAGT v5.773.0] MOTET BETALAR KOPPAR OCH SILVER (Chris). Forut gav en strid inga pengar
       alls. Grund + per fiendeniva, ganger regionens ring och elitfaktorn, +-15 %. Niva 1 i
       Voxholm ca 2 silver, niva 45 i ytterkanten ca 1,6 guld - alltid klart under expeditionerna. */
    v_gold := round((coalesce(public.pve_val('gold_base'), 0)
                     + coalesce(public.pve_val('gold_per_level'), 0) * v_enc.level)
                    * public.ring_mult_for(p_character, v_enc.region) * v_em * (0.85 + random() * 0.30)
                    * (1 + public.gold_find_pct(p_character) / 100));  /* [ANDRAT v5.776.0] */
    if v_frags > 0 or v_gold > 0 then
      perform public.apply_currency(p_character, 'encounter', v_gold, 0, v_frags, 0,
        jsonb_build_object('enc', v_enc.id,
          /* [TILLAGT v5.1155.0] pjaskastet loggas (raritet/item/bag_full, tur) sa balansen kan matas (buggsvep 2026-10-24) */
          'gear', v_gear, 'luck', round(public.loot_luck(p_character)::numeric, 2), 'rolled', (v_onb is null)));
    end if;
    /* Hjalparcachen (punkt 19): ett eget OBEROENDE kast, en pa tjugo. Inget tak
       pa hur manga saker ett mote kan ge - se punkt 29.
       FORSTA VINSTEN GER DEN ALLTID. Markt med en egen raknare sa den bara kan
       ges EN gang - hade jag i stallet fragat "saknar du hjalpare" hade man
       kunnat atervinna sin enda hjalpare om och om for gratis cacher. */
    /* [ANDRAT v5.774.0] Raknaren satts forst nar ladan faktiskt lagts i vaskan (se nedan). Med full
       vaska gick den forsta ladan forlorad for alltid, och guidens steg vantade pa en hjalpare. */
    if public.stat_of(p_character, 'first_helper_cache') = 0 then
      v_cache_forced := true;
    end if;
    if v_cache_forced or random() < coalesce(public.pve_val('helper_cache_chance'), 0) then
      if public.bag_free(p_character) > 0
         or exists (select 1 from public.stacks
                    where character_id = p_character and stack_key = 'cache_helper') then
        perform public.add_stack(p_character, 'cache_helper', 'item', 1, null);
        v_cache := true;
        if v_cache_forced then perform public.bump_stat(p_character, 'first_helper_cache', 1); end if;
      end if;
    end if;
  else
    /* [ANDRAT v5.802.0] Tog rundorna slut lever man med det man har kvar - forut 1 HP aven da. */
    v_new_pct := greatest(0.05, 100.0 * greatest(1, coalesce((v_sim->>'hp_left')::integer, 1)) / v_max);
  end if;
  /* [TILLAGT v5.834.0] DE FORSTA STRIDERNA (Chris 2026-10-17): upp till niva 3 lamnar en strid aldrig
     spelaren under halv halsa. Nya spelare vann forsta striden med 5-9 % kvar, kunde inte sla sig pa
     ~10 minuter och slutade spela. */
  /* [ANDRAT v5.843.0] Golvet hojer aldrig over det man gick in med - en forlust var forut en gratis lakning (buggsvep 15). */
  if public.character_level(v_ch.xp) <= 3 then v_new_pct := greatest(v_new_pct, least(50, v_pct)); end if;
  /* [TILLAGT v5.843.0] Ny niva = full halsa (grant_xp lakte, men striden skrev over med sin rest - buggsvep 15). */
  if public.character_level((select xp from public.characters where id = p_character)) > public.character_level(v_ch.xp) then
    v_new_pct := 100;
  end if;
  update public.characters
     set hp_pct = v_new_pct, save_version = save_version + 1
   where id = p_character;
  return json_build_object(
    'win', v_win, 'credits', v_credits, 'rounds', (v_sim->>'rounds')::integer, 'log', v_sim->'log',
    'player_atk', v_atk, 'enemy_atk', v_eatk,
    'start_hp', v_cur, 'enemy_hp', v_enc.enemy_hp,
    'hp', json_build_object('pct', round(v_new_pct,3), 'max', v_max,
          'cur', greatest(1, floor(v_max * v_new_pct / 100.0))::integer),
    'elite', v_enc.elite,
    'rewards', case when v_win then json_build_object(
          'xp', round(v_xp), 'rep', v_rep, 'scrap_key', v_scrap_key, 'scrap_qty', v_scrap_qty,
        'frags', v_frags, 'helper_cache', v_cache, 'gold', round(v_gold),
          'credits', v_credits,   /* [2026-10-04] segerrutan laser HAR, inte pa toppnivan */
          'gear', v_gear, 'choice', v_onb,
          'schematic', v_sch_got,
          'modchips', v_mc) end);   /* [TILLAGT v5.1358.0] */
end;
$function$
;

CREATE OR REPLACE FUNCTION public.claim_expedition(p_character uuid, p_exp text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_run public.expedition_runs; v_def public.expedition_config; v_hc integer;
  v_ch public.characters; v_loot jsonb; v_xp numeric; v_scrap integer;
  v_tier integer; v_luck numeric; v_rep integer;
  v_w integer[]; v_total integer; v_pick numeric; v_rar integer; v_i integer;
  v_key text; v_item public.items; v_gear jsonb := null; v_relic jsonb := null;
  v_frag_bonus numeric; v_frags integer; v_cell boolean := false; v_credits integer := 0;
  v_rec text := null; v_gold numeric; v_melon boolean := false;
  v_base numeric; v_whole integer; v_scrap_key text; v_junk jsonb;
  v_missed text[] := '{}'; v_want_gear boolean; v_mailed jsonb := '[]'::jsonb;
  v_relic_key text; v_relic_rar integer; v_relic_item public.items;
  v_onb jsonb; v_gc numeric; v_gear_n integer := 0; v_gi integer; v_gears jsonb := '[]'::jsonb;
  v_shard text; v_shard_got text := null; v_first_clear boolean; v_lap json;
  v_mc jsonb := null;   /* [TILLAGT v5.1358.0] Salvaged Mod Chip / Mod Chip Design */
begin
  perform public.owned_character(p_character);
  select * into v_run from public.expedition_runs
  where character_id = p_character and exp_id = p_exp and claimed_at is null for update;
  if not found then raise exception 'no_such_run' using errcode='P0001'; end if;
  if now() < v_run.ends_at then raise exception 'expedition_not_finished' using errcode='P0001'; end if;
  select * into v_def from public.expedition_config where id = p_exp;
  /* [FLYTTAD 2026-09-18] Synken ges vid STARTEN nu, se start_expedition. */
  select tier into v_tier from public.region_config where id = v_def.region_id;
  v_tier := public.world_tier(p_character, v_tier);   /* [TILLAGT v5.1104.0] niva 50: hela varlden ar hogsta nivan (Chris) */
  v_tier := coalesce(v_tier, 0);
  v_frag_bonus := public.frag_find_pct(p_character) / 100;   /* [ANDRAT v5.1155.0] (anvands inte - frag_with_find gor jobbet) */
  v_base  := public.expedition_frag_base(v_def.mins);
  v_whole := floor(v_base)::integer;
  /* [ANDRAT 2026-10-06] FRAG FIND SOM RIKTIG PROCENT (Chris: ja). Forut lades bonusen
     till som HUNDRADELAR av ett fragment: +5 % gav +0,05 fragment. Nu bas x (1 + bonus/100),
     resten ett kast - samma regel for dungeons, pa ETT stalle (frag_with_find). */
  v_frags := public.frag_with_find(p_character, v_base);
  v_scrap_key := public.scrap_key_for_rank(public.pick_scrap_rank(v_tier));
  /* [ANDRAT 2026-09-15] Var: greatest(1, round(mins * 0.5)). Se noten ovan. */
  v_scrap := 0;
  if v_run.loot is null then
    v_gold := round(public.expedition_gold(v_def.mins, v_tier) * (1 + public.gold_find_pct(p_character) / 100));
    v_loot := jsonb_build_object('scrap_key', v_scrap_key, 'scrap', v_scrap, 'gold', v_gold,
                                 'frags', v_frags, 'xp', public.expedition_xp(p_character, v_def.lvl, v_def.mins) /* [ANDRAT v5.977.0] egen niva aven pa 50 (Chris) */);
    update public.expedition_runs set loot = v_loot where id = v_run.id;
  else
    v_loot := v_run.loot;
    v_frags := (v_loot->>'frags')::integer;
    v_scrap := coalesce((v_loot->>'scrap')::integer, v_scrap);
    v_scrap_key := coalesce(v_loot->>'scrap_key', v_scrap_key);
  end if;
  v_ch := public.apply_currency(p_character, 'expedition',
            (v_loot->>'gold')::numeric, 0, v_frags, 0, jsonb_build_object('exp', p_exp));
  v_xp := public.grant_xp(p_character, (v_loot->>'xp')::numeric, 'expedition');
  if v_scrap > 0 then
    if public.bag_free(p_character) > 0
       or exists (select 1 from public.stacks
                  where character_id = p_character and stack_key = v_scrap_key and rarity is null) then
      perform public.add_stack(p_character, v_scrap_key, 'material', v_scrap, null);
    else
      v_missed := v_missed || 'the scrap'::text;
      v_mailed := v_mailed || jsonb_build_object('stack_key', v_scrap_key, 'kind', 'material', 'qty', v_scrap);
    end if;
  end if;

  /* [TILLAGT v5.17.0] SKRAP UR BYTET. En chans pa fyra, 1-3 olika sorter.
     Skrapet slutade droppa i tomgangen; det kommer harifran nu. */
  v_junk := public.roll_expedition_junk(p_character);

  /* [ANDRAT 2026-09-08] Turen raknas i loot_luck nu - samma tal overallt. */
  v_luck := public.loot_luck(p_character);
  if random() < public.exp_cell_chance(v_def.mins) then
    if public.bag_free(p_character) > 0 then
      perform public.add_stack(p_character, 'fuelcell', 'item', 1, null); v_cell := true;
    else v_missed := v_missed || 'a fuel cell'::text;
      v_mailed := v_mailed || jsonb_build_object('stack_key','fuelcell','kind','item','qty',1);
    end if;
  end if;
  if random() < public.exp_melon_chance(v_def.mins) then
    if public.bag_free(p_character) > 0 then
      perform public.add_stack(p_character, 'melon_' || v_def.region_id, 'item', 1, null); v_melon := true;
    else v_missed := v_missed || 'a mystery melon'::text;
      v_mailed := v_mailed || jsonb_build_object('stack_key','melon_' || v_def.region_id,'kind','item','qty',1);
    end if;
  end if;
  /* [ANDRAT v5.637.0] Onboardingens val mellan tva. Ger det nagot faller varken
     slumpad pjas eller relik ovanpa - en pjas per steg (Chris 2026-09-24). */
  v_onb := public.onboarding_step(p_character, 'expedition', v_def.lvl);
  /* [ANDRAT v5.776.0] Chansen kan vara over 1 pa langa expeditioner: hela delen ar sakra pjaser,
     resten ett kast pa en till. Varje pjas gar samma vag som forut (vaska eller post). */
  v_gc := public.exp_gear_chance(v_def.mins, v_luck / 2 + public.gear_bonus(p_character,'geardrop') / 100.0);   /* [ANDRAT tyst 2026-10-24] halv tur som i strid (Balans 2, Chris); p_geardrop fanns inte i tradet */
  v_gear_n := case when v_onb is null
                   then floor(v_gc)::integer + (case when random() < v_gc - floor(v_gc) then 1 else 0 end)
                   else 0 end;
  for v_gi in 1..v_gear_n loop
  v_want_gear := true;
  if v_want_gear and public.bag_free(p_character) = 0 then
    /* [ANDRAT v5.779.0] En gang i texten aven nar flera pjaser postas. */
    if not ('a piece of gear' = any(v_missed)) then v_missed := v_missed || 'a piece of gear'::text; end if;
    v_w := public.gear_weights_for(p_character, v_tier);
    select sum(x) into v_total from unnest(v_w) x;
    v_pick := random() * v_total; v_rar := 0;
    for v_i in 1..array_length(v_w,1) loop
      v_pick := v_pick - v_w[v_i];
      if v_pick < 0 then v_rar := v_i - 1; exit; end if;
    end loop;
    v_key := public.pick_item_key_r(v_rar, p_character);
    if v_key is not null then
      v_mailed := v_mailed || jsonb_build_object('item_key', v_key, 'rarity', v_rar, 'lvl', v_def.lvl);
    end if;
  end if;
  if v_want_gear and public.bag_free(p_character) > 0 then
    v_w := public.gear_weights_for(p_character, v_tier);
    select sum(x) into v_total from unnest(v_w) x;
    v_pick := random() * v_total; v_rar := 0;
    for v_i in 1..array_length(v_w,1) loop
      v_pick := v_pick - v_w[v_i];
      if v_pick < 0 then v_rar := v_i - 1; exit; end if;
    end loop;
    v_key := public.pick_item_key_r(v_rar, p_character);
    if v_key is not null then
      v_item := public.roll_item(p_character, v_key, v_rar, 1, 'bag', p_level => public.scaled_level(p_character, v_def.lvl));
      v_gear := jsonb_build_object('item', v_key, 'rarity', v_rar, 'id', v_item.id);
      v_gears := v_gears || v_gear;
    end if;
  end if;
  end loop;
  /* [TILLAGT] RELIKEN. Chansen ar densamma som alltid varit tankt: 4 % vid tva
     timmar, hojd med regionens niva och turen, hogst 20 %. Bara reliker som
     faktiskt kan falla i varlden valjs - hantverkets egna raknas bort. */
  /* [ANDRAT] SKARVAN GES NAR MAN INTE REDAN AGER DEN, oavsett tidigare klaringar.
     Grinden "bara forsta klaringen" stangde ute alla som klarat expeditionen innan
     skarvorna fanns. Agar-kollen mot stacks nedan raknar bort dubbletter. */
  v_first_clear := true;
  if v_first_clear then
    select key into v_shard from public.shard_config where exp_id = p_exp;
    if v_shard is not null
       and not exists (select 1 from public.stacks
                       where character_id = p_character and stack_key = v_shard)
       and not exists (select 1 from public.character_shard_grants g
                       where g.character_id = p_character and g.shard_key = v_shard) then   /* [ANDRAT 2026-10-20] en gang for alltid */
      insert into public.character_shard_grants (character_id, shard_key) values (p_character, v_shard) on conflict do nothing;
      -- [ANDRAT] Skarvan bor i gathering-vaskan (ingen takgrans), sa den laggs
      -- rakt in utan att den vanliga vaskans utrymme spelar nagon roll.
      v_shard_got := v_shard;
      perform public.add_stack(p_character, v_shard, 'material', 1, null);
    end if;
  end if;
  if v_onb is null and random() < public.exp_relic_chance(v_def.mins, v_tier, v_luck) then
    v_w := public.gear_weights_for(p_character, v_tier);
    select sum(x) into v_total from unnest(v_w) x;
    v_pick := random() * v_total; v_relic_rar := 0;
    for v_i in 1..array_length(v_w,1) loop
      v_pick := v_pick - v_w[v_i];
      if v_pick < 0 then v_relic_rar := v_i - 1; exit; end if;
    end loop;
    select i.key into v_relic_key from public.item_config i
    where i.slot_idx = 13 and i.key not like 'craft\_%' and i.key not like 'sig%'
      and v_relic_rar = any(i.drop_rarities)
    order by random() limit 1;
    if v_relic_key is null then
      /* Ingen relik i den sallsyntheten - ta narmaste lagre som finns. */
      select i.key, x.r into v_relic_key, v_relic_rar
      from public.item_config i, unnest(i.drop_rarities) as x(r)
      where i.slot_idx = 13 and i.key not like 'craft\_%' and i.key not like 'sig%'
        and x.r <= v_relic_rar
      order by x.r desc, random() limit 1;
    end if;
    if v_relic_key is not null then
      if public.bag_free(p_character) > 0 then
        v_relic_item := public.roll_item(p_character, v_relic_key, v_relic_rar, 1, 'bag'::item_location, p_level => public.scaled_level(p_character, v_def.lvl));
        v_relic := jsonb_build_object('item', v_relic_key, 'rarity', v_relic_rar,
                                      'id', v_relic_item.id);
      else
        v_missed := v_missed || 'a relic'::text;
        v_mailed := v_mailed || jsonb_build_object('item_key', v_relic_key, 'rarity', v_relic_rar, 'lvl', v_def.lvl);
      end if;
    end if;
  end if;
  if random() < public.exp_schematic_chance(v_def.mins, v_tier, v_luck) then
    /* [ANDRAT] Ritningen ar ett FOREMAL nu - den laggs i vaskan (eller posten)
       och laras nar spelaren oppnar den. Hogre regioner kan ge svarare papper. */
    v_rec := public.pick_paper(p_character, public.paper_ranks(v_tier, 'expedition', v_def.mins), null);
    if v_rec is not null then
      if public.bag_free(p_character) > 0
         or exists (select 1 from public.stacks
                    where character_id = p_character and stack_key = v_rec) then
        perform public.add_stack(p_character, v_rec, 'recipe', 1, null);
      else
        v_missed := v_missed || 'a schematic'::text;
        v_mailed := v_mailed || jsonb_build_object('stack_key', v_rec, 'kind', 'recipe', 'qty', 1);
      end if;
    end if;
  end if;
  /* [TILLAGT v5.1358.0] MOD CHIPS: Salvaged 1 %, papper 1,5 / 0,5 / 0,1 % vid 8 h tier 4 - skalar med langd och region. Loot Luck paverkar inte. */
  begin v_mc := public.modchip_world_drops(p_character, 'expedition', v_tier, v_def.mins, true); exception when others then v_mc := null; end;
  if jsonb_array_length(v_mailed) > 0 then
    perform public.send_mail(p_character, 'Expedition Depot',
      'Held for you — ' || v_def.name,
      'Your backpack was full when the team returned, so this was set aside. ' ||
      'Make room and collect it here.', v_mailed);
  end if;
  /* Hjalparcachen faller dar allt annat faller (beslut 19). */
  /* [ANDRAT v5.810.0] Svaret sparas och skickas med - forut syntes en hjalparlada fran en expedition
     aldrig i rutan (buggsvep 12). */
  v_hc := coalesce(public.helper_cache_roll(p_character, 1), 0);
  update public.expedition_runs set claimed_at = now() where id = v_run.id;
  v_lap := public.region_lap_check(p_character, v_def.region_id);
  /* [TILLAGT 2026-09-15] EXPEDITIONEN GER RYKTE I SIN EGEN REGION (Chris).
     VARFOR: rykte ar regionens matt pa hur mycket man gjort dar, och att resa
     ut fran en region i atta timmar raknades inte alls. Nu gor det det.
     Talet foljer LANGDEN och star i idle_config som exp_rep_per_min, sa det
     gar att skruva pa utan ny kod. Rykte lagras som SEKUNDER narvaro, samma
     valuta som uppdragen betalar i - darfor samma omrakning som quest_claim. */
  v_rep := greatest(1, round(v_def.mins *
             coalesce((select value::numeric from public.idle_config
                        where key = 'exp_rep_per_min'), 0.25)))::integer;
  insert into public.character_regions (character_id, region, rep_secs, visited_at)
  values (p_character, v_def.region_id, public.rep_secs_for(p_character, v_rep), now())
  on conflict (character_id, region)
    do update set rep_secs = public.character_regions.rep_secs + excluded.rep_secs;
  perform public.bump_stat(p_character, 'exp_done', 1);
  /* [TILLAGT 2026-09-30] Credits ur expeditionen. Nyckeln ar langden: exp_5 ... exp_480.
     De korta ger inget, de langa ett sakert. Talen bor i credit_drop_config - en langd
     som saknar rad ger noll, inte ett fel. Expeditionen ar PASSIV och fyra kan ga samtidigt,
     darfor ar den snalast av de fyra kallorna. Dygnstaket ligger i grant_play_credits. */
  v_credits := public.grant_play_credits(p_character, 'expedition',
    'exp_' || coalesce(v_def.mins, 0)::text,
    jsonb_build_object('exp', p_exp, 'mins', v_def.mins));
  return json_build_object('exp', p_exp, 'credits', v_credits, 'loot', v_loot, 'xp_gained', v_xp,
                           'choice', v_onb,
    'scrap', v_scrap, 'scrap_key', v_scrap_key, 'junk', v_junk, 'cell', v_cell, 'gear', v_gear, 'gears', v_gears,
    'relic', v_relic, 'recipe', v_rec, 'melon', v_melon, 'modchips', v_mc,   /* [TILLAGT v5.1358.0] */
    'frags', v_frags, 'rep', v_rep, 'gold', v_ch.gold_copper, 'version', v_ch.save_version,
    'missed', to_jsonb(v_missed), 'shard', v_shard_got, 'lap', v_lap, 'mailed', jsonb_array_length(v_mailed) > 0, 'helper_cache', v_hc);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.pve_dungeon_claim(p_character uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_run public.pve_dungeon_runs; v_cap numeric;
  v_ev jsonb; v_xp numeric := 0;
  v_ub integer := 0; v_uf integer := 0; v_ur integer := 0;
  v_loot integer := 0;
  v_scraps jsonb := '{}'::jsonb; v_caches integer := 0; v_credits integer := 0; v_vinster integer := 0; v_frags integer := 0;
  v_hp numeric; v_died boolean := false; v_boss integer := 0;
  v_rep integer := 0; v_dreg text;
  v_row public.items; v_max integer; v_new_pct numeric; v_k text;
  v_bosses jsonb := '[]'::jsonb; v_gear jsonb;
  v_fx_base numeric; v_fx_val integer; v_rmult numeric;
  v_mail_ids jsonb := '[]'::jsonb; v_to_bag boolean;
  v_sch text; v_sch_tier integer; v_sch_got text := null; v_final_won boolean := false;
  v_dgold numeric := 0; v_lv0 integer;   /* [TILLAGT v5.843.0] nivan fore hamtningen */   /* [TILLAGT v5.776.0] guld for klarat lopp */
  v_klar boolean := false; v_charms jsonb := '[]'::jsonb; v_ck text; v_mc jsonb := null;   /* [TILLAGT v5.1358.0] Mod Chips */   /* [TILLAGT v5.876.0] */   /* [TILLAGT v5.774.0] loppet KLARAT: slutbossen besegrad och ingen dod */
begin
  perform public.owned_character(p_character);
  select * into v_run from public.pve_dungeon_runs
    where character_id = p_character and state = 'running' for update;
  if not found then raise exception 'no_such_run' using errcode='P0001'; end if;
  if now() < v_run.effective_end then
    raise exception 'dungeon_not_finished' using errcode='P0001';
  end if;
  v_cap := extract(epoch from (v_run.effective_end - v_run.started_at)) / 60.0;
  /* [FLYTTAT 2026-09-21] Karnans fjardedel betalas vid STARTEN nu, se
     pve_dungeon_start. Stod raden kvar har skulle varje lopp betala tva ganger. */
  for v_ev in select * from jsonb_array_elements(v_run.events) loop
    exit when (v_ev->>'m')::numeric > v_cap + 0.01;   /* [ANDRAT v5.1222.0] handelsernas minut ar avrundad till 0,01 men sluttiden inte - slutbossen foll utanfor och loppet raknades som dott (Nightmare) */
    if (v_ev->>'loot_key') is not null then v_loot := v_loot + 1; end if;
  end loop;
  /* [BORTTAGET] Kravet pa plats for hela bytet. Det som inte ryms postas. */
  v_hp := v_run.hp_start_pct;
  for v_ev in select * from jsonb_array_elements(v_run.events) loop
    exit when (v_ev->>'m')::numeric > v_cap + 0.01;   /* [ANDRAT v5.1222.0] handelsernas minut ar avrundad till 0,01 men sluttiden inte - slutbossen foll utanfor och loppet raknades som dott (Nightmare) */
    v_xp := v_xp + (v_ev->>'xp')::numeric;
    if (v_ev->>'win')::boolean then v_vinster := v_vinster + 1; end if;
    v_ub := v_ub + (v_ev->>'ub')::integer;
    v_uf := v_uf + (v_ev->>'uf')::integer;
    v_ur := v_ur + (v_ev->>'ur')::integer;
    v_hp := (v_ev->>'hp')::numeric;
    if not (v_ev->>'win')::boolean then v_died := true; end if;
    if (v_ev->>'scrap')::integer > 0 and (v_ev->>'sk') is not null then
      v_scraps := jsonb_set(v_scraps, array[v_ev->>'sk'],
        to_jsonb(coalesce((v_scraps->>(v_ev->>'sk'))::integer, 0) + (v_ev->>'scrap')::integer));
    end if;
    v_gear := null;
    if (v_ev->>'loot_key') is not null then
      v_to_bag := public.bag_free(p_character) > 0;
      v_row := public.roll_item(p_character, v_ev->>'loot_key',
                                (v_ev->>'loot_rar')::integer, 1,
                                (case when v_to_bag then 'bag' else 'mail' end)::item_location, p_level => coalesce((v_ev->>'level')::integer, 1));
      if not v_to_bag then
        v_mail_ids := v_mail_ids || jsonb_build_object('item_id', v_row.id);
      end if;
      if (v_ev->>'sig')::boolean and (v_ev->>'fx') is not null then
        select base into v_fx_base from public.pve_effect_config where key = v_ev->>'fx';
        select mult into v_rmult from public.rarity_config where idx = v_row.rarity;
        v_fx_val := round(coalesce(v_fx_base,0) * coalesce(v_rmult,1))::integer;
        update public.items
          set pve_effect = jsonb_build_object('k', v_ev->>'fx', 'v', v_fx_val)
          where id = v_row.id;
      end if;
      v_gear := jsonb_build_object('id', v_row.id, 'key', v_row.item_key, 'rarity', v_row.rarity,
        'sig', coalesce((v_ev->>'sig')::boolean, false),
        'fx', (case when (v_ev->>'sig')::boolean
               then jsonb_build_object('k', v_ev->>'fx', 'v', v_fx_val) end));
    end if;
    if (v_ev->>'kind') in ('boss','final') then
      if (v_ev->>'win')::boolean then
        v_boss := v_boss + 1;
        /* [TILLAGT v5.876.0] Broken Charm - ett kast per besegrad boss, slutbossen battre. */
        /* [ANDRAT v5.880.0] HOGST EN PER LOPP (Chris): har en redan fallit kastas inte igen. */
        if jsonb_array_length(v_charms) = 0 then
          v_ck := public.charm_boss_roll(p_character, (v_ev->>'kind') = 'final', coalesce(v_run.heroic, false));
          if v_ck is not null then v_charms := v_charms || to_jsonb(v_ck); end if;
        end if;
      end if;
      if (v_ev->>'kind') = 'final' and (v_ev->>'win')::boolean then
        v_final_won := true;
      end if;
      v_bosses := v_bosses || jsonb_build_object(
        'name', v_ev->>'name', 'win', (v_ev->>'win')::boolean,
        'xp', (v_ev->>'xp')::numeric, 'scrap', (v_ev->>'scrap')::integer,
        'sk', v_ev->>'sk', 'gear', v_gear);
    end if;
  end loop;
  /* [TILLAGT v5.774.0] AVBRUTET AR INTE KLARAT (buggsvep 2). Avbryt flyttar slutet till nu, och
     da passerade hamtningen med noll handelser och "ingen dod" - rykte, credits, 8/16 fragment,
     heroic, uppdragsmal och raknare gick att hamta om och om igen utan att spela. Det man hann
     spela (XP, fynd, skrot) behalls; klarat-belaningarna kraver att slutbossen foll. */
  v_klar := v_final_won and not v_died;
  /* Ett kast per vunnen strid - samma chans som ett mote ute i varlden. */
  v_caches := public.helper_cache_roll(p_character, v_vinster);
  for v_k in select * from jsonb_object_keys(v_scraps) loop
    perform public.add_stack(p_character, v_k, 'material', (v_scraps->>v_k)::integer, null);
  end loop;
  select public.character_level(xp) into v_lv0 from public.characters where id = p_character;
  if v_xp > 0 then perform public.grant_xp(p_character, v_xp, 'dungeon'); end if;
  /* [2026-10-05] Bara det som FORBRUKADES - resten lamnas tillbaka pa raderna under. */
  if v_ub > 0 then perform public.bump_stat(p_character, 'used_bandage', v_ub); end if;
  if v_uf > 0 then perform public.bump_stat(p_character, 'used_first_aid_kit', v_uf); end if;
  if v_run.sup_bandage - v_ub > 0 then
    perform public.add_stack(p_character, 'bandage', 'item', v_run.sup_bandage - v_ub, null);
  end if;
  if v_run.sup_fak - v_uf > 0 then
    perform public.add_stack(p_character, 'first_aid_kit', 'item', v_run.sup_fak - v_uf, null);
  end if;
  if v_run.sup_revive - v_ur > 0 then
    perform public.add_stack(p_character, 'revive_kit', 'item', v_run.sup_revive - v_ur, null);
  end if;
  v_max := public.character_health(p_character);
  /* [ANDRAT v5.802.0] Att do gav forut 25 % - mer an man gick in med (gratis lakning, buggsvep 10).
     Nu hogst 25 % och aldrig mer an man startade med. */
  v_new_pct := (case when v_died then greatest(0.05, least(25.0, coalesce(v_run.hp_start_pct, 25.0))) else greatest(0.05, v_hp) end);
  /* [ANDRAT v5.780.0] Lakningen sedan loppet tog slut raknas in - forut nollades en natts lakning
     om man hamtade pa morgonen (buggsvep 4). */
  v_new_pct := least(100, v_new_pct + greatest(0, extract(epoch from (now() - v_run.effective_end))) / 3600.0
                                     * public.pve_regen(p_character));
  /* [TILLAGT v5.843.0] Ny niva = full halsa, som overallt (buggsvep 15). */
  if public.character_level((select xp from public.characters where id = p_character)) > coalesce(v_lv0, 0) then v_new_pct := 100; end if;
  update public.characters
     set hp_pct = v_new_pct, save_version = save_version + 1
   where id = p_character;
  /* [TILLAGT] Ritningen. Bara om man tog sig igenom. */
  if v_final_won and not v_died then
    select rc.tier into v_sch_tier from public.region_config rc
    join public.pve_dungeon_config dc on dc.region = rc.id
    where dc.id = v_run.dungeon_id;
    v_sch_tier := public.world_tier(p_character, coalesce(v_sch_tier, 0));   /* [TILLAGT 2026-10-28] niva 50 skalar (Chris) */
    if random() < public.schematic_chance(case when v_run.heroic then 'heroic' else 'dungeon' end)
                 * (case when v_run.heroic and coalesce(v_sch_tier,0) >= 4 then 1.5 else 1 end) then
      v_sch := public.pick_paper(p_character, public.paper_ranks(coalesce(v_sch_tier,0), case when v_run.heroic then 'heroic' else 'dungeon' end, 0),
                public.boss_paper_perks(1 + floor(random() * 5)::integer));   /* [ANDRAT v5.863.0] en av de fem bossarnas lista */
      if v_sch is not null then
        v_sch_got := v_sch;
        if public.bag_free(p_character) > 0
           or exists (select 1 from public.stacks
                      where character_id = p_character and stack_key = v_sch) then
          perform public.add_stack(p_character, v_sch, 'recipe', 1, null);
        else
          v_mail_ids := v_mail_ids || jsonb_build_object('stack_key', v_sch,
                          'kind', 'recipe', 'qty', 1);
        end if;
      end if;
    end if;
  end if;
  if jsonb_array_length(v_mail_ids) > 0 then
    perform public.send_mail(p_character, 'Dungeon Quartermaster',
      'Held for you — spoils from the run',
      'Your backpack was full, so this was set aside. Make room and collect it here.',
      v_mail_ids);
  end if;
  /* [TILLAGT 2026-09-15] DUNGEONEN GER RYKTE I SIN EGEN REGION (Chris).
     VARFOR: den ar regionens tyngsta arbete och raknades inte alls. Regionen
     tas ur dungeonens egen rad, inte ur var spelaren rakar sta. Bara den som
     TAR SIG UT LEVANDE far ryktet - samma krav som uppdragen staller pa en
     dungeon. Talen star i idle_config: dungeon_rep och dungeon_rep_heroic. */
  if v_klar then
    select region into v_dreg from public.pve_dungeon_config where id = v_run.dungeon_id;
    v_rep := coalesce((select value::numeric from public.idle_config
      where key = case when coalesce(v_run.heroic,false) then 'dungeon_rep_heroic'
                       else 'dungeon_rep' end), 40)::integer;
    if v_dreg is not null and v_rep > 0 then
      insert into public.character_regions (character_id, region, rep_secs, visited_at)
      values (p_character, v_dreg, public.rep_secs_for(p_character, v_rep), now())
      on conflict (character_id, region)
        do update set rep_secs = public.character_regions.rep_secs + excluded.rep_secs;
    end if;
  end if;
  /* [TILLAGT 2026-09-30] Credits ur ett KLARAT lopp. Dog man ger loppet ingenting -
     annars vore doden en lika bra vag till credits som att klara det. Heroic ger mer.
     Talen bor i credit_drop_config, dygnstaket i grant_play_credits. */
  if v_klar then
    v_credits := public.grant_play_credits(p_character, 'dungeon',
      case when coalesce(v_run.heroic, false) then 'dungeon_hard' else 'dungeon' end,
      jsonb_build_object('dungeon', v_run.dungeon_id, 'run', v_run.id));
  end if;
  /* [TILLAGT 2026-10-06] Fragment ur ett KLARAT lopp (Chris): 8 vanlig, 16 heroic.
     Samma regel som credits - dog man ger loppet ingenting. */
  if v_klar then
    /* [ANDRAT 2026-10-06] Frag find galler har ocksa - samma regel som expeditionen. */
    v_frags := public.frag_with_find(p_character, case when coalesce(v_run.heroic, false) then 16 else 8 end);
    /* [TILLAGT v5.776.0] GULD FOR KLARAT LOPP (Chris: ekonomiforslaget punkt 5): som en
       45-minutersexpedition i dungeonens region, med samma guldbonus fran utrustning och hjalpare. */
    v_dgold := round(public.expedition_gold(45, public.world_tier(p_character, coalesce((select rc.tier from public.region_config rc
                 join public.pve_dungeon_config dc on dc.region = rc.id where dc.id = v_run.dungeon_id), 0)))
               * (1 + public.gold_find_pct(p_character) / 100));
    perform public.apply_currency(p_character, 'dungeon', v_dgold, 0, v_frags, 0,
      jsonb_build_object('dungeon', v_run.dungeon_id, 'run', v_run.id));
  end if;
  /* [TILLAGT v5.901.0] RIFT: ny basta niva, forsta-gangen-bonus (guld x niva/2 + en Broken Charm), serverrekord. */
  if v_klar and coalesce(v_run.rift, 0) > 0 then
    declare v_old integer; v_srv integer; v_rgold numeric; v_rck text; v_rr numeric; v_cname text;
    begin
      select name into v_cname from public.characters where id = p_character;
      v_old := public.rift_best_in(p_character, v_run.dungeon_id);   /* [ANDRAT v5.1193.0] per dungeon */
      select coalesce(max(rift_best), 0) into v_srv from public.character_rift_best b join public.characters c on c.id = b.character_id
          where c.deleted_at is null and b.character_id <> p_character and b.dungeon_id = v_run.dungeon_id;   /* [ANDRAT v5.1207.0] rekord PER DUNGEON (Chris) */
      if v_run.rift > coalesce(v_old, 0) then
        insert into public.character_rift_best (character_id, dungeon_id, best) values (p_character, v_run.dungeon_id, v_run.rift)
          on conflict (character_id, dungeon_id) do update set best = greatest(public.character_rift_best.best, excluded.best);
        update public.characters set rift_best = greatest(coalesce(rift_best, 0), v_run.rift) where id = p_character;   /* totalt basta: topplistan */
        perform set_config('genesis.rift_first', '1', true);   /* [TILLAGT 2026-10-20] kvittot vet att bonusen betalades */
        v_rgold := round(v_dgold * v_run.rift * coalesce(public.idle_val('rift_first_gold_mult'), 0.5));
        if v_rgold > 0 then perform public.apply_currency(p_character, 'dungeon', v_rgold, 0, 0, 0, jsonb_build_object('rift_first', v_run.rift, 'run', v_run.id)); v_dgold := v_dgold + v_rgold; end if;
        if v_run.rift % 5 = 0 then   /* [ANDRAT v5.1211.0] GARANTERAD CHARM BARA VAR FEMTE NIVA per dungeon (Chris: tva charms per rift blev for mycket) */
        v_rr := random() * (coalesce(public.idle_val('charm_w_epic'), 70) + coalesce(public.idle_val('charm_w_legendary'), 25) + coalesce(public.idle_val('charm_w_mythic'), 5));   /* [ANDRAT 2026-10-20] normaliserat som charm_boss_roll */
        v_rck := case when v_rr < coalesce(public.idle_val('charm_w_epic'), 70) then 'broken_charm_epic' when v_rr < coalesce(public.idle_val('charm_w_epic'), 70) + coalesce(public.idle_val('charm_w_legendary'), 25) then 'broken_charm_legendary' else 'broken_charm_mythic' end;
        if public.bag_free(p_character) > 0 or exists (select 1 from public.stacks where character_id = p_character and stack_key = v_rck) then perform public.add_stack(p_character, v_rck, 'item', 1, null);
        else perform public.send_mail(p_character, 'Dungeon Quartermaster', 'Held for you - a broken charm', 'Your backpack was full, so this was set aside. Make room and collect it here.', jsonb_build_array(jsonb_build_object('stack_key', v_rck, 'kind', 'item', 'qty', 1))); end if;
        v_charms := v_charms || to_jsonb(v_rck);
        end if;
        if v_run.rift > v_srv then perform public.rift_chat(coalesce(v_cname, 'Someone') || ' cleared Rift ' || v_run.rift || ' in ' || (select name from public.pve_dungeon_config where id = v_run.dungeon_id) || ' - a new server record!'); end if;
      end if;
      perform public.bump_stat(p_character, 'rift_clears', 1);
    end;
  end if;
  /* [TILLAGT v5.1358.0] MOD CHIPS vid klarat lopp (slutbossen besegrad, ingen dod): Salvaged 3 %, papper Epic 3 % / Legendary 1 % / Mythic 0,4 % (Mythic bara tier 3-4). */
  if v_klar then
    begin v_mc := public.modchip_world_drops(p_character, 'dungeon', coalesce(v_sch_tier, 0), 0, true); exception when others then v_mc := null; end;
  end if;
  update public.pve_dungeon_runs set state = 'claimed', claimed_at = now(),
    died = not v_klar where id = v_run.id;   /* [ANDRAT v5.774.0] heroic, uppdrag och raknare laser died */
  return json_build_object('rift_first', (coalesce(current_setting('genesis.rift_first', true), '') = '1'), 'rift', coalesce(v_run.rift, 0), 'rift_best', (select rift_best from public.characters where id = p_character), 'xp', round(v_xp), 'rep', v_rep, 'scrap', v_scraps, 'credits', v_credits, 'frags', v_frags, 'gold', v_dgold,
    'helper_caches', v_caches,
    'charms', v_charms, 'charms_mailed', (select count(*) from public.mail where character_id = p_character and subject = 'Held for you - a broken charm' and at = now()), 'boss_loot', v_bosses, 'died', v_died, 'klar', v_klar, 'bosses', v_boss,
    'schematic', v_sch_got, 'modchips', v_mc,   /* [TILLAGT v5.1358.0] */
    'used', json_build_object('b', v_ub, 'f', v_uf, 'r', v_ur),
    'packed', json_build_object('b', v_run.sup_bandage, 'f', v_run.sup_fak, 'r', v_run.sup_revive),
    'refund', json_build_object('b', greatest(0, v_run.sup_bandage - v_ub),
                                'f', greatest(0, v_run.sup_fak - v_uf),
                                'r', greatest(0, v_run.sup_revive - v_ur)),
    'hp', json_build_object('pct', round(v_new_pct,3), 'max', v_max,
          'cur', greatest(1, floor(v_max * v_new_pct / 100.0))::integer));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.wb_reward(p_event bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_ev public.world_boss_events; v_h public.world_boss_hits; v_top uuid; v_n integer;
  v_rar integer; v_rar2 integer; v_lvl integer; v_key text; v_it public.items; v_gold numeric; v_xp numeric; v_tier integer;
  v_items jsonb; v_body text; v_ck text; v_r numeric; v_we numeric; v_wl numeric; v_wm numeric; v_got_charm boolean; v_got_apex boolean;
  v_mc jsonb;   /* [TILLAGT v5.1358.0] Mod Chip Design (minst 20 slag) */
  v_dead boolean; v_ch public.characters; v_sig_key text; v_sig_fx text; v_sig_base numeric; v_sig_it public.items; v_paper text; v_rmult numeric; v_top_me boolean;
begin
  select * into v_ev from public.world_boss_events where id = p_event for update;
  if not found or v_ev.rewarded_at is not null then return; end if;
  v_dead := v_ev.state = 'dead';
  select count(*) into v_n from public.world_boss_hits where event_id = p_event;
  if v_n >= 3 then
    select profile_id into v_top from public.world_boss_hits where event_id = p_event order by damage desc, first_at asc limit 1;
  end if;
  update public.world_boss_events set rewarded_at = now(), top_profile = v_top where id = p_event;
  select tier into v_tier from public.region_config where id = v_ev.region;
  for v_h in select * from public.world_boss_hits where event_id = p_event loop
  begin   /* [TILLAGT 2026-10-20] felisolering per deltagare */
    select * into v_ch from public.characters where id = v_h.character_id and deleted_at is null;
    if not found then continue; end if;
    if v_h.damage <= 0 then continue; end if;
    v_mc := null;   /* [TILLAGT v5.1358.0] per spelare */
    /* [TILLAGT v5.977.0] WORLDSAVER (Chris 2026-10-20): alla som slog far +10 % guld och XP i en timme - aven om bossen flyr. */
    insert into public.active_boosts (character_id, boost, until, pct)
    values (v_h.character_id, 'worldsaver', now() + make_interval(mins => coalesce(public.idle_val('wb_buff_mins'), 60)::integer),
            coalesce(public.idle_val('wb_buff_pct'), 10))
    on conflict (character_id, boost) do update set until = greatest(public.active_boosts.until, excluded.until), pct = excluded.pct;   /* [v5.900.0 svep 1] noll skada = inget brev */
    v_lvl := least(public.lvl_cap(), greatest(1, public.character_level(v_ch.xp)));
    if v_dead then
      v_rar := public.wb_roll_rarity(v_h.character_id);
      if v_h.attacks_used >= coalesce(public.idle_val('wb_faithful_strikes'), 20)::integer then
        v_rar2 := public.wb_roll_rarity(v_h.character_id); v_rar := greatest(v_rar, v_rar2);
      end if;
      if v_top is not null and v_h.profile_id = v_top then v_rar := least(5, v_rar + 1); end if;
    else
      v_rar := case when v_top is not null and v_h.profile_id = v_top then 1 else 0 end;
    end if;
    v_key := public.pick_item_key_r(v_rar, v_h.character_id);
    v_items := '[]'::jsonb; v_it := null; v_sig_it := null; v_ck := null;   /* [ANDRAT v5.1316.0] nollas per spelare - rapporten visar vad var och en fick */
    if v_key is not null then
      v_it := public.roll_item(v_h.character_id, v_key, v_rar, 1, 'mail', 0, false, v_lvl);
      v_items := v_items || jsonb_build_array(jsonb_build_object('item_id', v_it.id));
    end if;
    /* [TILLAGT v5.903.0] SIGNATURPJAS i world boss-snitt (x1,5, lagst Epic) och ett Master-papper - bara nar bossen FALLER. */
    v_sig_key := null; v_paper := null; v_top_me := (v_top is not null and v_h.profile_id = v_top);
    if v_dead and random() < (case when v_top_me then coalesce(public.idle_val('wb_sig_top_chance'), 0.30) else coalesce(public.idle_val('wb_sig_chance'), 0.15) end) then
      select s.item_key, s.effect_key, e.base into v_sig_key, v_sig_fx, v_sig_base from public.pve_signature_config s left join public.pve_effect_config e on e.key = s.effect_key
       where s.dungeon_id = (select dungeon from public.world_boss_config where key = v_ev.boss_key) and s.boss_ord = (select max(x.boss_ord) from public.pve_signature_config x where x.dungeon_id = s.dungeon_id) order by random() limit 1;
      if v_sig_key is not null then
        v_sig_it := public.roll_item(v_h.character_id, v_sig_key, public.clamp_item_rarity(v_sig_key, greatest(3, v_rar)), 1, 'mail', 0, false, v_lvl);   /* [ANDRAT 2026-10-20] klampad raritet */
        select mult into v_rmult from public.rarity_config where idx = v_sig_it.rarity;
        update public.items set pve_effect = jsonb_build_object('k', v_sig_fx, 'v', round(coalesce(v_sig_base, 0) * coalesce(v_rmult, 1) * coalesce(public.idle_val('wb_sig_mult'), 1.5))::integer) where id = v_sig_it.id;
        v_items := v_items || jsonb_build_array(jsonb_build_object('item_id', v_sig_it.id));
      end if;
    end if;
    if v_dead and random() < coalesce(public.idle_val('wb_paper_chance'), 0.20) then
      v_paper := public.pick_paper(v_h.character_id, public.paper_ranks(public.world_tier(v_h.character_id, coalesce(v_tier, 0)), 'heroic', 0), public.boss_paper_perks(1 + floor(random() * 5)::integer));
      if v_paper is not null then v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', v_paper, 'kind', 'recipe', 'qty', 1)); end if;
    end if;
    /* [TILLAGT v5.1358.0] MOD CHIP DESIGN fran World Boss: minst 20 slag. Epic 4 % / Legendary 1,5 % / Mythic 0,6 %. Inga Salvaged. Pappret laggs i brevet. */
    if coalesce(v_h.attacks_used, 0) >= 20 then
      begin v_mc := public.modchip_world_drops(v_h.character_id, 'worldboss', public.world_tier(v_h.character_id, coalesce(v_tier, 0)), 0, false); exception when others then v_mc := null; end;
      if v_mc->'design'->>'key' is not null then v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', v_mc->'design'->>'key', 'kind', 'item', 'qty', 1)); end if;
    end if;
    v_gold := round(public.expedition_gold(15, public.world_tier(v_h.character_id, coalesce(v_tier, 0))) * 3 * (case when v_dead then 1 else 0.5 end) * (case when v_dead and v_h.sidestep then 1.05 else 1 end));   /* [ANDRAT v5.983.0] Sidestep */
    v_items := v_items || jsonb_build_array(jsonb_build_object('gold', v_gold, 'reason', 'world_boss'));
    if v_dead then v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', 'boss_mark', 'kind', 'item', 'qty', 1)); end if;   /* [TILLAGT 2026-10-20] Boss Mark */
    v_xp := round(public.xp_award(v_lvl, v_lvl, 3) * (case when v_dead then 1 else 0.5 end) * (case when v_dead and v_h.sidestep then 1.05 else 1 end));   /* [ANDRAT v5.983.0] Sidestep */
    perform public.grant_xp(v_h.character_id, v_xp, 'world_boss');
    v_got_charm := false; v_got_apex := false;
    if v_dead then
      if random() < coalesce(public.idle_val('wb_charm_chance'), 0.35) then
        v_we := coalesce(public.idle_val('charm_w_epic'), 70); v_wl := coalesce(public.idle_val('charm_w_legendary'), 25); v_wm := coalesce(public.idle_val('charm_w_mythic'), 5);
        v_r := random() * (v_we + v_wl + v_wm);
        v_ck := case when v_r < v_we then 'broken_charm_epic' when v_r < v_we + v_wl then 'broken_charm_legendary' else 'broken_charm_mythic' end;
        v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', v_ck, 'kind', 'item', 'qty', 1));
        v_got_charm := true;
      end if;
      if random() < (case when v_top is not null and v_h.profile_id = v_top then coalesce(public.idle_val('wb_apex_top_chance'), 0.10) else coalesce(public.idle_val('wb_apex_chance'), 0.03) end) then
        v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', 'apex_charm', 'kind', 'item', 'qty', 1));
        v_got_apex := true;
      end if;
    end if;
    v_body := case when v_dead then v_ev.zone || ' is quiet again. ' || (select name from public.world_boss_config where key = v_ev.boss_key) || ' fell, and you were there'
                   else (select name from public.world_boss_config where key = v_ev.boss_key) || ' escaped, wounded. You fought anyway, and that counts' end
              || ' (' || v_h.attacks_used || (case when v_h.attacks_used = 1 then ' strike, ' else ' strikes, ' end) || to_char(v_h.damage, 'FM999G999G999') || ' damage, ' || v_h.dodged || (case when v_h.dodged = 1 then ' dodge' else ' dodges' end)
              || (case when v_top is not null and v_h.profile_id = v_top then ', top damage!' else '' end) || ').'
              || ' Inside: ' || floor(v_gold / 10000)::integer || 'g ' || floor((v_gold::integer % 10000) / 100)::integer || 's and a piece of gear.'
              || (case when v_got_apex then ' An Apex Charm is in the box.' else '' end)
              || (case when v_got_charm then ' A Broken Charm is in the box.' else '' end)
              || (case when v_sig_key is not null then ' The boss dropped one of its signature pieces!' else '' end)
              || (case when v_paper is not null then ' A schematic is in the box.' else '' end)
              || (case when v_mc->'design'->>'key' is not null then ' A Mod Chip Design is in the box.' else '' end);   /* [TILLAGT v5.1358.0] */
    perform public.send_mail(v_h.character_id, 'World Boss Courier',
      'Spoils of ' || (select name from public.world_boss_config where key = v_ev.boss_key), v_body, v_items);
    update public.world_boss_hits set reward = jsonb_build_object('item_id', v_it.id, 'item_key', v_it.item_key, 'item_rar', v_it.rarity, 'sig_id', v_sig_it.id, 'sig_rar', v_sig_it.rarity, 'charm_key', v_ck, 'mark', v_dead, 'sig', v_sig_key, 'paper', v_paper, 'rarity', v_rar, 'gold', v_gold, 'xp', v_xp, 'charm', v_got_charm, 'apex', v_got_apex, 'modchip_design', v_mc->'design'->>'key', 'top', (v_top is not null and v_h.profile_id = v_top))
      where event_id = p_event and profile_id = v_h.profile_id;
    perform public.bump_stat(v_h.character_id, case when v_dead then 'world_boss_kills' else 'world_boss_fights' end, 1);
  exception when others then
    raise warning 'wb_reward event % profile %: %', p_event, v_h.profile_id, sqlerrm;
    begin perform public.send_mail(v_h.character_id, 'World Boss Courier', 'Spoils delayed', 'Your reward from the World Boss could not be packed. The team has been told and will send it by hand.', '[]'::jsonb); exception when others then null; end;
  end;
  end loop;
end $function$
;

-- ============================================================================
-- 8. inspect_player: socket och chip foljer med i Inspect
-- ============================================================================
CREATE OR REPLACE FUNCTION public.inspect_player(p_handle text, p_char uuid DEFAULT NULL::uuid)
 RETURNS json
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_p public.profiles; v_ch public.characters; v_g public.guilds; v_seen timestamptz; v_it public.items; v_gc public.gem_config;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode='P0001'; end if;
  if public.handle_check(p_handle) is not null then
    raise exception 'handle_characters' using errcode='P0001';
  end if;
  select * into v_p from public.profiles
   where handle_key = public.handle_norm(p_handle) and not banned;
  if not found then raise exception 'player_not_found' using errcode='P0001'; end if;
  if p_char is not null then
    select * into v_ch from public.characters
     where id = p_char and profile_id = v_p.id and deleted_at is null;
  end if;
  if v_ch.id is null then
    select * into v_ch from public.characters
     where profile_id = v_p.id and deleted_at is null
     order by last_seen_at desc nulls last limit 1;
  end if;
  if v_ch.id is null then raise exception 'player_not_found' using errcode='P0001'; end if;
  v_seen := v_ch.last_seen_at;
  select g.* into v_g from public.guild_members m join public.guilds g on g.id = m.guild_id
   where m.character_id = v_ch.id;
  /* [TILLAGT v5.996.0] Stenen (slot 14) for statsraden Gem. */
  select * into v_it from public.items where character_id = v_ch.id and location = 'equipped' and slot_idx = 14;
  if v_it.id is not null then select * into v_gc from public.gem_config where region_id = v_it.gem_region; end if;
  return json_build_object(
    'handle', v_p.handle, 'avatar', v_p.avatar, 'name', v_ch.name, 'char_id', v_ch.id,
    'level', case when v_ch.xp is null then null else public.character_level(v_ch.xp) end,
    'paragon', v_ch.paragon, 'class_id', v_ch.class_id,
    'guild_tag', v_g.tag, 'guild_name', v_g.name,
    'title', public.title_of_profile(v_p.id),   /* [TILLAGT 2026-10-21] vald titel fran achievements */
    'online', (v_seen is not null and v_seen > now() - interval '3 minutes'),
    /* [TILLAGT v5.996.0] ALLT KLIENTEN BEHOVER FOR ATT RAKNA STATSRUTAN SOM SIN EGEN (Chris: stats och hjalpare i Inspect).
       Ravarorna skickas, inte fardiga tal - sa rutan raknar med exakt samma kod som ens egen statsruta. */
    'xp', v_ch.xp, 'region', v_ch.region,
    'pets', coalesce((select json_agg(json_build_object('id', p.id, 'species', p.species, 'rarity', p.rarity, 'affixes', p.affixes,
               'xp', p.xp, 'nickname', p.nickname, 'team_slot', p.team_slot, 'shiny', p.shiny) order by p.team_slot)
             from public.pets p where p.character_id = v_ch.id and p.team_slot is not null), '[]'::json),
    'skills', coalesce((select json_agg(json_build_object('prof', s.prof, 'tier', s.tier, 'node', s.node, 'ranks', s.ranks))
             from public.character_skills s where s.character_id = v_ch.id and s.ranks > 0), '[]'::json),
    'paragon_nodes', coalesce((select json_agg(json_build_object('node', c.node, 'effect', c.effect, 'per_point', c.per_point, 'points', cp.points))
             from public.character_paragon cp join public.paragon_config c on c.node = cp.node
             where cp.character_id = v_ch.id and cp.points > 0), '[]'::json),
    'gem', case when v_it.id is null then null else json_build_object('key', v_it.item_key, 'pct_key', v_gc.pct_key, 'pct', v_it.gem_pct) end,
    'boosts', coalesce((select json_agg(json_build_object('boost', b.boost, 'pct', b.pct, 'until_ms', (extract(epoch from b.until) * 1000)::bigint))
             from public.active_boosts b where b.character_id = v_ch.id and b.until > now()), '[]'::json),
    'rep', coalesce((select json_object_agg(r.region, r.rep_secs) from public.character_regions r where r.character_id = v_ch.id), '{}'::json),
    'gear', coalesce((
      select json_agg(json_build_object('slot_idx', i.slot_idx,
               'item_key', i.item_key, 'rarity', i.rarity,
               'item_level', i.item_level, 'god_roll', i.god_roll, 'crafted', i.crafted,
               'hp', i.hp, 'power', i.power, 'damage', i.damage, 'affixes', i.affixes,
               'pve_effect', i.pve_effect, 'tune_count', i.tune_count, 'charmed', i.charmed, 'apex', i.apex, 'skin', i.skin,
               'gem_region', i.gem_region, 'gem_pct', i.gem_pct, 'gem_good', i.gem_good,
               'mod_socket', i.mod_socket, 'mod_chip', i.mod_chip)
               order by i.slot_idx)
        from public.items i
       where i.character_id = v_ch.id and i.location = 'equipped'
    ), '[]'::json));
end $function$
;
