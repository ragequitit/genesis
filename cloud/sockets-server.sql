-- ============================================================================
-- GENESIS v5.1358.0 — SOCKETS: Sockets och Mod Chips (v1)
-- ============================================================================
-- Kors i Supabase SQL Editor pa projektet genesis, i ETT svep (hela filen). Bara CREATE OR REPLACE / INSERT ... ON CONFLICT /
-- ALTER TABLE ADD COLUMN IF NOT EXISTS - ingen DROP, inget som tar bort data. Gar att kora flera ganger.
-- [ANDRAT 2026-10-30, sammanslagning med main v5.1370.0] De 17 funktioner som ANDRAS kopieras inte langre in hela:
-- blocket SIST i filen hamtar serverns nuvarande kod och byter exakta ankare (cloud/sockets-anchors.md, base64 i filen).
-- Saknas ett ankare avbryts allt. Darfor kan main (Halloween m.fl.) andra funktionerna utan att sockets skriver over dem.
-- can_be_traded och buyback_take star kvar hela (oforandrade pa servern sedan 2026-10-29, kollat).
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
/* Stapelvaror kan vara bundna (Socket Press). Materialen hade bop redan; stapelvarorna saknade det. */
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
  ('dgspeed', 'dgspeed', 'Dungeon Speed', 'sapphire', 12, array[0.9, 1.1, 1.5, 2.0]),
  ('luck',    'luck',    'Loot Luck',     'amethyst', 20, array[0.5, 1.0, 1.5, 2.0])   /* [TILLAGT 2026-10-30] Chris: lagre tal, tak 20 % fran chip */
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
  ('design_modchip_luck_epic',         3, array['luck'],    8),
  ('design_modchip_crit_legendary',    4, array['crit'],    12),
  ('design_modchip_critdmg_legendary', 4, array['critdmg'], 12),
  ('design_modchip_gold_legendary',    4, array['gold'],    12),
  ('design_modchip_dgspeed_legendary', 4, array['dgspeed'], 12),
  ('design_modchip_luck_legendary',    4, array['luck'],    12),
  ('design_modchip_mythic_crit_critdmg',    5, array['crit','critdmg'],    16),
  ('design_modchip_mythic_crit_gold',       5, array['crit','gold'],       16),
  ('design_modchip_mythic_crit_dgspeed',    5, array['crit','dgspeed'],    16),
  ('design_modchip_mythic_critdmg_gold',    5, array['critdmg','gold'],    16),
  ('design_modchip_mythic_critdmg_dgspeed', 5, array['critdmg','dgspeed'], 16),
  ('design_modchip_mythic_gold_dgspeed',    5, array['gold','dgspeed'],    16),
  ('design_modchip_mythic_crit_luck',       5, array['crit','luck'],       16),
  ('design_modchip_mythic_critdmg_luck',    5, array['critdmg','luck'],    16),
  ('design_modchip_mythic_gold_luck',       5, array['gold','luck'],       16),
  ('design_modchip_mythic_dgspeed_luck',    5, array['dgspeed','luck'],    16)
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
  ('modchip_luck_rare',         'Loot Luck Mod Chip',     15, '{2}', null, '{}', false, null),
  ('modchip_luck_epic',         'Loot Luck Mod Chip',     15, '{3}', null, '{}', false, null),
  ('modchip_luck_legendary',    'Loot Luck Mod Chip',     15, '{4}', null, '{}', false, null),
  ('modchip_luck_mythic',       'Loot Luck Mod Chip',     15, '{5}', null, '{}', false, null),
  ('salvaged_modchip',          'Salvaged Mod Chip',      15, '{2,3}', null, '{}', false, null)
  on conflict (key) do nothing;

/* Stapelvarorna: borren (bunden, saljs inte = kan inte laggas pa auktion), extraktorerna (saljbara) och pappren (saljbara). */
insert into public.stack_item_config (key, name, sell, vendor_sells, bop) values
  ('socket_drill',             'Socket Press',             0,      false, true),
  ('chip_extractor_rare',      'Chip Extractor (Rare)',      5000,  false, false),
  ('chip_extractor_epic',      'Chip Extractor (Epic)',      15000, false, false),
  ('chip_extractor_legendary', 'Chip Extractor (Legendary)', 40000, false, false),
  ('chip_extractor_mythic',    'Chip Extractor (Mythic)',    100000,false, false),
  ('design_modchip_crit_epic',         'Epic Mod Chip Design: Crit Chance',        45000,  false, false),
  ('design_modchip_critdmg_epic',      'Epic Mod Chip Design: Crit Damage',        45000,  false, false),
  ('design_modchip_gold_epic',         'Epic Mod Chip Design: Gold Find',          45000,  false, false),
  ('design_modchip_dgspeed_epic',      'Epic Mod Chip Design: Dungeon Speed',      45000,  false, false),
  ('design_modchip_luck_epic',         'Epic Mod Chip Design: Loot Luck',          45000,  false, false),
  ('design_modchip_crit_legendary',    'Legendary Mod Chip Design: Crit Chance',   120000, false, false),
  ('design_modchip_critdmg_legendary', 'Legendary Mod Chip Design: Crit Damage',   120000, false, false),
  ('design_modchip_gold_legendary',    'Legendary Mod Chip Design: Gold Find',     120000, false, false),
  ('design_modchip_dgspeed_legendary', 'Legendary Mod Chip Design: Dungeon Speed', 120000, false, false),
  ('design_modchip_luck_legendary',    'Legendary Mod Chip Design: Loot Luck',     120000, false, false),
  ('design_modchip_mythic_crit_critdmg',    'Mythic Mod Chip Design: Crit Chance or Crit Damage',   320000, false, false),
  ('design_modchip_mythic_crit_gold',       'Mythic Mod Chip Design: Crit Chance or Gold Find',     320000, false, false),
  ('design_modchip_mythic_crit_dgspeed',    'Mythic Mod Chip Design: Crit Chance or Dungeon Speed', 320000, false, false),
  ('design_modchip_mythic_critdmg_gold',    'Mythic Mod Chip Design: Crit Damage or Gold Find',     320000, false, false),
  ('design_modchip_mythic_critdmg_dgspeed', 'Mythic Mod Chip Design: Crit Damage or Dungeon Speed', 320000, false, false),
  ('design_modchip_mythic_gold_dgspeed',    'Mythic Mod Chip Design: Gold Find or Dungeon Speed',   320000, false, false),
  ('design_modchip_mythic_crit_luck',       'Mythic Mod Chip Design: Crit Chance or Loot Luck',     320000, false, false),
  ('design_modchip_mythic_critdmg_luck',    'Mythic Mod Chip Design: Crit Damage or Loot Luck',     320000, false, false),
  ('design_modchip_mythic_gold_luck',       'Mythic Mod Chip Design: Gold Find or Loot Luck',       320000, false, false),
  ('design_modchip_mythic_dgspeed_luck',    'Mythic Mod Chip Design: Dungeon Speed or Loot Luck',   320000, false, false)
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
  ('cr_jc_modchip_luck_rare',         'jewelcrafter', 'Rare Loot Luck Mod Chip',          'modchip_luck_rare',         2, 'known', '{"amethyst":10,"quartz_crystal":10,"charged_scrap":4}', 1,  null, 2, null, 150,  1),
  ('cr_jc_modchip_luck_epic',         'jewelcrafter', 'Epic Loot Luck Mod Chip',          'modchip_luck_epic',         3, 'drop',  '{"amethyst":25,"prism_crystal":10,"phase_scrap":4}',    8,  null, 3, null, 350,  1),
  ('cr_jc_modchip_luck_legendary',    'jewelcrafter', 'Legendary Loot Luck Mod Chip',     'modchip_luck_legendary',    4, 'drop',  '{"amethyst":60,"signal_crystal":10,"phase_crystal":5,"phase_scrap":8}', 12, null, 4, null, 800,  1),
  ('cr_jc_modchip_luck_mythic',       'jewelcrafter', 'Mythic Loot Luck Mod Chip',        'modchip_luck_mythic',       5, 'drop',  '{"amethyst":140,"phase_crystal":10,"genesis_crystal":4,"phase_scrap":16}', 16, null, 5, null, 1500, 1),
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
revoke execute on function public.mod_chip_bonus(uuid, text) from authenticated; -- [ANDRAT] intern hjalpare: anropas bara fran andra serverfunktioner, aldrig av spelaren direkt

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
revoke execute on function public.socket_roll(uuid, integer, integer, public.item_location, boolean) from authenticated; -- [ANDRAT] intern hjalpare: anropas bara fran andra serverfunktioner, aldrig av spelaren direkt

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
revoke execute on function public.modchip_make(uuid, text, integer, text, text, public.item_location, numeric) from authenticated; -- [ANDRAT] intern hjalpare: anropas bara fran andra serverfunktioner, aldrig av spelaren direkt

