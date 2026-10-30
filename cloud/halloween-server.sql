-- ============================================================================
--  GENESIS v5.1362.0 — HALLOWEEN
--  Sasongsevent (aterbrukbar grund) + Halloween 2026 som forsta event.
-- ============================================================================
--  Kors i Supabase SQL Editor pa projektet genesis, hela filen i ett svep.
--  Bara CREATE TABLE IF NOT EXISTS, CREATE OR REPLACE, INSERT ... ON CONFLICT,
--  ALTER TABLE ... ADD COLUMN IF NOT EXISTS. Ingen DROP. Gar att kora flera ganger.
--
--  Innehall:
--   1. Tabeller: season_events, season_event_shop, season_event_drops, season_event_purchases
--   2. Rader: Halloween 2026 (fonster, mark, butik, droppchanser), stack_item_config (marken),
--      item_config (utseende-setet Jack-o'-Lantern, faller aldrig)
--   3. Nya funktioner: event_now_key, event_state, event_mark_drop, event_shop_buy
--   4. Droppkrokar i pve_fight, claim_expedition, pve_dungeon_claim, wb_reward via
--      event_patch_fn (laser serverns NUVARANDE kod med pg_get_functiondef, byter ut ett
--      ankare, skriver tillbaka). Fungerar BADE med och utan sockets-grenen inlagd -
--      sockets-raderna rors inte. Kors filen igen hoppar den over redan patchade krokar.
--   5. Revokes
--   6. Testblock (spelaranrop under set_config, rullas alltid tillbaka)
--
--  Nasta event = nya rader i season_events / season_event_shop / season_event_drops
--  + nya bilder. Ingen ny kod. Se cloud/HALLOWEEN-README.md.
-- ============================================================================

-- ============================================================================
-- 1. TABELLER
-- ============================================================================

/* [TILLAGT v5.1362.0] SASONGSEVENT. En rad per event. Fonstret ar starts_at..ends_at (UTC);
   enabled=false stanger eventet direkt oavsett fonster. mark_* = eventets valuta (en stack_item_config-rad).
   set_* = utseende-setet: set_prefix ar forledet i item_config-nycklarna (jack_head -> 'jack'), figure_suffix
   ar filen assets/character/set/<figur>_<figure_suffix>.webp, set_min = hur manga delar som maste baras
   for att den stora klassbilden ska visas (5 = alla). */
create table if not exists public.season_events (
  key            text primary key,
  name           text not null,
  tagline        text,
  starts_at      timestamptz not null,
  ends_at        timestamptz not null,
  enabled        boolean not null default true,
  mark_key       text not null,
  mark_name      text not null,
  mark_plural    text not null,
  mark_art       text not null,
  set_name       text,
  set_prefix     text,
  figure_suffix  text,
  set_min        integer not null default 5,
  accent         text,
  flavor         text,
  sort           integer not null default 0
);

/* Butikens varor. kind:
     appearance  payload {"item_key":"jack_head","slot":0}   -> rad i character_appearances (utseende, bundet, aldrig saljbart)
     gear        payload {"rarity":4,"up_chance":0.10}        -> en pjas rullas (som wb_marks_redeem), aldrig en vaska
     gold        payload {"copper":250000}                    -> apply_currency
     stack       payload {"stack_key":"...","qty":1}          -> add_stack (bunden vara, t ex en framtida charm)
     title       (ej byggt - inget titelsystem i spelet annu; event_shop_buy sager event_kind_unknown)
   per_char = max antal kop per karaktar (null = obegransat). art = bildvag for klienten. */
create table if not exists public.season_event_shop (
  event_key  text not null references public.season_events(key) on delete cascade,
  key        text not null,
  name       text not null,
  kind       text not null check (kind in ('appearance','gear','gold','stack','title')),
  price      integer not null check (price > 0),
  payload    jsonb not null default '{}'::jsonb,
  art        text,
  descr      text,
  per_char   integer,
  sort       integer not null default 0,
  enabled    boolean not null default true,
  primary key (event_key, key)
);

/* Droppchanser per kalla. chance 0..1 (vid full skala), qty_min..qty_max marks per traff.
   min_tier = lagsta regionsniva (0 = alla). expedition: full_mins = langden (minuter) som ger full
   chans OCH fullt antal; kortare skalar linjart (mins/full_mins). hi_tier/hi_bonus = fran och med
   regionsniva hi_tier laggs hi_bonus marks pa. */
create table if not exists public.season_event_drops (
  event_key  text not null references public.season_events(key) on delete cascade,
  src        text not null check (src in ('encounter','expedition','dungeon','worldboss')),
  chance     numeric not null check (chance >= 0 and chance <= 1),
  qty_min    integer not null default 1,
  qty_max    integer not null default 1,
  min_tier   integer not null default 0,
  full_mins  numeric,
  hi_tier    integer,
  hi_bonus   integer not null default 0,
  note       text,
  primary key (event_key, src)
);

/* Kopbok: en rad per kop. Anvands for per_char-granser och for att se vad som salts. */
create table if not exists public.season_event_purchases (
  id            bigserial primary key,
  character_id  uuid not null,
  event_key     text not null,
  item_key      text not null,
  price         integer not null,
  at            timestamptz not null default now()
);
create index if not exists season_event_purchases_char_idx on public.season_event_purchases (character_id, event_key, item_key);

/* Marken ar Bind on Pickup. Kolumnen finns redan om sockets-grenen ar inlagd (samma sats dar). */
alter table public.stack_item_config add column if not exists bop boolean not null default false;

-- ============================================================================
-- 2. RADER: HALLOWEEN 2026
-- ============================================================================

/* Eventfonstret: 2026-10-31 00:00 UTC till 2026-11-09 23:59:59 UTC (10 dagar). Chris bestammer -
   andra starts_at/ends_at har, eller stang med enabled=false. */
insert into public.season_events (key, name, tagline, starts_at, ends_at, enabled, mark_key, mark_name, mark_plural, mark_art,
                                  set_name, set_prefix, figure_suffix, set_min, accent, flavor, sort)
values ('halloween_2026', 'Halloween', 'The grid is haunted. Collect Jack-o''-Marks and dress for the season.',
        '2026-10-31 00:00:00+00', '2026-11-09 23:59:59+00', true,
        'halloween_mark', 'Jack-o''-Mark', 'Jack-o''-Marks', 'assets/items/event/halloween_mark.webp',
        'Jack-o''-Lantern', 'jack', 'halloween', 5, '#ff8c1a',
        'Something is grinning in the dark between the nodes.', 10)
on conflict (key) do update set
  name = excluded.name, tagline = excluded.tagline, starts_at = excluded.starts_at, ends_at = excluded.ends_at,
  mark_key = excluded.mark_key, mark_name = excluded.mark_name, mark_plural = excluded.mark_plural, mark_art = excluded.mark_art,
  set_name = excluded.set_name, set_prefix = excluded.set_prefix, figure_suffix = excluded.figure_suffix, set_min = excluded.set_min,
  accent = excluded.accent, flavor = excluded.flavor, sort = excluded.sort;
  /* enabled skrivs INTE over: har Chris stangt eventet forblir det stangt nar filen kors igen. */

/* Marken: stapelvara, sell 0 (kan aldrig saljas, auktioneras, postas eller handlas - can_be_traded stoppar sell=0),
   bop (Bind on Pickup for sockets-grenens can_be_traded). */
insert into public.stack_item_config (key, name, sell, vendor_sells, bop)
values ('halloween_mark', 'Jack-o''-Mark', 0, false, true)
on conflict (key) do update set name = excluded.name, sell = 0, vendor_sells = false, bop = true;

/* Utseende-setet Jack-o'-Lantern: fem item_config-rader (plats 0-4) med TOM drop_rarities - de faller aldrig,
   rullas aldrig av handlaren, kan inte tillverkas. De finns bara sa transmog_apply kan peka pa dem (samma plats,
   och raden i character_appearances som eventbutiken lagger). rarities '{3}' = ritas Epic om nagot nagonsin fragar. */
insert into public.item_config (key, name, slot_idx, rarities, bag_slots, drop_rarities, two_hand, region) values
  ('jack_head',   'Jack-o''-Lantern Head',   0, '{3}', null, '{}', false, null),
  ('jack_chest',  'Jack-o''-Lantern Chest',  1, '{3}', null, '{}', false, null),
  ('jack_legs',   'Jack-o''-Lantern Legs',   2, '{3}', null, '{}', false, null),
  ('jack_gloves', 'Jack-o''-Lantern Gloves', 3, '{3}', null, '{}', false, null),
  ('jack_boots',  'Jack-o''-Lantern Boots',  4, '{3}', null, '{}', false, null)
on conflict (key) do update set name = excluded.name, slot_idx = excluded.slot_idx, rarities = excluded.rarities,
  drop_rarities = '{}', bag_slots = null, two_hand = false;

/* Butiken. Setdelarna dyrast (175 marks for hela setet), resten billigare. Alla priser har. */
insert into public.season_event_shop (event_key, key, name, kind, price, payload, art, descr, per_char, sort) values
  ('halloween_2026', 'jack_head',   'Jack-o''-Lantern Head',   'appearance', 40, '{"item_key":"jack_head","slot":0}',   'assets/gear/halloween/jack_head.webp',   'Appearance for the head slot. Any class, forever.', 1, 10),
  ('halloween_2026', 'jack_chest',  'Jack-o''-Lantern Chest',  'appearance', 40, '{"item_key":"jack_chest","slot":1}',  'assets/gear/halloween/jack_chest.webp',  'Appearance for the chest slot. Any class, forever.', 1, 20),
  ('halloween_2026', 'jack_legs',   'Jack-o''-Lantern Legs',   'appearance', 35, '{"item_key":"jack_legs","slot":2}',   'assets/gear/halloween/jack_legs.webp',   'Appearance for the legs slot. Any class, forever.', 1, 30),
  ('halloween_2026', 'jack_gloves', 'Jack-o''-Lantern Gloves', 'appearance', 30, '{"item_key":"jack_gloves","slot":3}', 'assets/gear/halloween/jack_gloves.webp', 'Appearance for the gloves slot. Any class, forever.', 1, 40),
  ('halloween_2026', 'jack_boots',  'Jack-o''-Lantern Boots',  'appearance', 30, '{"item_key":"jack_boots","slot":4}',  'assets/gear/halloween/jack_boots.webp',  'Appearance for the feet slot. Any class, forever.', 1, 50),
  ('halloween_2026', 'cache_legendary', 'Legendary Cache', 'gear', 25, '{"rarity":4,"up_chance":0.10}', 'assets/items/caches/cache_gear_leg.webp',  'A Legendary piece of gear for your level. 10 % chance it is Mythic.', null, 60),
  ('halloween_2026', 'cache_rare',      'Rare Cache',      'gear',  8, '{"rarity":2,"up_chance":0.25}', 'assets/items/caches/cache_gear_rare.webp', 'A Rare piece of gear for your level. 25 % chance it is Epic.', null, 70),
  ('halloween_2026', 'gold_pile',       'Pile of gold',    'gold', 10, '{"copper":250000}',             'assets/ui/ico/gold.webp',                  '25 gold, straight into your purse.', null, 80)
on conflict (event_key, key) do update set name = excluded.name, kind = excluded.kind, price = excluded.price, payload = excluded.payload,
  art = excluded.art, descr = excluded.descr, per_char = excluded.per_char, sort = excluded.sort;

/* Droppchanser. Malet: en aktiv spelare har hela setet (175 marks) pa 3-4 dagar, ca 50-60 marks per dag.
     encounter   25 % per vunnen strid, 1 mark (alla regioner)                   ~15-25 / dag
     expedition  100 % vid 4 h eller langre, 1-2 marks; kortare skalar (mins/240)  ~15-30 / dag med flera hjalpare
     dungeon     100 % vid klarat lopp, 2 marks, +1 fran regionsniva 3            ~6-12 / dag
     worldboss   100 % vid dodad boss, 5 marks (i brevet)                         ~10 / dag (tva bossar) */
insert into public.season_event_drops (event_key, src, chance, qty_min, qty_max, min_tier, full_mins, hi_tier, hi_bonus, note) values
  ('halloween_2026', 'encounter',  0.25, 1, 1, 0, null, null, 0, '25 % per vunnen strid'),
  ('halloween_2026', 'expedition', 1.00, 1, 2, 0, 240,  null, 0, 'full chans och fullt antal fran 4 h, kortare skalar'),
  ('halloween_2026', 'dungeon',    1.00, 2, 2, 0, null, 3,    1, 'klarat lopp; +1 fran regionsniva 3'),
  ('halloween_2026', 'worldboss',  1.00, 5, 5, 0, null, null, 0, 'bara nar bossen dor; laggs i brevet')
on conflict (event_key, src) do update set chance = excluded.chance, qty_min = excluded.qty_min, qty_max = excluded.qty_max,
  min_tier = excluded.min_tier, full_mins = excluded.full_mins, hi_tier = excluded.hi_tier, hi_bonus = excluded.hi_bonus, note = excluded.note;

-- ============================================================================
-- 3. NYA FUNKTIONER
-- ============================================================================

/* Nyckeln pa det event som ar igang just nu (eller null). Finns tva overlappande vinner lagst sort. */
create or replace function public.event_now_key()
 returns text language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select key from public.season_events
  where enabled and now() >= starts_at and now() <= ends_at
  order by sort, starts_at limit 1;
$function$;
revoke execute on function public.event_now_key() from public, anon;
revoke execute on function public.event_now_key() from authenticated; -- intern hjalpare

/* Allt klienten behover i ETT anrop: det aktiva eventet (butik med agt/kopt, droppchanser, spelarens marks)
   och nasta kommande event (for "starts in"). event = null nar inget ar igang. */
create or replace function public.event_state(p_character uuid)
 returns json language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_e public.season_events; v_n public.season_events; v_marks integer := 0; v_shop jsonb; v_drops jsonb; v_ev json := null; v_next json := null;
begin
  perform public.owned_character(p_character);
  select * into v_e from public.season_events where key = public.event_now_key();
  if found then
    select coalesce(sum(qty), 0)::integer into v_marks from public.stacks where character_id = p_character and stack_key = v_e.mark_key;
    select coalesce(jsonb_agg(jsonb_build_object(
             'key', s.key, 'name', s.name, 'kind', s.kind, 'price', s.price, 'payload', s.payload, 'art', s.art, 'descr', s.descr,
             'per_char', s.per_char,
             'bought', (select count(*) from public.season_event_purchases p where p.character_id = p_character and p.event_key = s.event_key and p.item_key = s.key),
             'owned', (s.kind = 'appearance' and exists (select 1 from public.character_appearances a where a.character_id = p_character and a.item_key = s.payload->>'item_key'))
           ) order by s.sort, s.key), '[]'::jsonb)
      into v_shop from public.season_event_shop s where s.event_key = v_e.key and s.enabled;
    select coalesce(jsonb_agg(jsonb_build_object('src', d.src, 'chance', d.chance, 'qty_min', d.qty_min, 'qty_max', d.qty_max,
             'min_tier', d.min_tier, 'full_mins', d.full_mins, 'hi_tier', d.hi_tier, 'hi_bonus', d.hi_bonus, 'note', d.note) order by d.src), '[]'::jsonb)
      into v_drops from public.season_event_drops d where d.event_key = v_e.key;
    v_ev := json_build_object('key', v_e.key, 'name', v_e.name, 'tagline', v_e.tagline, 'starts_at', v_e.starts_at, 'ends_at', v_e.ends_at,
              'mark', json_build_object('key', v_e.mark_key, 'name', v_e.mark_name, 'plural', v_e.mark_plural, 'art', v_e.mark_art),
              'set', json_build_object('name', v_e.set_name, 'prefix', v_e.set_prefix, 'figure_suffix', v_e.figure_suffix, 'min', v_e.set_min),
              'accent', v_e.accent, 'flavor', v_e.flavor, 'shop', v_shop, 'drops', v_drops, 'marks', v_marks);
  end if;
  select * into v_n from public.season_events where enabled and starts_at > now() order by starts_at limit 1;
  if found then
    v_next := json_build_object('key', v_n.key, 'name', v_n.name, 'tagline', v_n.tagline, 'starts_at', v_n.starts_at, 'ends_at', v_n.ends_at,
                'mark', json_build_object('key', v_n.mark_key, 'name', v_n.mark_name, 'plural', v_n.mark_plural, 'art', v_n.mark_art), 'accent', v_n.accent);
  end if;
  return json_build_object('now', now(), 'event', v_ev, 'next', v_next);
end $function$;
revoke execute on function public.event_state(uuid) from public, anon;
grant execute on function public.event_state(uuid) to authenticated;

/* EN rullning per kalla. Returnerar null (inget event / ingen traff) eller
   {"event","key","qty","name","plural","art","mailed"}. p_deliver=true lagger marken i vaskan (eller i
   posten om vaskan ar full och spelaren inte redan har en stapel); false = bara svaret, anroparen levererar
   (wb_reward lagger dem i brevet). Loot Luck paverkar inte. Alla tal ur season_event_drops. */
create or replace function public.event_mark_drop(p_character uuid, p_src text, p_tier integer, p_mins numeric default 0, p_deliver boolean default true)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_e public.season_events; v_d public.season_event_drops; v_f numeric := 1; v_t integer := greatest(0, coalesce(p_tier, 0));
        v_qty integer; v_mailed boolean := false;
begin
  select * into v_e from public.season_events where key = public.event_now_key();
  if not found then return null; end if;
  select * into v_d from public.season_event_drops where event_key = v_e.key and src = p_src;
  if not found then return null; end if;
  if v_t < coalesce(v_d.min_tier, 0) then return null; end if;
  if p_src = 'expedition' and coalesce(v_d.full_mins, 0) > 0 then
    v_f := least(1, greatest(0, coalesce(p_mins, 0)) / v_d.full_mins);
  end if;
  if v_d.chance * v_f <= 0 or random() >= v_d.chance * v_f then return null; end if;
  v_qty := v_d.qty_min + floor(random() * (greatest(v_d.qty_min, v_d.qty_max) - v_d.qty_min + 1))::integer;
  if v_f < 1 then v_qty := greatest(1, round(v_qty * v_f)::integer); end if;
  if v_d.hi_tier is not null and v_t >= v_d.hi_tier then v_qty := v_qty + coalesce(v_d.hi_bonus, 0); end if;
  if v_qty <= 0 then return null; end if;
  if p_deliver then
    if public.bag_free(p_character) > 0 or exists (select 1 from public.stacks where character_id = p_character and stack_key = v_e.mark_key) then
      perform public.add_stack(p_character, v_e.mark_key, 'item', v_qty, null);
    else
      perform public.send_mail(p_character, v_e.name || ' Courier', 'Your ' || v_e.mark_plural, 'Your backpack was full, so they wait here.',
        jsonb_build_array(jsonb_build_object('stack_key', v_e.mark_key, 'kind', 'item', 'qty', v_qty)));
      v_mailed := true;
    end if;
  end if;
  return jsonb_build_object('event', v_e.key, 'key', v_e.mark_key, 'qty', v_qty, 'name', v_e.mark_name, 'plural', v_e.mark_plural, 'art', v_e.mark_art, 'mailed', v_mailed);
end $function$;
revoke execute on function public.event_mark_drop(uuid, text, integer, numeric, boolean) from public, anon;
revoke execute on function public.event_mark_drop(uuid, text, integer, numeric, boolean) from authenticated; -- intern hjalpare: anropas bara fran andra serverfunktioner

/* KOPET. Drar marks, levererar varan, bokfor, returnerar nytt lage. Klienten spelar bara upp svaret.
   Felkoder: event_closed, event_item_bad, event_item_owned, event_marks_short (detail = priset), event_kind_unknown. */
create or replace function public.event_shop_buy(p_character uuid, p_event text, p_key text)
 returns json language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_e public.season_events; v_s public.season_event_shop; v_have integer; v_n integer; v_res json;
        v_rar integer; v_ikey text; v_it public.items; v_name text; v_lvl integer; v_mailed boolean := false; v_skey text; v_qty integer;
begin
  perform public.owned_character(p_character);
  select * into v_e from public.season_events where key = p_event and enabled and now() >= starts_at and now() <= ends_at;
  if not found then raise exception 'event_closed' using errcode='P0001'; end if;
  select * into v_s from public.season_event_shop where event_key = p_event and key = p_key and enabled;
  if not found then raise exception 'event_item_bad' using errcode='P0001'; end if;
  if v_s.per_char is not null then
    select count(*) into v_n from public.season_event_purchases where character_id = p_character and event_key = p_event and item_key = p_key;
    if v_n >= v_s.per_char then raise exception 'event_item_owned' using errcode='P0001'; end if;
  end if;
  if v_s.kind = 'appearance' and exists (select 1 from public.character_appearances where character_id = p_character and item_key = v_s.payload->>'item_key') then
    raise exception 'event_item_owned' using errcode='P0001';
  end if;
  if v_s.kind = 'title' then raise exception 'event_kind_unknown' using errcode='P0001'; end if;
  select coalesce(sum(qty), 0)::integer into v_have from public.stacks where character_id = p_character and stack_key = v_e.mark_key;
  if v_have < v_s.price then raise exception 'event_marks_short' using errcode='P0001', detail = v_s.price::text; end if;
  if not public.take_stack(p_character, v_e.mark_key, v_s.price, null) then raise exception 'event_marks_short' using errcode='P0001', detail = v_s.price::text; end if;

  if v_s.kind = 'appearance' then
    v_ikey := v_s.payload->>'item_key';
    if not exists (select 1 from public.item_config where key = v_ikey) then raise exception 'event_item_bad' using errcode='P0001'; end if;
    insert into public.character_appearances (character_id, item_key) values (p_character, v_ikey);
    v_res := json_build_object('kind', 'appearance', 'item_key', v_ikey, 'name', v_s.name, 'slot', (v_s.payload->>'slot')::integer);

  elsif v_s.kind = 'gear' then
    v_rar := least(5, greatest(0, coalesce((v_s.payload->>'rarity')::integer, 4)));
    if random() < coalesce((v_s.payload->>'up_chance')::numeric, 0) then v_rar := least(5, v_rar + 1); end if;
    /* som wb_marks_redeem: aldrig en vaska (de har egen fast raritet) */
    for i in 1..40 loop
      v_ikey := public.pick_item_key_r(v_rar, p_character);
      exit when v_ikey is not null and (select bag_slots is null from public.item_config where key = v_ikey);
    end loop;
    if v_ikey is null then raise exception 'event_item_bad' using errcode='P0001'; end if;
    v_lvl := least(public.lvl_cap(), greatest(1, public.character_level((select xp from public.characters where id = p_character))));
    if public.bag_free(p_character) > 0 then
      v_it := public.roll_item(p_character, v_ikey, v_rar, 1, 'bag', 0, false, v_lvl);
    else
      v_it := public.roll_item(p_character, v_ikey, v_rar, 1, 'mail', 0, false, v_lvl);
      perform public.send_mail(p_character, v_e.name || ' Courier', 'Your ' || v_s.name, 'Your backpack was full, so the piece waits here.', jsonb_build_array(jsonb_build_object('item_id', v_it.id)));
      v_mailed := true;
    end if;
    select name into v_name from public.item_config where key = v_ikey;
    v_res := json_build_object('kind', 'item', 'item_id', v_it.id, 'item_key', v_ikey, 'name', v_name, 'rarity', v_it.rarity, 'mailed', v_mailed);

  elsif v_s.kind = 'gold' then
    v_qty := greatest(0, coalesce((v_s.payload->>'copper')::integer, 0));
    /* Skalet 'sell' finns i ledgerns lista (spelaren byter marks mot guld). Vill Chris ha ett eget skal:
       lagg 'event_shop' i ledgerns lista och byt har. */
    perform public.apply_currency(p_character, 'sell', v_qty, 0, 0, 0, jsonb_build_object('event', p_event, 'shop', p_key, 'marks', v_s.price));
    v_res := json_build_object('kind', 'gold', 'copper', v_qty);

  elsif v_s.kind = 'stack' then
    v_skey := v_s.payload->>'stack_key'; v_qty := greatest(1, coalesce((v_s.payload->>'qty')::integer, 1));
    if not exists (select 1 from public.stack_item_config where key = v_skey) then raise exception 'event_item_bad' using errcode='P0001'; end if;
    if public.bag_free(p_character) > 0 or exists (select 1 from public.stacks where character_id = p_character and stack_key = v_skey) then
      perform public.add_stack(p_character, v_skey, 'item', v_qty, null);
    else
      perform public.send_mail(p_character, v_e.name || ' Courier', 'Your ' || v_s.name, 'Your backpack was full, so it waits here.', jsonb_build_array(jsonb_build_object('stack_key', v_skey, 'kind', 'item', 'qty', v_qty)));
      v_mailed := true;
    end if;
    v_res := json_build_object('kind', 'stack', 'key', v_skey, 'qty', v_qty, 'mailed', v_mailed);
  else
    raise exception 'event_kind_unknown' using errcode='P0001';
  end if;

  insert into public.season_event_purchases (character_id, event_key, item_key, price) values (p_character, p_event, p_key, v_s.price);
  update public.characters set save_version = save_version + 1, last_seen_at = now() where id = p_character;
  select coalesce(sum(qty), 0)::integer into v_have from public.stacks where character_id = p_character and stack_key = v_e.mark_key;
  return json_build_object('ok', true, 'event', p_event, 'key', p_key, 'price', v_s.price, 'marks_left', v_have, 'got', v_res,
                           'state', public.event_state(p_character));
end $function$;
revoke execute on function public.event_shop_buy(uuid, text, text) from public, anon;
grant execute on function public.event_shop_buy(uuid, text, text) to authenticated;

-- ============================================================================
-- 4. DROPPKROKAR - patchas in i serverns NUVARANDE kod
-- ============================================================================

/* Laser funktionens kod med pg_get_functiondef, kraver att ankaret finns EXAKT en gang, byter ut det och
   skriver tillbaka funktionen. Har markoren redan skrivits in (filen kors igen) gors inget.
   Fungerar oavsett om sockets-grenen ar inlagd: ankarna nedan finns i bada versionerna, sockets-raderna rors inte. */
create or replace function public.event_patch_fn(p_fn regprocedure, p_anchor text, p_new text, p_marker text)
 returns text language plpgsql
as $function$
declare v_def text; v_n integer;
begin
  v_def := pg_get_functiondef(p_fn);
  if position(p_marker in v_def) > 0 then return p_fn::text || ': redan patchad (' || p_marker || ')'; end if;
  v_n := (length(v_def) - length(replace(v_def, p_anchor, ''))) / length(p_anchor);
  if v_n <> 1 then
    raise exception 'event_patch_fn: ankaret finns % ganger i % (ska vara exakt 1). Ankare: %', v_n, p_fn::text, p_anchor;
  end if;
  execute replace(v_def, p_anchor, p_new);
  return p_fn::text || ': patchad (' || p_marker || ')';
end $function$;
revoke execute on function public.event_patch_fn(regprocedure, text, text, text) from public, anon;
revoke execute on function public.event_patch_fn(regprocedure, text, text, text) from authenticated;

/* ---- pve_fight: 25 % per vunnen strid (encounter) ---- */
select public.event_patch_fn('public.pve_fight(uuid, uuid)',
  $a$  v_tier integer; v_credits integer := 0; v_em numeric := 1;$a$,
  $b$  v_tier integer; v_credits integer := 0; v_em numeric := 1;
  v_evm jsonb := null;   /* [TILLAGT v5.1362.0] EVENT-MARKS (sasongsevent) - se event_mark_drop */$b$,
  'v5.1362.0] EVENT-MARKS (sasongsevent) - se event_mark_drop');
select public.event_patch_fn('public.pve_fight(uuid, uuid)',
  $a$    v_scrap_qty := round(coalesce(public.pve_val('scrap_qty'), 0)$a$,
  $b$    /* [TILLAGT v5.1362.0] EVENT-MARKS: en rullning per vunnen strid, talen i season_event_drops (encounter). Loot Luck paverkar inte. */
    begin v_evm := public.event_mark_drop(p_character, 'encounter', coalesce(v_tier, 0), 0, true); exception when others then v_evm := null; end;
    v_scrap_qty := round(coalesce(public.pve_val('scrap_qty'), 0)$b$,
  'v5.1362.0] EVENT-MARKS: en rullning per vunnen strid');
select public.event_patch_fn('public.pve_fight(uuid, uuid)',
  $a$'schematic', v_sch_got$a$,
  $b$'event_marks', v_evm,   /* [TILLAGT v5.1362.0] */
          'schematic', v_sch_got$b$,
  $m$'event_marks', v_evm,   /* [TILLAGT v5.1362.0] */$m$);

/* ---- claim_expedition: 100 % fran 4 h, 1-2 marks, kortare skalar ---- */
select public.event_patch_fn('public.claim_expedition(uuid, text)',
  $a$  v_shard text; v_shard_got text := null; v_first_clear boolean; v_lap json;$a$,
  $b$  v_shard text; v_shard_got text := null; v_first_clear boolean; v_lap json;
  v_evm jsonb := null;   /* [TILLAGT v5.1362.0] EVENT-MARKS (sasongsevent) - se event_mark_drop */$b$,
  'v5.1362.0] EVENT-MARKS (sasongsevent) - se event_mark_drop');
select public.event_patch_fn('public.claim_expedition(uuid, text)',
  $a$  if jsonb_array_length(v_mailed) > 0 then$a$,
  $b$  /* [TILLAGT v5.1362.0] EVENT-MARKS: skalar med langden (mins/full_mins), talen i season_event_drops (expedition). */
  begin v_evm := public.event_mark_drop(p_character, 'expedition', v_tier, v_def.mins, true); exception when others then v_evm := null; end;
  if jsonb_array_length(v_mailed) > 0 then$b$,
  'v5.1362.0] EVENT-MARKS: skalar med langden');
select public.event_patch_fn('public.claim_expedition(uuid, text)',
  $a$'relic', v_relic, 'recipe', v_rec, 'melon', v_melon,$a$,
  $b$'relic', v_relic, 'recipe', v_rec, 'melon', v_melon, 'event_marks', v_evm,   /* [TILLAGT v5.1362.0] */$b$,
  $m$'melon', v_melon, 'event_marks', v_evm,$m$);

/* ---- pve_dungeon_claim: klarat lopp, 2 marks (+1 fran regionsniva 3) ---- */
select public.event_patch_fn('public.pve_dungeon_claim(uuid)',
  $a$  v_klar boolean := false; v_charms jsonb := '[]'::jsonb; v_ck text;$a$,
  $b$  v_klar boolean := false; v_charms jsonb := '[]'::jsonb; v_ck text; v_evm jsonb := null;   /* [TILLAGT v5.1362.0] EVENT-MARKS */$b$,
  'v_evm jsonb := null;   /* [TILLAGT v5.1362.0] EVENT-MARKS */');
select public.event_patch_fn('public.pve_dungeon_claim(uuid)',
  $a$  update public.pve_dungeon_runs set state = 'claimed', claimed_at = now(),$a$,
  $b$  /* [TILLAGT v5.1362.0] EVENT-MARKS vid klarat lopp (slutbossen besegrad, ingen dod). Talen i season_event_drops (dungeon). */
  if v_klar then
    begin v_evm := public.event_mark_drop(p_character, 'dungeon', coalesce(v_sch_tier, 0), 0, true); exception when others then v_evm := null; end;
  end if;
  update public.pve_dungeon_runs set state = 'claimed', claimed_at = now(),$b$,
  'v5.1362.0] EVENT-MARKS vid klarat lopp');
select public.event_patch_fn('public.pve_dungeon_claim(uuid)',
  $a$'schematic', v_sch_got,$a$,
  $b$'schematic', v_sch_got, 'event_marks', v_evm,   /* [TILLAGT v5.1362.0] */$b$,
  $m$'schematic', v_sch_got, 'event_marks', v_evm,$m$);

/* ---- wb_reward: 5 marks i brevet nar bossen dor ---- */
select public.event_patch_fn('public.wb_reward(bigint)',
  $a$v_got_charm boolean; v_got_apex boolean;$a$,
  $b$v_got_charm boolean; v_got_apex boolean;
  v_evm jsonb := null;   /* [TILLAGT v5.1362.0] EVENT-MARKS (sasongsevent) - se event_mark_drop */$b$,
  'v5.1362.0] EVENT-MARKS (sasongsevent) - se event_mark_drop');
select public.event_patch_fn('public.wb_reward(bigint)',
  $a$    if v_dead then v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', 'boss_mark', 'kind', 'item', 'qty', 1)); end if;$a$,
  $b$    if v_dead then v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', 'boss_mark', 'kind', 'item', 'qty', 1)); end if;
    /* [TILLAGT v5.1362.0] EVENT-MARKS: bara nar bossen dor, laggs i brevet. Talen i season_event_drops (worldboss). */
    v_evm := null;
    if v_dead then begin v_evm := public.event_mark_drop(v_h.character_id, 'worldboss', public.world_tier(v_h.character_id, coalesce(v_tier, 0)), 0, false); exception when others then v_evm := null; end; end if;
    if v_evm is not null then v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', v_evm->>'key', 'kind', 'item', 'qty', (v_evm->>'qty')::integer)); end if;$b$,
  'v5.1362.0] EVENT-MARKS: bara nar bossen dor');
select public.event_patch_fn('public.wb_reward(bigint)',
  $a$              || (case when v_paper is not null then ' A schematic is in the box.' else '' end)$a$,
  $b$              || (case when v_paper is not null then ' A schematic is in the box.' else '' end)
              || (case when v_evm is not null then ' ' || (v_evm->>'qty') || ' ' || (case when (v_evm->>'qty')::integer = 1 then v_evm->>'name' else v_evm->>'plural' end) || ' in the box.' else '' end)   /* [TILLAGT v5.1362.0] */$b$,
  $m$(v_evm->>'qty')::integer = 1 then v_evm->>'name' else v_evm->>'plural' end) || ' in the box.'$m$);
select public.event_patch_fn('public.wb_reward(bigint)',
  $a$'apex', v_got_apex,$a$,
  $b$'apex', v_got_apex, 'event_marks', v_evm,$b$,
  $m$'apex', v_got_apex, 'event_marks', v_evm,$m$);

-- ============================================================================
-- 5. REVOKES (samlat - de star aven vid varje funktion ovan)
-- ============================================================================
revoke execute on function public.event_now_key() from public, anon, authenticated;
revoke execute on function public.event_mark_drop(uuid, text, integer, numeric, boolean) from public, anon, authenticated;
revoke execute on function public.event_patch_fn(regprocedure, text, text, text) from public, anon, authenticated;
revoke execute on function public.event_state(uuid) from public, anon;
revoke execute on function public.event_shop_buy(uuid, text, text) from public, anon;
grant execute on function public.event_state(uuid) to authenticated;
grant execute on function public.event_shop_buy(uuid, text, text) to authenticated;
/* Tabellerna laser klienten ALDRIG direkt - allt gar via event_state. */
revoke all on table public.season_events, public.season_event_shop, public.season_event_drops, public.season_event_purchases from public, anon, authenticated;

-- ============================================================================
-- 6. TESTBLOCK - kors lokalt av Chris, rullas ALLTID tillbaka
-- ============================================================================
--  Byt <CHAR> mot testkaraktarens id, <PROFILE> mot dess profile_id (auth.users.id) och <SESSION> mot
--  en giltig x-genesis-session (eller det vardet owned_character kraver). set_config med role
--  'authenticated' ligger BARA runt spelaranropen; allt annat kors som agare.
--  Eventet oppnas tillfalligt i transaktionen (starts_at = igar) sa testet gar aven fore 2026-10-31.
/*
begin;
  update public.season_events set starts_at = now() - interval '1 day' where key = 'halloween_2026';

  -- som agare: ge 60 marks och rulla droppar
  select public.add_stack('<CHAR>'::uuid, 'halloween_mark', 'item', 60, null);
  select public.event_mark_drop('<CHAR>'::uuid, 'encounter', 0, 0, true);     -- 25 %: null eller {"qty":1,...}
  select public.event_mark_drop('<CHAR>'::uuid, 'expedition', 2, 480, true);  -- alltid 1-2
  select public.event_mark_drop('<CHAR>'::uuid, 'expedition', 2, 60, true);   -- 25 % chans, 1 mark
  select public.event_mark_drop('<CHAR>'::uuid, 'dungeon', 3, 0, true);       -- alltid 3 (2 + 1)
  select public.event_mark_drop('<CHAR>'::uuid, 'worldboss', 1, 0, false);    -- alltid 5, levereras inte

  -- som spelare
  select set_config('request.jwt.claims', json_build_object('sub', '<PROFILE>', 'role', 'authenticated')::text, true);
  select set_config('request.headers', json_build_object('x-genesis-session', '<SESSION>')::text, true);
  select set_config('role', 'authenticated', true);
    select public.event_state('<CHAR>'::uuid);                                       -- event.marks >= 60, shop med owned=false
    select public.event_shop_buy('<CHAR>'::uuid, 'halloween_2026', 'jack_head');     -- got.kind = appearance, marks_left = 20
    select public.event_shop_buy('<CHAR>'::uuid, 'halloween_2026', 'jack_head');     -- FEL: event_item_owned
    select public.event_shop_buy('<CHAR>'::uuid, 'halloween_2026', 'cache_rare');    -- got.kind = item (Rare/Epic), marks_left = 12
    select public.event_shop_buy('<CHAR>'::uuid, 'halloween_2026', 'gold_pile');     -- got.copper = 250000, marks_left = 2
    select public.event_shop_buy('<CHAR>'::uuid, 'halloween_2026', 'cache_legendary'); -- FEL: event_marks_short (detail 25)
    -- utseendet: satt jack_head pa den burna hjalmen
    select public.transmog_apply('<CHAR>'::uuid, (select id from public.items where character_id = '<CHAR>'::uuid and location = 'equipped' and slot_idx = 0 limit 1), 'jack_head');
    -- sparrarna: marken kan inte saljas/listas
    select public.can_be_traded(null, 'halloween_mark');                              -- FEL: cannot_be_listed (eller bind_on_pickup med sockets)
  reset role;

  select item_key from public.character_appearances where character_id = '<CHAR>'::uuid and item_key like 'jack\_%';
  select * from public.season_event_purchases where character_id = '<CHAR>'::uuid;
  select stack_key, qty from public.stacks where character_id = '<CHAR>'::uuid and stack_key = 'halloween_mark';
rollback;
*/

-- Kontroll efter korning (ska ge 4 rader med 'patchad' eller 'redan patchad' i meddelandena ovan, och har 'halloween_2026'):
select key, name, starts_at, ends_at, enabled, public.event_now_key() as active_now from public.season_events order by sort;
