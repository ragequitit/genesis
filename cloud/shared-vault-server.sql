/* [TILLAGT v5.1413.0-valv] DELAT VALV (Chris 2026-11-01, ide fran PickyPete).
   En flik Shared i valvet som alla karaktarer pa samma konto ser. 20 rutor, 100 credits en gang per konto.
   Filen ar idempotent och avbryter med fel om ett ankare saknas. KORS INTE forran Chris sagt till.

   VARFOR EGNA TABELLER, INTE EN NY PLATS PA items:
   items.character_id ar NOT NULL och ON DELETE CASCADE - en pjas maste ha en karaktar, och raderas karaktaren raderas pjasen.
   Over 90 serverfunktioner laser items, de flesta bara pa character_id. Ett nytt varde i item_location gar inte heller att
   torrkora (ett nytt enum-varde far inte anvandas i samma transaktion). Darfor FLYTTAS raden hit: den finns inte i items
   medan den ligger i fliken. Da kan auktionshus, salj, skrot, post, handel och utrustning inte hitta den alls, och att
   radera en karaktar kan inte nudda den. Hela raden sparas som json, sa en ny kolumn pa items foljer med automatiskt
   (aterkopet har tappat falt flera ganger for att det raknade upp dem for hand).
   Agaren ar kontot (profile_id). Kontoradering tar fliken, karaktarsradering inte. */

/* ===== Tal ===== */
create table if not exists public.shared_vault_config (
  key text primary key,
  val integer not null check (val >= 0),
  note text
);
insert into public.shared_vault_config (key, val, note) values
  ('slots', 20, 'Rutor i delade fliken, en ruta per pjas eller sort'),
  ('unlock_credits', 100, 'Pris i credits for att lasa upp fliken, en gang per konto')
on conflict (key) do nothing;

/* ===== Kontots upplasning ===== */
create table if not exists public.shared_vault_accounts (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  paid_credits integer not null,
  bought_by uuid,            /* medvetet ingen koppling till characters: kopet ska overleva att karaktaren raderas */
  bought_by_name text
);

/* ===== Pjaser: hela raden ur items ===== */
create table if not exists public.shared_vault_items (
  id uuid primary key,       /* samma id som pjasen hade, sa item_log foljer pjasen hela vagen */
  profile_id uuid not null references public.profiles(id) on delete cascade,
  item_key text not null,
  rarity integer not null,
  snapshot jsonb not null,
  put_by uuid,
  put_at timestamptz not null default now()
);
create index if not exists shared_vault_items_profile on public.shared_vault_items (profile_id);

/* ===== Staplar ===== */
create table if not exists public.shared_vault_stacks (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  stack_key text not null,
  kind text not null,
  rarity integer,
  rarity_key integer generated always as (coalesce(rarity, -1)) stored,
  qty integer not null check (qty > 0),
  primary key (profile_id, stack_key, rarity_key)
);

/* Tabellerna nas bara genom funktionerna nedan. */
alter table public.shared_vault_config enable row level security;
alter table public.shared_vault_accounts enable row level security;
alter table public.shared_vault_items enable row level security;
alter table public.shared_vault_stacks enable row level security;
revoke all on public.shared_vault_config, public.shared_vault_accounts, public.shared_vault_items, public.shared_vault_stacks
  from public, anon, authenticated;

/* ===== Kassaboken: nytt skal, annars avvisas kopet. Inte 'buy' - den raknar upp handlarkop (vendor_buys). ===== */
do $patch$
declare v_def text; v_ny text; v_ankare text := '''cache''::text,';
begin
  select pg_get_constraintdef(oid) into v_def from pg_constraint
   where conrelid = 'public.ledger'::regclass and conname = 'ledger_reason_check';
  if v_def is null then raise exception 'ANKARE SAKNAS: ledger_reason_check'; end if;
  if position('''shared_vault''' in v_def) = 0 then
    if position(v_ankare in v_def) = 0 then raise exception 'ANKARE SAKNAS: cache i ledger_reason_check'; end if;
    v_ny := replace(v_def, v_ankare, '''shared_vault''::text, ' || v_ankare);
    alter table public.ledger drop constraint ledger_reason_check;
    execute format('alter table public.ledger add constraint ledger_reason_check %s not valid', v_ny);
    alter table public.ledger validate constraint ledger_reason_check;
  end if;