-- ============================================================================
-- 3. Andrade funktioner: gear_bonus, roll_item, trg_loot_announce_item, chat_snapshot_item, can_be_traded
-- ============================================================================
/* [ANDRAT vid sammanslagning 2026-10-30] gear_bonus lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] roll_item lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] trg_loot_announce_item lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] chat_snapshot_item lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

CREATE OR REPLACE FUNCTION public.can_be_traded(p_item uuid DEFAULT NULL::uuid, p_stack_key text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
/* EN kalla for auktion, post och byteshandel. [ANDRAT v5.1358.0] Tre nya regler:
   - en BUNDEN pjas (borrad, Salvaged chip, uttaget/fusionerat chip) ar Bind on Pickup;
   - en pjas med ett ISATT chip kan inte lamna kontot forran chipet ar uttaget (chip_inserted);
   - en bunden stapelvara (Socket Press, stack_item_config.bop) ar ocksa Bind on Pickup. */
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
/* [ANDRAT vid sammanslagning 2026-10-30] sell_item lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] salvage_item lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] equip_item lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] tune_item lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] charm_apply lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] transmog_apply lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

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
revoke execute on function public.salvaged_modchip_drop(uuid) from authenticated; -- [ANDRAT] intern hjalpare: anropas bara fran andra serverfunktioner, aldrig av spelaren direkt

/* [TILLAGT v5.1358.0] ETT MOD CHIP DESIGN FALLER. Epic/Legendary: sorten slumpas. Mythic: tva sorter slumpas (den som lar sig
   valjer) och en chattrad skrivs i General (sender_tag LOOT, ingen lank). p_deliver=false ger bara nyckeln (World Boss
   lagger den i brevet sjalv). Alla kan hitta - yrket kravs forst nar man laser. */
create or replace function public.modchip_design_drop(p_character uuid, p_rar integer, p_deliver boolean default true)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_key text; v_a text; v_b text; v_mailed boolean := false; v_ord text[] := array['crit','critdmg','gold','dgspeed','luck'];   /* [ANDRAT 2026-10-30] + luck, samma ordning som klientens MODCHIP_SORTS */
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
revoke execute on function public.modchip_design_drop(uuid, integer, boolean) from authenticated; -- [ANDRAT] intern hjalpare: anropas bara fran andra serverfunktioner, aldrig av spelaren direkt

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
revoke execute on function public.modchip_world_drops(uuid, text, integer, numeric, boolean) from authenticated; -- [ANDRAT] intern hjalpare: anropas bara fran andra serverfunktioner, aldrig av spelaren direkt

-- ============================================================================
-- 7. Andrade: craft_output, wb_marks_redeem, pve_fight, claim_expedition, pve_dungeon_claim, wb_reward
-- ============================================================================
/* [ANDRAT vid sammanslagning 2026-10-30] craft_output lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] wb_marks_redeem lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] pve_fight lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] claim_expedition lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] pve_dungeon_claim lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

/* [ANDRAT vid sammanslagning 2026-10-30] wb_reward lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

-- ============================================================================
-- 8. inspect_player: socket och chip foljer med i Inspect
-- ============================================================================
/* [ANDRAT vid sammanslagning 2026-10-30] inspect_player lappas fran serverns nuvarande kod i blocket sist i filen (ankare i sockets-anchors.md). */

-- ============================================================================
-- 9. LAPPAR serverns nuvarande funktioner (gear_bonus ... inspect_player) med ankarna
-- ============================================================================
/* Lappar serverns nuvarande funktioner med ankarna i cloud/sockets-anchors.md (base64 sa inga backstreck far tolkas om). Avbryter om ett ankare saknas. */
do $patch$
declare r record; v_oid oid; v_def text; v_a text; v_r text; v_cur text := ''; v_fns text[] := '{}';
begin
  for r in with t as (select row_number() over () n, x.* from (values
('gear_bonus','ICApLCAwKQogICsgY2FzZSBwX2tleQ==','ICApLCAwKQogICsgcHVibGljLm1vZF9jaGlwX2JvbnVzKHBfY2hhcmFjdGVyLCBwX2tleSkgICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIE1vZCBDaGlwcyBtZWQgc29ydGVucyB0YWsgLSBzZSBtb2RfY2hpcF9ib251cyAqLwogICsgY2FzZSBwX2tleQ=='),
('roll_item','ICB2X2NoYW5jZSBudW1lcmljOyB2X2hpdHMgaW50ZWdlciA6PSAwOyB2X2Jlc3QgbnVtZXJpYzsKYmVnaW4=','ICB2X2NoYW5jZSBudW1lcmljOyB2X2hpdHMgaW50ZWdlciA6PSAwOyB2X2Jlc3QgbnVtZXJpYzsKICB2X3NvY2sgYm9vbGVhbiA6PSBmYWxzZTsgICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIHNvY2tldCBwYSBwamFzZW4gKi8KYmVnaW4='),
('roll_item','ICBpZiBub3QgKHZfciA9IGFueSh2X2l0ZW0ucmFyaXRpZXMpKSB0aGVuCiAgICByYWlzZSBleGNlcHRpb24gJ2l0ZW1fbm90X2F2YWlsYWJsZV9pbl9yYXJpdHknIHVzaW5nIGVycmNvZGU9J1AwMDAxJzsKICBlbmQgaWY7Cg==','ICBpZiBub3QgKHZfciA9IGFueSh2X2l0ZW0ucmFyaXRpZXMpKSB0aGVuCiAgICByYWlzZSBleGNlcHRpb24gJ2l0ZW1fbm90X2F2YWlsYWJsZV9pbl9yYXJpdHknIHVzaW5nIGVycmNvZGU9J1AwMDAxJzsKICBlbmQgaWY7CiAgLyogW1RJTExBR1QgdjUuMTM1OC4wXSBFdHQgTW9kIENoaXAgcnVsbGFzIGFsZHJpZyBzb20gZ2VhciAtIGRldCBnb3JzIGF2IG1vZGNoaXBfbWFrZS4gKi8KICBpZiB2X2l0ZW0uc2xvdF9pZHggPSAxNSB0aGVuIHJhaXNlIGV4Y2VwdGlvbiAndXNlX21vZGNoaXBfbWFrZScgdXNpbmcgZXJyY29kZT0nUDAwMDEnOyBlbmQgaWY7Cg=='),
('roll_item','ICBpbnNlcnQgaW50byBwdWJsaWMuaXRlbXMgKGNoYXJhY3Rlcl9pZCwgaXRlbV9rZXksIHJhcml0eSwgYWZmaXhlcywgaHAsIGdvbGRfdmFsdWUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjcmFmdGVkLCBsb2NhdGlvbiwgc2xvdF9pZHgsIHBvd2VyLCBkYW1hZ2UsIGl0ZW1fbGV2ZWwsIGdvZF9yb2xsKQogIHZhbHVlcyAocF9jaGFyYWN0ZXIsIHBfaXRlbV9rZXksIHZfciwgdl9hZmYsIHZfaHAsIHZfZ29sZCwKICAgICAgICAgIHZfbWFkZSwgcF9sb2NhdGlvbiwgbnVsbCwgdl9wb3dlciwgdl9kbWcsIHZfbHZsLCB2X2dvZCk=','ICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIFNPQ0tFVEVOIFJVTExBUyBGT1JFIElOU0VSVCBzYSB0cmdfbG9vdF9hbm5vdW5jZV9pdGVtIHNlciBkZW4gKGNoYXR0cmFkZW4gJ3dpdGggYSBzb2NrZXQnKS4gKi8KICB2X3NvY2sgOj0gcHVibGljLnNvY2tldF9yb2xsKHBfY2hhcmFjdGVyLCB2X3IsIHZfaXRlbS5zbG90X2lkeCwgcF9sb2NhdGlvbiwgdl9tYWRlKTsKICBpbnNlcnQgaW50byBwdWJsaWMuaXRlbXMgKGNoYXJhY3Rlcl9pZCwgaXRlbV9rZXksIHJhcml0eSwgYWZmaXhlcywgaHAsIGdvbGRfdmFsdWUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjcmFmdGVkLCBsb2NhdGlvbiwgc2xvdF9pZHgsIHBvd2VyLCBkYW1hZ2UsIGl0ZW1fbGV2ZWwsIGdvZF9yb2xsLCBtb2Rfc29ja2V0KQogIHZhbHVlcyAocF9jaGFyYWN0ZXIsIHBfaXRlbV9rZXksIHZfciwgdl9hZmYsIHZfaHAsIHZfZ29sZCwKICAgICAgICAgIHZfbWFkZSwgcF9sb2NhdGlvbiwgbnVsbCwgdl9wb3dlciwgdl9kbWcsIHZfbHZsLCB2X2dvZCwgdl9zb2NrKQ=='),
('trg_loot_announce_item','ICBpZiBuZXcucmFyaXR5ID49IDMgYW5kIG5ldy5sb2NhdGlvbiBpbiAoJ2JhZycsJ2VxdWlwcGVkJywnbWFpbCcpIGFuZCBuZXcuZ2VtX3JlZ2lvbiBpcyBudWxsCiAgICAgYW5kIGNvYWxlc2NlKGN1cnJlbnRfc2V0dGluZygnZ2VuZXNpcy5jcmFmdGluZycsIHRydWUpLCAnJykgPD4gJ29uJyB0aGVu','ICAvKiBbQU5EUkFUIHY1LjEzNTguMF0gQ2hpcHMgKHBsYXRzIDE1KSBhbm5vbnNlcmFzIGFsZHJpZyAtIGV0dCB0aWxsdmVya2F0IEVwaWMtY2hpcCBhciBpbmdldCBmeW5kLiAqLwogIGlmIG5ldy5yYXJpdHkgPj0gMyBhbmQgbmV3LmxvY2F0aW9uIGluICgnYmFnJywnZXF1aXBwZWQnLCdtYWlsJykgYW5kIG5ldy5nZW1fcmVnaW9uIGlzIG51bGwKICAgICBhbmQgY29hbGVzY2UoY3VycmVudF9zZXR0aW5nKCdnZW5lc2lzLmNyYWZ0aW5nJywgdHJ1ZSksICcnKSA8PiAnb24nCiAgICAgYW5kIG5vdCBleGlzdHMgKHNlbGVjdCAxIGZyb20gcHVibGljLml0ZW1fY29uZmlnIGljIHdoZXJlIGljLmtleSA9IG5ldy5pdGVtX2tleSBhbmQgaWMuc2xvdF9pZHggPSAxNSkgdGhlbg=='),
('trg_loot_announce_item','ICAgICAgICAgICAgICdmb3VuZCAnIHx8IGNhc2Ugd2hlbiBuZXcucmFyaXR5ID49IDUgdGhlbiAnYSBNeXRoaWMnIHdoZW4gbmV3LnJhcml0eSA9IDQgdGhlbiAnYSBMZWdlbmRhcnknIGVsc2UgJ2FuIEVwaWMnIGVuZCB8fCAnIGl0ZW06IFtbaXRlbV1dIScs','ICAgICAgICAgICAgIC8qIFtBTkRSQVQgdjUuMTM1OC4wXSBMZWdlbmRhcnkvTXl0aGljIE1FRCBzb2NrZXQgc2FncyBpIHJhZGVuIChDaHJpcykuIEVwaWMgbWVkIHNvY2tldCBmYXIgYmFyYSBnbGltdGVuIHBhIGtvcnRldC4gKi8KICAgICAgICAgICAgICdmb3VuZCAnIHx8IGNhc2Ugd2hlbiBuZXcucmFyaXR5ID49IDUgdGhlbiAnYSBNeXRoaWMnIHdoZW4gbmV3LnJhcml0eSA9IDQgdGhlbiAnYSBMZWdlbmRhcnknIGVsc2UgJ2FuIEVwaWMnIGVuZAogICAgICAgICAgICAgICAgICAgICAgfHwgY2FzZSB3aGVuIG5ldy5tb2Rfc29ja2V0IGFuZCBuZXcucmFyaXR5ID49IDQgdGhlbiAnIGl0ZW0gd2l0aCBhIHNvY2tldDogW1tpdGVtXV0hJyBlbHNlICcgaXRlbTogW1tpdGVtXV0hJyBlbmQs'),
('trg_loot_announce_item','J3B2ZScsbmV3LnB2ZV9lZmZlY3QsJ3NvY2tldCcsbmV3LnNvY2tldF9raW5kLCd0dW5lJyxuZXcudHVuZV9jb3VudCwnY3JhZnRlZCcsbmV3LmNyYWZ0ZWQpKQ==','J3B2ZScsbmV3LnB2ZV9lZmZlY3QsJ3NvY2tldCcsbmV3LnNvY2tldF9raW5kLCd0dW5lJyxuZXcudHVuZV9jb3VudCwnY3JhZnRlZCcsbmV3LmNyYWZ0ZWQsCiAgICAgICAgICAgICAgICdtb2Rfc29ja2V0JyxuZXcubW9kX3NvY2tldCwnbW9kX2NoaXAnLG5ldy5tb2RfY2hpcCkp'),
('chat_snapshot_item','J2dlbScsdi5nZW1fcmVnaW9uLCdnZW1fcGN0Jyx2LmdlbV9wY3Qs','J21vZF9zb2NrZXQnLHYubW9kX3NvY2tldCwnbW9kX2NoaXAnLHYubW9kX2NoaXAsCiAgICAnZ2VtJyx2LmdlbV9yZWdpb24sJ2dlbV9wY3QnLHYuZ2VtX3BjdCw='),
('inspect_player','J2dlbV9yZWdpb24nLCBpLmdlbV9yZWdpb24sICdnZW1fcGN0JywgaS5nZW1fcGN0LCAnZ2VtX2dvb2QnLCBpLmdlbV9nb29kKQ==','J2dlbV9yZWdpb24nLCBpLmdlbV9yZWdpb24sICdnZW1fcGN0JywgaS5nZW1fcGN0LCAnZ2VtX2dvb2QnLCBpLmdlbV9nb29kLAogICAgICAgICAgICAgICAnbW9kX3NvY2tldCcsIGkubW9kX3NvY2tldCwgJ21vZF9jaGlwJywgaS5tb2RfY2hpcCk='),
('sell_item','ICBpZiB2X2l0LmZhdm9yaXRlIHRoZW4gcmFpc2UgZXhjZXB0aW9uICdpdGVtX2Zhdm9yaXRlJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsgICAvKiBbVElMTEFHVCB2NS4xMjEzLjBdIGZhdm9yaXRzdGphcm5hbiBza3lkZGFyIChDaHJpcykgKi8K','ICBpZiB2X2l0LmZhdm9yaXRlIHRoZW4gcmFpc2UgZXhjZXB0aW9uICdpdGVtX2Zhdm9yaXRlJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsgICAvKiBbVElMTEFHVCB2NS4xMjEzLjBdIGZhdm9yaXRzdGphcm5hbiBza3lkZGFyIChDaHJpcykgKi8KICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIEVuIHBqYXMgbWVkIGlzYXR0IGNoaXAgc2FsanMvc2tyb3RhcyBpbnRlIGZvcnJhbiBjaGlwZXQgYXIgdXR0YWdldCAoQ2hyaXMpLiAqLwogIGlmIHZfaXQubW9kX2NoaXAgaXMgbm90IG51bGwgdGhlbiByYWlzZSBleGNlcHRpb24gJ2NoaXBfaW5zZXJ0ZWQnIHVzaW5nIGVycmNvZGU9J1AwMDAxJzsgZW5kIGlmOwo='),
('salvage_item','ICBpZiB2X2l0LmZhdm9yaXRlIHRoZW4gcmFpc2UgZXhjZXB0aW9uICdpdGVtX2Zhdm9yaXRlJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsgICAvKiBbVElMTEFHVCB2NS4xMjEzLjBdICovCg==','ICBpZiB2X2l0LmZhdm9yaXRlIHRoZW4gcmFpc2UgZXhjZXB0aW9uICdpdGVtX2Zhdm9yaXRlJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsgICAvKiBbVElMTEFHVCB2NS4xMjEzLjBdICovCiAgLyogW1RJTExBR1QgdjUuMTM1OC4wXSBFbiBwamFzIG1lZCBpc2F0dCBjaGlwIHNhbGpzL3Nrcm90YXMgaW50ZSBmb3JyYW4gY2hpcGV0IGFyIHV0dGFnZXQgKENocmlzKS4gKi8KICBpZiB2X2l0Lm1vZF9jaGlwIGlzIG5vdCBudWxsIHRoZW4gcmFpc2UgZXhjZXB0aW9uICdjaGlwX2luc2VydGVkJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsKICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIEV0dCBNb2QgQ2hpcCAocGxhdHMgMTUpIGFyIGludGUgZ2VhcjogZGV0IHNhdHRzIGkgZW4gc29ja2V0LCBhbGRyaWcgcGEga3JvcHBlbi4gKi8KICBpZiBleGlzdHMgKHNlbGVjdCAxIGZyb20gcHVibGljLml0ZW1fY29uZmlnIGljIHdoZXJlIGljLmtleSA9IHZfaXQuaXRlbV9rZXkgYW5kIGljLnNsb3RfaWR4ID0gMTUpIHRoZW4gcmFpc2UgZXhjZXB0aW9uICdjaGlwX25vdF9nZWFyJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsK'),
('equip_item','ICBpZiBub3QgZm91bmQgdGhlbiByYWlzZSBleGNlcHRpb24gJ2l0ZW1fbm90X2ZvdW5kJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsK','ICBpZiBub3QgZm91bmQgdGhlbiByYWlzZSBleGNlcHRpb24gJ2l0ZW1fbm90X2ZvdW5kJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsKICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIEV0dCBNb2QgQ2hpcCAocGxhdHMgMTUpIGFyIGludGUgZ2VhcjogZGV0IHNhdHRzIGkgZW4gc29ja2V0LCBhbGRyaWcgcGEga3JvcHBlbi4gKi8KICBpZiBleGlzdHMgKHNlbGVjdCAxIGZyb20gcHVibGljLml0ZW1fY29uZmlnIGljIHdoZXJlIGljLmtleSA9IHZfaXQuaXRlbV9rZXkgYW5kIGljLnNsb3RfaWR4ID0gMTUpIHRoZW4gcmFpc2UgZXhjZXB0aW9uICdjaGlwX25vdF9nZWFyJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsK'),
('tune_item','ICBpZiBub3QgZm91bmQgdGhlbiByYWlzZSBleGNlcHRpb24gJ2l0ZW1fbm90X2ZvdW5kJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsK','ICBpZiBub3QgZm91bmQgdGhlbiByYWlzZSBleGNlcHRpb24gJ2l0ZW1fbm90X2ZvdW5kJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsKICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIEV0dCBNb2QgQ2hpcCAocGxhdHMgMTUpIGFyIGludGUgZ2VhcjogZGV0IHNhdHRzIGkgZW4gc29ja2V0LCBhbGRyaWcgcGEga3JvcHBlbi4gKi8KICBpZiBleGlzdHMgKHNlbGVjdCAxIGZyb20gcHVibGljLml0ZW1fY29uZmlnIGljIHdoZXJlIGljLmtleSA9IHZfaXQuaXRlbV9rZXkgYW5kIGljLnNsb3RfaWR4ID0gMTUpIHRoZW4gcmFpc2UgZXhjZXB0aW9uICdjaGlwX25vdF9nZWFyJyB1c2luZyBlcnJjb2RlPSdQMDAwMSc7IGVuZCBpZjsK'),
('charm_apply','ICBpZiB2X2l0LmdlbV9yZWdpb24gaXMgbm90IG51bGwgb3Igdl9pYy5iYWdfc2xvdHMgaXMgbm90IG51bGwgdGhlbgogICAgcmFpc2UgZXhjZXB0aW9uICdjaGFybV9ub3RfZ2VhcicgdXNpbmcgZXJyY29kZT0nUDAwMDEnOwogIGVuZCBpZjs=','ICBpZiB2X2l0LmdlbV9yZWdpb24gaXMgbm90IG51bGwgb3Igdl9pYy5iYWdfc2xvdHMgaXMgbm90IG51bGwgb3Igdl9pYy5zbG90X2lkeCA9IDE1IHRoZW4gICAvKiBbQU5EUkFUIHY1LjEzNTguMF0gaW50ZSBwYSBldHQgTW9kIENoaXAgKi8KICAgIHJhaXNlIGV4Y2VwdGlvbiAnY2hhcm1fbm90X2dlYXInIHVzaW5nIGVycmNvZGU9J1AwMDAxJzsKICBlbmQgaWY7'),
('transmog_apply','dl9pYy5zbG90X2lkeCBpcyBudWxsIHRoZW4gcmFpc2UgZXhjZXB0aW9uICd0cmFuc21vZ19ub3RfZ2Vhcic=','dl9pYy5zbG90X2lkeCBpcyBudWxsIG9yIHZfaWMuc2xvdF9pZHggPSAxNSB0aGVuIHJhaXNlIGV4Y2VwdGlvbiAndHJhbnNtb2dfbm90X2dlYXIn'),
('craft_output','ICBzZWxlY3QgKiBpbnRvIHZfc3RhY2sgZnJvbSBwdWJsaWMuc3RhY2tfaXRlbV9jb25maWcgd2hlcmUga2V5ID0gdl9yYy5pdGVtX2tleTsKICBpZiBmb3VuZCB0aGVuCiAgICBwZXJmb3JtIHB1YmxpYy5hZGRfc3RhY2socF9jaGFyYWN0ZXIsIHZfcmMuaXRlbV9rZXksICdpdGVtJywgMSwgbnVsbCk7','ICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIE1PRCBDSElQUyBnb3JzIGF2IG1vZGNoaXBfbWFrZSAoZWdldCBydWxsYXQgdmFyZGUgKy01ICUsIG9idW5kZXQpLCBhbGRyaWcgYXYgcm9sbF9pdGVtLiAqLwogIGlmIHZfcmMuaXRlbV9rZXkgbGlrZSAnbW9kY2hpcFxfJScgdGhlbgogICAgdl9pdGVtIDo9IHB1YmxpYy5tb2RjaGlwX21ha2UocF9jaGFyYWN0ZXIsIHZfcmMuaXRlbV9rZXksIHZfcmMucmFyaXR5LCBzcGxpdF9wYXJ0KHZfcmMuaXRlbV9rZXksICdfJywgMiksICdjcmFmdCcsICdiYWcnKTsKICAgIHJldHVybiBqc29uX2J1aWxkX29iamVjdCgnY3JhZnRlZCcsIHZfcmMuaXRlbV9rZXksICdraW5kJywgJ2dlYXInLCAnaXRlbScsIHZfaXRlbS5pZCwgJ3Jhcml0eScsIHZfaXRlbS5yYXJpdHksICdhZmZpeGVzJywgdl9pdGVtLmFmZml4ZXMsICd4cF9nYWluZWQnLCB2X3hwKTsKICBlbmQgaWY7CiAgc2VsZWN0ICogaW50byB2X3N0YWNrIGZyb20gcHVibGljLnN0YWNrX2l0ZW1fY29uZmlnIHdoZXJlIGtleSA9IHZfcmMuaXRlbV9rZXk7CiAgaWYgZm91bmQgdGhlbgogICAgcGVyZm9ybSBwdWJsaWMuYWRkX3N0YWNrKHBfY2hhcmFjdGVyLCB2X3JjLml0ZW1fa2V5LCAnaXRlbScsIDEsIG51bGwpOw=='),
('wb_marks_redeem','ICBlbHNpZiBwX3doYXQgPSAnYnJva2VuX2NoYXJtX215dGhpYycgdGhlbiB2X2Nvc3QgOj0gY29hbGVzY2UocHVibGljLmlkbGVfdmFsKCd3Yl9tYXJrc19jaGFybV9teXRoaWMnKSwgMTApOjppbnRlZ2VyOwo=','ICBlbHNpZiBwX3doYXQgPSAnYnJva2VuX2NoYXJtX215dGhpYycgdGhlbiB2X2Nvc3QgOj0gY29hbGVzY2UocHVibGljLmlkbGVfdmFsKCd3Yl9tYXJrc19jaGFybV9teXRoaWMnKSwgMTApOjppbnRlZ2VyOwogIGVsc2lmIHBfd2hhdCA9ICdzb2NrZXRfZHJpbGwnIHRoZW4gdl9jb3N0IDo9IGNvYWxlc2NlKG51bGxpZihwdWJsaWMuaWRsZV92YWwoJ3NvY2tldF9kcmlsbF9tYXJrcycpLCAwKSwgMTUpOjppbnRlZ2VyOyAgIC8qIFtUSUxMQUdUIHY1LjEzNTguMF0gU29ja2V0IERyaWxsIDE1IG1hcmtzIChDaHJpcyksIGJ1bmRlbiAqLwo='),
('wb_marks_redeem','ICAgICAgcGVyZm9ybSBwdWJsaWMuc2VuZF9tYWlsKHBfY2hhcmFjdGVyLCAnV29ybGQgQm9zcyBDb3VyaWVyJywgJ1lvdXIgQm9zcyBNYXJrIHJld2FyZCcsICdZb3VyIGJhY2twYWNrIHdhcyBmdWxsLCBzbyB0aGUgY2hhcm0gd2FpdHMgaGVyZS4nLCBqc29uYl9idWlsZF9hcnJheShqc29uYl9idWlsZF9vYmplY3QoJ3N0YWNrX2tleScsIHBfd2hhdCwgJ2tpbmQnLCAnaXRlbScsICdxdHknLCAxKSkpOw==','ICAgICAgcGVyZm9ybSBwdWJsaWMuc2VuZF9tYWlsKHBfY2hhcmFjdGVyLCAnV29ybGQgQm9zcyBDb3VyaWVyJywgJ1lvdXIgQm9zcyBNYXJrIHJld2FyZCcsICdZb3VyIGJhY2twYWNrIHdhcyBmdWxsLCBzbyBpdCB3YWl0cyBoZXJlLicsIGpzb25iX2J1aWxkX2FycmF5KGpzb25iX2J1aWxkX29iamVjdCgnc3RhY2tfa2V5JywgcF93aGF0LCAna2luZCcsICdpdGVtJywgJ3F0eScsIDEpKSk7ICAgLyogW0FORFJBVCB2NS4xMzU4LjBdIGF2ZW4gYm9ycmVuICov'),
('pve_fight','ICB2X3RpZXIgaW50ZWdlcjsgdl9jcmVkaXRzIGludGVnZXIgOj0gMDsgdl9lbSBudW1lcmljIDo9IDE7Cg==','ICB2X3RpZXIgaW50ZWdlcjsgdl9jcmVkaXRzIGludGVnZXIgOj0gMDsgdl9lbSBudW1lcmljIDo9IDE7CiAgdl9tYyBqc29uYiA6PSBudWxsOyAgIC8qIFtUSUxMQUdUIHY1LjEzNTguMF0gU2FsdmFnZWQgTW9kIENoaXAgLyBNb2QgQ2hpcCBEZXNpZ24gKi8K'),
('pve_fight','ICAgIHZfc2NyYXBfcXR5IDo9IHJvdW5kKGNvYWxlc2NlKHB1YmxpYy5wdmVfdmFsKCdzY3JhcF9xdHknKSwgMCkK','ICAgIC8qIFtUSUxMQUdUIHY1LjEzNTguMF0gTU9EIENISVBTOiBTYWx2YWdlZCAwLDA1ICUgcGVyIHZpbnN0IChhbGxhIHJlZ2lvbmVyKSwgcGFwcGVyIEVwaWMgMCwwNSAlIChEcmFrZW1hcmsrKSwgTGVnZW5kYXJ5IDAsMDE1ICUgKEN1dGxhc3MgQmF5KyksIE15dGhpYyAwLDAwMyAlIChOb3ZhIENvbW1hbmQrKS4gTG9vdCBMdWNrIHBhdmVya2FyIGludGUuICovCiAgICBiZWdpbiB2X21jIDo9IHB1YmxpYy5tb2RjaGlwX3dvcmxkX2Ryb3BzKHBfY2hhcmFjdGVyLCAnZW5jb3VudGVyJywgY29hbGVzY2Uodl90aWVyLCAwKSwgMCwgdHJ1ZSk7IGV4Y2VwdGlvbiB3aGVuIG90aGVycyB0aGVuIHZfbWMgOj0gbnVsbDsgZW5kOwogICAgdl9zY3JhcF9xdHkgOj0gcm91bmQoY29hbGVzY2UocHVibGljLnB2ZV92YWwoJ3NjcmFwX3F0eScpLCAwKQo='),
('pve_fight','ICAgICAgICAgICdzY2hlbWF0aWMnLCB2X3NjaF9nb3QpIGVuZCk7','ICAgICAgICAgICdzY2hlbWF0aWMnLCB2X3NjaF9nb3QsCiAgICAgICAgICAnbW9kY2hpcHMnLCB2X21jKSBlbmQpOyAgIC8qIFtUSUxMQUdUIHY1LjEzNTguMF0gKi8='),
('claim_expedition','ICB2X3NoYXJkIHRleHQ7IHZfc2hhcmRfZ290IHRleHQgOj0gbnVsbDsgdl9maXJzdF9jbGVhciBib29sZWFuOyB2X2xhcCBqc29uOw==','ICB2X3NoYXJkIHRleHQ7IHZfc2hhcmRfZ290IHRleHQgOj0gbnVsbDsgdl9maXJzdF9jbGVhciBib29sZWFuOyB2X2xhcCBqc29uOwogIHZfbWMganNvbmIgOj0gbnVsbDsgICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIFNhbHZhZ2VkIE1vZCBDaGlwIC8gTW9kIENoaXAgRGVzaWduICov'),
('claim_expedition','ICBpZiBqc29uYl9hcnJheV9sZW5ndGgodl9tYWlsZWQpID4gMCB0aGVuCiAgICBwZXJmb3JtIHB1YmxpYy5zZW5kX21haWwocF9jaGFyYWN0ZXIsICdFeHBlZGl0aW9uIERlcG90Jyw=','ICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIE1PRCBDSElQUzogU2FsdmFnZWQgMSAlLCBwYXBwZXIgMSw1IC8gMCw1IC8gMCwxICUgdmlkIDggaCB0aWVyIDQgLSBza2FsYXIgbWVkIGxhbmdkIG9jaCByZWdpb24uIExvb3QgTHVjayBwYXZlcmthciBpbnRlLiAqLwogIGJlZ2luIHZfbWMgOj0gcHVibGljLm1vZGNoaXBfd29ybGRfZHJvcHMocF9jaGFyYWN0ZXIsICdleHBlZGl0aW9uJywgdl90aWVyLCB2X2RlZi5taW5zLCB0cnVlKTsgZXhjZXB0aW9uIHdoZW4gb3RoZXJzIHRoZW4gdl9tYyA6PSBudWxsOyBlbmQ7CiAgaWYganNvbmJfYXJyYXlfbGVuZ3RoKHZfbWFpbGVkKSA+IDAgdGhlbgogICAgcGVyZm9ybSBwdWJsaWMuc2VuZF9tYWlsKHBfY2hhcmFjdGVyLCAnRXhwZWRpdGlvbiBEZXBvdCcs'),
('claim_expedition','ICAgICdyZWxpYycsIHZfcmVsaWMsICdyZWNpcGUnLCB2X3JlYywgJ21lbG9uJywgdl9tZWxvbiw=','ICAgICdyZWxpYycsIHZfcmVsaWMsICdyZWNpcGUnLCB2X3JlYywgJ21lbG9uJywgdl9tZWxvbiwgJ21vZGNoaXBzJywgdl9tYyw='),
('pve_dungeon_claim','ICB2X2tsYXIgYm9vbGVhbiA6PSBmYWxzZTsgdl9jaGFybXMganNvbmIgOj0gJ1tdJzo6anNvbmI7IHZfY2sgdGV4dDs=','ICB2X2tsYXIgYm9vbGVhbiA6PSBmYWxzZTsgdl9jaGFybXMganNvbmIgOj0gJ1tdJzo6anNvbmI7IHZfY2sgdGV4dDsgdl9tYyBqc29uYiA6PSBudWxsOyAgIC8qIFtUSUxMQUdUIHY1LjEzNTguMF0gTW9kIENoaXBzICov'),
('pve_dungeon_claim','ICB1cGRhdGUgcHVibGljLnB2ZV9kdW5nZW9uX3J1bnMgc2V0IHN0YXRlID0gJ2NsYWltZWQnLCBjbGFpbWVkX2F0ID0gbm93KCks','ICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdIE1PRCBDSElQUyB2aWQga2xhcmF0IGxvcHAgKHNsdXRib3NzZW4gYmVzZWdyYWQsIGluZ2VuIGRvZCk6IFNhbHZhZ2VkIDMgJSwgcGFwcGVyIEVwaWMgMyAlIC8gTGVnZW5kYXJ5IDEgJSAvIE15dGhpYyAwLDQgJSAoTXl0aGljIGJhcmEgdGllciAzLTQpLiAqLwogIGlmIHZfa2xhciB0aGVuCiAgICBiZWdpbiB2X21jIDo9IHB1YmxpYy5tb2RjaGlwX3dvcmxkX2Ryb3BzKHBfY2hhcmFjdGVyLCAnZHVuZ2VvbicsIGNvYWxlc2NlKHZfc2NoX3RpZXIsIDApLCAwLCB0cnVlKTsgZXhjZXB0aW9uIHdoZW4gb3RoZXJzIHRoZW4gdl9tYyA6PSBudWxsOyBlbmQ7CiAgZW5kIGlmOwogIHVwZGF0ZSBwdWJsaWMucHZlX2R1bmdlb25fcnVucyBzZXQgc3RhdGUgPSAnY2xhaW1lZCcsIGNsYWltZWRfYXQgPSBub3coKSw='),
('pve_dungeon_claim','ICAgICdzY2hlbWF0aWMnLCB2X3NjaF9nb3Qs','ICAgICdzY2hlbWF0aWMnLCB2X3NjaF9nb3QsICdtb2RjaGlwcycsIHZfbWMs'),
('wb_reward','ICB2X2l0ZW1zIGpzb25iOyB2X2JvZHkgdGV4dDsgdl9jayB0ZXh0OyB2X3IgbnVtZXJpYzsgdl93ZSBudW1lcmljOyB2X3dsIG51bWVyaWM7IHZfd20gbnVtZXJpYzsgdl9nb3RfY2hhcm0gYm9vbGVhbjsgdl9nb3RfYXBleCBib29sZWFuOw==','ICB2X2l0ZW1zIGpzb25iOyB2X2JvZHkgdGV4dDsgdl9jayB0ZXh0OyB2X3IgbnVtZXJpYzsgdl93ZSBudW1lcmljOyB2X3dsIG51bWVyaWM7IHZfd20gbnVtZXJpYzsgdl9nb3RfY2hhcm0gYm9vbGVhbjsgdl9nb3RfYXBleCBib29sZWFuOwogIHZfbWMganNvbmI7ICAgLyogW1RJTExBR1QgdjUuMTM1OC4wXSBNb2QgQ2hpcCBEZXNpZ24gKG1pbnN0IDIwIHNsYWcpICov'),
('wb_reward','ICAgIGlmIHZfaC5kYW1hZ2UgPD0gMCB0aGVuIGNvbnRpbnVlOyBlbmQgaWY7Cg==','ICAgIGlmIHZfaC5kYW1hZ2UgPD0gMCB0aGVuIGNvbnRpbnVlOyBlbmQgaWY7CiAgICB2X21jIDo9IG51bGw7ICAgLyogW1RJTExBR1QgdjUuMTM1OC4wXSBwZXIgc3BlbGFyZSAqLwo='),
('wb_reward','ICAgIHZfZ29sZCA6PSByb3VuZChwdWJsaWMuZXhwZWRpdGlvbl9nb2xkKDE1LCBwdWJsaWMud29ybGRfdGllcih2X2guY2hhcmFjdGVyX2lkLCBjb2FsZXNjZSh2X3RpZXIsIDApKSkgKiAz','ICAgIC8qIFtUSUxMQUdUIHY1LjEzNTguMF0gTU9EIENISVAgREVTSUdOIGZyYW4gV29ybGQgQm9zczogbWluc3QgMjAgc2xhZy4gRXBpYyA0ICUgLyBMZWdlbmRhcnkgMSw1ICUgLyBNeXRoaWMgMCw2ICUuIEluZ2EgU2FsdmFnZWQuIFBhcHByZXQgbGFnZ3MgaSBicmV2ZXQuICovCiAgICBpZiBjb2FsZXNjZSh2X2guYXR0YWNrc191c2VkLCAwKSA+PSAyMCB0aGVuCiAgICAgIGJlZ2luIHZfbWMgOj0gcHVibGljLm1vZGNoaXBfd29ybGRfZHJvcHModl9oLmNoYXJhY3Rlcl9pZCwgJ3dvcmxkYm9zcycsIHB1YmxpYy53b3JsZF90aWVyKHZfaC5jaGFyYWN0ZXJfaWQsIGNvYWxlc2NlKHZfdGllciwgMCkpLCAwLCBmYWxzZSk7IGV4Y2VwdGlvbiB3aGVuIG90aGVycyB0aGVuIHZfbWMgOj0gbnVsbDsgZW5kOwogICAgICBpZiB2X21jLT4nZGVzaWduJy0+PidrZXknIGlzIG5vdCBudWxsIHRoZW4gdl9pdGVtcyA6PSB2X2l0ZW1zIHx8IGpzb25iX2J1aWxkX2FycmF5KGpzb25iX2J1aWxkX29iamVjdCgnc3RhY2tfa2V5Jywgdl9tYy0+J2Rlc2lnbictPj4na2V5JywgJ2tpbmQnLCAnaXRlbScsICdxdHknLCAxKSk7IGVuZCBpZjsKICAgIGVuZCBpZjsKICAgIHZfZ29sZCA6PSByb3VuZChwdWJsaWMuZXhwZWRpdGlvbl9nb2xkKDE1LCBwdWJsaWMud29ybGRfdGllcih2X2guY2hhcmFjdGVyX2lkLCBjb2FsZXNjZSh2X3RpZXIsIDApKSkgKiAz'),
('wb_reward','ICAgICAgICAgICAgICB8fCAoY2FzZSB3aGVuIHZfcGFwZXIgaXMgbm90IG51bGwgdGhlbiAnIEEgc2NoZW1hdGljIGlzIGluIHRoZSBib3guJyBlbHNlICcnIGVuZCk=','ICAgICAgICAgICAgICB8fCAoY2FzZSB3aGVuIHZfcGFwZXIgaXMgbm90IG51bGwgdGhlbiAnIEEgc2NoZW1hdGljIGlzIGluIHRoZSBib3guJyBlbHNlICcnIGVuZCkKICAgICAgICAgICAgICB8fCAoY2FzZSB3aGVuIHZfbWMtPidkZXNpZ24nLT4+J2tleScgaXMgbm90IG51bGwgdGhlbiAnIEEgTW9kIENoaXAgRGVzaWduIGlzIGluIHRoZSBib3guJyBlbHNlICcnIGVuZCkgICAvKiBbVElMTEFHVCB2NS4xMzU4LjBdICov'),
('wb_reward','J3BhcGVyJywgdl9wYXBlciwgJ3Jhcml0eScsIHZfcmFyLCAnZ29sZCcsIHZfZ29sZCwgJ3hwJywgdl94cCwgJ2NoYXJtJywgdl9nb3RfY2hhcm0sICdhcGV4Jywgdl9nb3RfYXBleCw=','J3BhcGVyJywgdl9wYXBlciwgJ3Jhcml0eScsIHZfcmFyLCAnZ29sZCcsIHZfZ29sZCwgJ3hwJywgdl94cCwgJ2NoYXJtJywgdl9nb3RfY2hhcm0sICdhcGV4Jywgdl9nb3RfYXBleCwgJ21vZGNoaXBfZGVzaWduJywgdl9tYy0+J2Rlc2lnbictPj4na2V5Jyw=')) x(fn,a,r))
    select fn, array_agg(convert_from(decode(a,'base64'),'UTF8') order by n) aa, array_agg(convert_from(decode(t.r,'base64'),'UTF8') order by n) rr from t group by fn order by min(n) loop
    select p.oid into v_oid from pg_proc p join pg_namespace s on s.oid=p.pronamespace where s.nspname='public' and p.proname=r.fn;
    if (select count(*) from pg_proc p join pg_namespace s on s.oid=p.pronamespace where s.nspname='public' and p.proname=r.fn) <> 1 then
      raise exception 'SOCKETS: % finns inte exakt en gang', r.fn; end if;
    v_def := pg_get_functiondef(v_oid);
    /* Redan lappad (filen kord forut)? En funktion lappas alltid hel i ett svep, sa finns forsta ersattningen finns alla. */
    if position(r.rr[1] in v_def) > 0 then v_fns := v_fns || (r.fn || ' (redan)'); continue; end if;
    for i in 1..array_length(r.aa,1) loop
      if position(r.aa[i] in v_def) = 0 then raise exception 'SOCKETS: ankare % i % hittas inte', i, r.fn; end if;
      v_def := replace(v_def, r.aa[i], r.rr[i]);
    end loop;
    execute v_def;
    v_fns := v_fns || r.fn;
  end loop;
  raise notice 'SOCKETS lappade: %', array_to_string(v_fns, ', ');
end $patch$;