end $patch$;

/* ===== Flytten ar ingen ny pjas: inga chattrader, inga raknare, ingen "created"/"deleted" i loggen.
   Utan det har annonserades en Legendary i chatten vid varje uttag, och en tillverkad pjas raknades som
   tillverkad igen (gratis prestationer). Flaggan satts bara av shared_vault_move, for den egna transaktionen. ===== */
do $patch$
declare v_def text; v_a text;
begin
  v_def := pg_get_functiondef('public.trg_loot_announce_item'::regproc);
  if position('genesis.shared_move' in v_def) = 0 then
    v_a := 'if new.rarity >= 3 and new.location in (''bag'',''equipped'',''mail'') and new.gem_region is null';
    if position(v_a in v_def) = 0 then raise exception 'ANKARE SAKNAS: trg_loot_announce_item'; end if;
    execute replace(v_def, v_a, v_a || ' and coalesce(current_setting(''genesis.shared_move'', true), '''') <> ''on''' /* [TILLAGT v5.1413.0-valv] */);
  end if;

  v_def := pg_get_functiondef('public.trg_crafted_counter'::regproc);
  if position('genesis.shared_move' in v_def) = 0 then
    v_a := 'if (TG_OP = ''INSERT'' and coalesce(new.crafted, false))';
    if position(v_a in v_def) = 0 then raise exception 'ANKARE SAKNAS: trg_crafted_counter'; end if;
    execute replace(v_def, v_a, 'if coalesce(current_setting(''genesis.shared_move'', true), '''') = ''on'' then return new; end if;   /* [TILLAGT v5.1413.0-valv] */
  ' || v_a);
  end if;

  v_def := pg_get_functiondef('public.trg_item_log'::regproc);
  if position('genesis.shared_move' in v_def) = 0 then
    v_a := 'if tg_op = ''INSERT'' then';
    if position(v_a in v_def) = 0 then raise exception 'ANKARE SAKNAS: trg_item_log'; end if;
    execute replace(v_def, v_a, 'if coalesce(current_setting(''genesis.shared_move'', true), '''') = ''on'' then return coalesce(new, old); end if;   /* [TILLAGT v5.1413.0-valv] flytten loggas av shared_vault_move */
  ' || v_a);
  end if;
end $patch$;

/* ===== Hjalpare ===== */
create or replace function public.shared_vault_cfg(p_key text)
returns integer language plpgsql stable security definer set search_path = public, pg_temp as $function$
declare v integer;
begin
  select val into v from public.shared_vault_config where key = p_key;
  if v is null then raise exception 'shared_vault_config_missing' using errcode = 'P0001'; end if;
  return v;
end $function$;

create or replace function public.shared_vault_used(p_profile uuid)
returns integer language sql stable security definer set search_path = public, pg_temp as $function$
  select ((select count(*) from public.shared_vault_items where profile_id = p_profile)
        + (select count(*) from public.shared_vault_stacks where profile_id = p_profile))::integer;
$function$;

/* Far den har stapelsorten ligga i fliken? Utrustning, material och lador - inget bundet.
   Lador (cache_) far inte saljas men Chris vill ha dem har, darfor provas de bara mot Bind on Pickup.
   Material gar genom samma regel som auktionshus, post och handel (can_be_traded), sa skarvor och bundet stoppas pa ETT stalle. */
create or replace function public.shared_vault_stack_rule(p_key text, p_kind text)
returns void language plpgsql stable security definer set search_path = public, pg_temp as $function$
begin
  if coalesce((select bop from public.material_config where key = p_key), false)
     or coalesce((select bop from public.stack_item_config where key = p_key), false) then
    raise exception 'shared_no_bound' using errcode = 'P0001';
  end if;
  if left(p_key, 6) = 'cache_' then return; end if;
  if p_kind is distinct from 'material' then
    raise exception 'shared_wrong_kind' using errcode = 'P0001';
  end if;
  begin
    perform public.can_be_traded(null, p_key);
  exception when sqlstate 'P0001' then
    raise exception 'shared_no_bound' using errcode = 'P0001';
  end;
end $function$;

/* ===== Lasa fliken: det spelet ritar ===== */
create or replace function public.shared_vault_state(p_character uuid)
returns json language plpgsql stable security definer set search_path = public, pg_temp as $function$
declare v_ch public.characters; v_open boolean;
begin
  v_ch := public.owned_character(p_character);
  v_open := exists (select 1 from public.shared_vault_accounts where profile_id = v_ch.profile_id);
  return json_build_object(
    'unlocked', v_open,
    'unlock_credits', public.shared_vault_cfg('unlock_credits'),
    'slots', public.shared_vault_cfg('slots'),
    'used', public.shared_vault_used(v_ch.profile_id),
    'items', (select coalesce(json_agg(i.snapshot order by i.put_at, i.id), '[]'::json)
                from public.shared_vault_items i where i.profile_id = v_ch.profile_id),
    'stacks', (select coalesce(json_agg(json_build_object('stack_key', s.stack_key, 'kind', s.kind, 'rarity', s.rarity, 'qty', s.qty) order by s.stack_key), '[]'::json)
                 from public.shared_vault_stacks s where s.profile_id = v_ch.profile_id));
end $function$;

/* ===== Kopet: en gang per konto, avgors har ===== */
create or replace function public.shared_vault_unlock(p_character uuid)
returns json language plpgsql security definer set search_path = public, pg_temp as $function$
declare v_ch public.characters; v_cost integer; v_n integer;
begin
  v_ch := public.owned_character(p_character);
  perform public.assert_at_vault(p_character);
  v_cost := public.shared_vault_cfg('unlock_credits');
  /* Raden laggs in FORE betalningen: ett samtidigt kop vantar pa den och far "redan upplast", inte en andra debitering.
     Saknas credits faller hela transaktionen och raden med den. */
  insert into public.shared_vault_accounts (profile_id, paid_credits, bought_by, bought_by_name)
  values (v_ch.profile_id, v_cost, p_character, v_ch.name)
  on conflict (profile_id) do nothing;
  get diagnostics v_n = row_count;
  if v_n = 0 then raise exception 'shared_vault_already_unlocked' using errcode = 'P0001'; end if;
  v_ch := public.apply_currency(p_character, 'shared_vault', 0, 0, 0, 0,
            jsonb_build_object('unlock', 'shared_vault'), -v_cost);
  return json_build_object('unlocked', true, 'paid', v_cost, 'credits', v_ch.credits, 'version', v_ch.save_version);
end $function$;

/* ===== VARJE flytt till och fran fliken gar genom den har funktionen =====
   p_to_shared true = vaskan -> fliken, false = fliken -> vaskan. Antingen p_item eller p_stack_key.
   Las i fast ordning: kontot (allt pa kontot gar ett i taget, sa tva samtidiga kan inte bada ta sista rutan eller samma sak),
   sedan pjasen/stapeln. Pjaser kommer bara ur vaskan och gar bara till vaskan - samma vag som valvet. */
create or replace function public.shared_vault_move(p_character uuid, p_to_shared boolean, p_item uuid default null,
  p_stack_key text default null, p_rarity integer default null, p_qty integer default null)
returns json language plpgsql security definer set search_path = public, pg_temp as $function$
declare v_ch public.characters; v_it public.items; v_sv public.shared_vault_items; v_st public.shared_vault_stacks;
        v_slots integer; v_used integer; v_have integer; v_kind text; v_qty integer; v_snap jsonb; v_cols text;
begin
  v_ch := public.owned_character(p_character);
  perform public.sanction_guard(p_character, 'mail_block');   /* samma sparr som att skicka till en egen karaktar med posten */
  perform public.assert_at_vault(p_character);
  if p_to_shared is null or (p_item is null) = (p_stack_key is null) then
    raise exception 'bad_request' using errcode = 'P0001';
  end if;
  if p_qty is not null and p_qty < 1 then raise exception 'bad_quantity' using errcode = 'P0001'; end if;

  perform 1 from public.shared_vault_accounts where profile_id = v_ch.profile_id for update;
  if not found then raise exception 'shared_vault_locked' using errcode = 'P0001'; end if;
  v_slots := public.shared_vault_cfg('slots');
  v_used := public.shared_vault_used(v_ch.profile_id);

  if p_item is not null and p_to_shared then
    select * into v_it from public.items where id = p_item and character_id = p_character for update;
    if not found then raise exception 'item_not_found' using errcode = 'P0001'; end if;
    if v_it.location <> 'bag' then raise exception 'item_not_in_bag' using errcode = 'P0001'; end if;
    if v_it.socket_kind is not null then raise exception 'item_socketed' using errcode = 'P0001'; end if;
    if v_it.sheet_id is not null then raise exception 'item_on_sheet' using errcode = 'P0001'; end if;
    if v_it.gem_region is not null then raise exception 'shared_no_gem' using errcode = 'P0001'; end if;
    if coalesce(v_it.bound, false) then raise exception 'shared_no_bound' using errcode = 'P0001'; end if;
    /* Isatt chip utan markering raknas som bundet - samma regel som nar chipet tas ur. */
    if v_it.mod_chip is not null and coalesce((v_it.mod_chip->>'b')::boolean, true) then
      raise exception 'shared_bound_chip' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.trade_offers o join public.trades t on t.id = o.trade_id
                where o.item_id = p_item and t.status = 'open') then
      raise exception 'item_in_trade' using errcode = 'P0001';
    end if;
    if v_used >= v_slots then raise exception 'shared_vault_full' using errcode = 'P0001'; end if;

    /* Som vid handel: en karaktar ska inte kunna angra en annans Tune. */
    v_snap := to_jsonb(v_it) || jsonb_build_object('tune_prev', null);
    perform set_config('genesis.shared_move', 'on', true);
    delete from public.items where id = v_it.id;
    perform set_config('genesis.shared_move', '', true);
    insert into public.shared_vault_items (id, profile_id, item_key, rarity, snapshot, put_by)
    values (v_it.id, v_ch.profile_id, v_it.item_key, v_it.rarity, v_snap, p_character);
    insert into public.item_log (item_id, character_id, event, item_key, rarity, meta)
    values (v_it.id, p_character, 'shared_in', v_it.item_key, v_it.rarity,
            jsonb_build_object('from', 'bag', 'to', 'shared', 'profile', v_ch.profile_id, 'snapshot', v_snap));

  elsif p_item is not null then
    select * into v_sv from public.shared_vault_items where id = p_item and profile_id = v_ch.profile_id for update;
    if not found then raise exception 'item_not_in_shared' using errcode = 'P0001'; end if;
    perform public.assert_bag_space(p_character, 1);
    v_snap := v_sv.snapshot || jsonb_build_object('character_id', p_character, 'location', 'bag', 'slot_idx', null,
                'socket_kind', null, 'socket_idx', null, 'sheet_id', null, 'sheet_slot', null);
    /* Bara kolumner som finns i bada: en kolumn som tillkommit sedan pjasen lades in far sitt standardvarde. */
    select string_agg(quote_ident(c.column_name), ',') into v_cols from information_schema.columns c
     where c.table_schema = 'public' and c.table_name = 'items' and c.is_generated = 'NEVER' and v_snap ? c.column_name;
    delete from public.shared_vault_items where id = v_sv.id;
    perform set_config('genesis.shared_move', 'on', true);
    execute format('insert into public.items (%s) select %s from jsonb_populate_record(null::public.items, $1)', v_cols, v_cols) using v_snap;
    perform set_config('genesis.shared_move', '', true);
    insert into public.item_log (item_id, character_id, event, item_key, rarity, meta)
    values (v_sv.id, p_character, 'shared_out', v_sv.item_key, v_sv.rarity,
            jsonb_build_object('from', 'shared', 'to', 'bag', 'profile', v_ch.profile_id, 'put_by', v_sv.put_by));

  elsif p_to_shared then
    select qty, kind into v_have, v_kind from public.stacks
     where character_id = p_character and stack_key = p_stack_key and coalesce(rarity, -1) = coalesce(p_rarity, -1) for update;
    if v_have is null then raise exception 'nothing_to_store' using errcode = 'P0001'; end if;
    perform public.shared_vault_stack_rule(p_stack_key, v_kind);
    v_qty := least(coalesce(p_qty, v_have), v_have);
    if not exists (select 1 from public.shared_vault_stacks where profile_id = v_ch.profile_id and stack_key = p_stack_key
                    and rarity_key = coalesce(p_rarity, -1))
       and v_used >= v_slots then
      raise exception 'shared_vault_full' using errcode = 'P0001';
    end if;
    if not public.take_stack(p_character, p_stack_key, v_qty, p_rarity) then
      raise exception 'nothing_to_store' using errcode = 'P0001';
    end if;
    insert into public.shared_vault_stacks (profile_id, stack_key, kind, rarity, qty)
    values (v_ch.profile_id, p_stack_key, v_kind, p_rarity, v_qty)
    on conflict (profile_id, stack_key, rarity_key) do update set qty = public.shared_vault_stacks.qty + excluded.qty;
    insert into public.item_log (item_id, character_id, event, item_key, rarity, meta)
    values (gen_random_uuid(), p_character, 'shared_in', p_stack_key, p_rarity,
            jsonb_build_object('from', 'bag', 'to', 'shared', 'profile', v_ch.profile_id, 'qty', v_qty, 'kind', v_kind));

  else
    select * into v_st from public.shared_vault_stacks
     where profile_id = v_ch.profile_id and stack_key = p_stack_key and rarity_key = coalesce(p_rarity, -1) for update;
    if not found then raise exception 'nothing_stored' using errcode = 'P0001'; end if;
    v_qty := least(coalesce(p_qty, v_st.qty), v_st.qty);
    if public.stack_needs_slot(p_character, p_stack_key, p_rarity) then
      perform public.assert_bag_space(p_character, 1);
    end if;
    /* Direkt in, inte add_stack: att flytta ska inte rakna som att samla (samma skal som valvet). */
    insert into public.stacks (character_id, stack_key, kind, rarity, qty)
    values (p_character, p_stack_key, v_st.kind, p_rarity, v_qty)
    on conflict (character_id, stack_key, rarity_key) do update set qty = public.stacks.qty + excluded.qty;
    if v_qty >= v_st.qty then
      delete from public.shared_vault_stacks where profile_id = v_ch.profile_id and stack_key = p_stack_key and rarity_key = coalesce(p_rarity, -1);
    else
      update public.shared_vault_stacks set qty = qty - v_qty
       where profile_id = v_ch.profile_id and stack_key = p_stack_key and rarity_key = coalesce(p_rarity, -1);
    end if;
    insert into public.item_log (item_id, character_id, event, item_key, rarity, meta)
    values (gen_random_uuid(), p_character, 'shared_out', p_stack_key, p_rarity,
            jsonb_build_object('from', 'shared', 'to', 'bag', 'profile', v_ch.profile_id, 'qty', v_qty, 'kind', v_st.kind));
  end if;

  update public.characters set save_version = save_version + 1, last_seen_at = now() where id = p_character;
  return json_build_object('ok', true, 'to_shared', p_to_shared, 'item', p_item, 'key', p_stack_key, 'qty', v_qty,
    'used', public.shared_vault_used(v_ch.profile_id), 'slots', v_slots);
end $function$;

/* ===== Vem far kora vad: spelaren tre, resten bara internt. Rattigheten ges forst, sedan tas public/anon bort. ===== */
grant execute on function public.shared_vault_state(uuid) to authenticated;
grant execute on function public.shared_vault_unlock(uuid) to authenticated;
grant execute on function public.shared_vault_move(uuid, boolean, uuid, text, integer, integer) to authenticated;
revoke execute on function public.shared_vault_state(uuid) from public, anon;
revoke execute on function public.shared_vault_unlock(uuid) from public, anon;
revoke execute on function public.shared_vault_move(uuid, boolean, uuid, text, integer, integer) from public, anon;
revoke execute on function public.shared_vault_cfg(text) from public, anon, authenticated;
revoke execute on function public.shared_vault_used(uuid) from public, anon, authenticated;
revoke execute on function public.shared_vault_stack_rule(text, text) from public, anon, authenticated;
