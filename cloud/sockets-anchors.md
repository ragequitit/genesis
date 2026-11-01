# Ankarstrangar for cloud/sockets-server.sql

Varje andrad funktion: ankaret (exakt text i serverns nuvarande kod) och vad det ersatts med. Byggt automatiskt ur serverns kod 2026-10-29.

### gear_bonus

Ankare:
```
  ), 0)
  + case p_key
```
Ersatts med:
```
  ), 0)
  + public.mod_chip_bonus(p_character, p_key)   /* [TILLAGT v5.1358.0] Mod Chips med sortens tak - se mod_chip_bonus */
  + case p_key
```

### roll_item

Ankare:
```
  v_chance numeric; v_hits integer := 0; v_best numeric;
begin
```
Ersatts med:
```
  v_chance numeric; v_hits integer := 0; v_best numeric;
  v_sock boolean := false;   /* [TILLAGT v5.1358.0] socket pa pjasen */
begin
```

### roll_item

Ankare:
```
  if not (v_r = any(v_item.rarities)) then
    raise exception 'item_not_available_in_rarity' using errcode='P0001';
  end if;

```
Ersatts med:
```
  if not (v_r = any(v_item.rarities)) then
    raise exception 'item_not_available_in_rarity' using errcode='P0001';
  end if;
  /* [TILLAGT v5.1358.0] Ett Mod Chip rullas aldrig som gear - det gors av modchip_make. */
  if v_item.slot_idx = 15 then raise exception 'use_modchip_make' using errcode='P0001'; end if;

```

### roll_item

Ankare:
```
  insert into public.items (character_id, item_key, rarity, affixes, hp, gold_value,
                            crafted, location, slot_idx, power, damage, item_level, god_roll)
  values (p_character, p_item_key, v_r, v_aff, v_hp, v_gold,
          v_made, p_location, null, v_power, v_dmg, v_lvl, v_god)
```
Ersatts med:
```
  /* [TILLAGT v5.1358.0] SOCKETEN RULLAS FORE INSERT sa trg_loot_announce_item ser den (chattraden 'with a socket'). */
  v_sock := public.socket_roll(p_character, v_r, v_item.slot_idx, p_location, v_made);
  insert into public.items (character_id, item_key, rarity, affixes, hp, gold_value,
                            crafted, location, slot_idx, power, damage, item_level, god_roll, mod_socket)
  values (p_character, p_item_key, v_r, v_aff, v_hp, v_gold,
          v_made, p_location, null, v_power, v_dmg, v_lvl, v_god, v_sock)
```

### trg_loot_announce_item

Ankare:
```
  if new.rarity >= 3 and new.location in ('bag','equipped','mail') and new.gem_region is null
     and coalesce(current_setting('genesis.crafting', true), '') <> 'on' then
```
Ersatts med:
```
  /* [ANDRAT v5.1358.0] Chips (plats 15) annonseras aldrig - ett tillverkat Epic-chip ar inget fynd. */
  if new.rarity >= 3 and new.location in ('bag','equipped','mail') and new.gem_region is null
     and coalesce(current_setting('genesis.crafting', true), '') <> 'on'
     and not exists (select 1 from public.item_config ic where ic.key = new.item_key and ic.slot_idx = 15) then
```

### trg_loot_announce_item

Ankare:
```
             'found ' || case when new.rarity >= 5 then 'a Mythic' when new.rarity = 4 then 'a Legendary' else 'an Epic' end || ' item: [[item]]!',
```
Ersatts med:
```
             /* [ANDRAT v5.1358.0] Legendary/Mythic MED socket sags i raden (Chris). Epic med socket far bara glimten pa kortet. */
             'found ' || case when new.rarity >= 5 then 'a Mythic' when new.rarity = 4 then 'a Legendary' else 'an Epic' end
                      || case when new.mod_socket and new.rarity >= 4 then ' item with a socket: [[item]]!' else ' item: [[item]]!' end,
```

### trg_loot_announce_item

Ankare:
```
'pve',new.pve_effect,'socket',new.socket_kind,'tune',new.tune_count,'crafted',new.crafted))
```
Ersatts med:
```
'pve',new.pve_effect,'socket',new.socket_kind,'tune',new.tune_count,'crafted',new.crafted,
               'mod_socket',new.mod_socket,'mod_chip',new.mod_chip))
```

### chat_snapshot_item

Ankare:
```
'gem',v.gem_region,'gem_pct',v.gem_pct,
```
Ersatts med:
```
'mod_socket',v.mod_socket,'mod_chip',v.mod_chip,
    'gem',v.gem_region,'gem_pct',v.gem_pct,
```

### inspect_player

Ankare:
```
'gem_region', i.gem_region, 'gem_pct', i.gem_pct, 'gem_good', i.gem_good)
```
Ersatts med:
```
'gem_region', i.gem_region, 'gem_pct', i.gem_pct, 'gem_good', i.gem_good,
               'mod_socket', i.mod_socket, 'mod_chip', i.mod_chip)
```

### can_be_traded

Ankare:
```
(hela funktionen skrivs om)
```
Ersatts med:
```

```

### sell_item

Ankare:
```
  if v_it.favorite then raise exception 'item_favorite' using errcode='P0001'; end if;   /* [TILLAGT v5.1213.0] favoritstjarnan skyddar (Chris) */

```
Ersatts med:
```
  if v_it.favorite then raise exception 'item_favorite' using errcode='P0001'; end if;   /* [TILLAGT v5.1213.0] favoritstjarnan skyddar (Chris) */
  /* [TILLAGT v5.1358.0] En pjas med isatt chip saljs/skrotas inte forran chipet ar uttaget (Chris). */
  if v_it.mod_chip is not null then raise exception 'chip_inserted' using errcode='P0001'; end if;

```

### salvage_item

Ankare:
```
  if v_it.favorite then raise exception 'item_favorite' using errcode='P0001'; end if;   /* [TILLAGT v5.1213.0] */

```
Ersatts med:
```
  if v_it.favorite then raise exception 'item_favorite' using errcode='P0001'; end if;   /* [TILLAGT v5.1213.0] */
  /* [TILLAGT v5.1358.0] En pjas med isatt chip saljs/skrotas inte forran chipet ar uttaget (Chris). */
  if v_it.mod_chip is not null then raise exception 'chip_inserted' using errcode='P0001'; end if;
  /* [TILLAGT v5.1358.0] Ett Mod Chip (plats 15) ar inte gear: det satts i en socket, aldrig pa kroppen. */
  if exists (select 1 from public.item_config ic where ic.key = v_it.item_key and ic.slot_idx = 15) then raise exception 'chip_not_gear' using errcode='P0001'; end if;

```

### equip_item

Ankare:
```
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;

```
Ersatts med:
```
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  /* [TILLAGT v5.1358.0] Ett Mod Chip (plats 15) ar inte gear: det satts i en socket, aldrig pa kroppen. */
  if exists (select 1 from public.item_config ic where ic.key = v_it.item_key and ic.slot_idx = 15) then raise exception 'chip_not_gear' using errcode='P0001'; end if;

```

### tune_item

Ankare:
```
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;

```
Ersatts med:
```
  if not found then raise exception 'item_not_found' using errcode='P0001'; end if;
  /* [TILLAGT v5.1358.0] Ett Mod Chip (plats 15) ar inte gear: det satts i en socket, aldrig pa kroppen. */
  if exists (select 1 from public.item_config ic where ic.key = v_it.item_key and ic.slot_idx = 15) then raise exception 'chip_not_gear' using errcode='P0001'; end if;

```

### charm_apply

Ankare:
```
  if v_it.gem_region is not null or v_ic.bag_slots is not null then
    raise exception 'charm_not_gear' using errcode='P0001';
  end if;
```
Ersatts med:
```
  if v_it.gem_region is not null or v_ic.bag_slots is not null or v_ic.slot_idx = 15 then   /* [ANDRAT v5.1358.0] inte pa ett Mod Chip */
    raise exception 'charm_not_gear' using errcode='P0001';
  end if;
```

### transmog_apply

Ankare:
```
v_ic.slot_idx is null then raise exception 'transmog_not_gear'
```
Ersatts med:
```
v_ic.slot_idx is null or v_ic.slot_idx = 15 then raise exception 'transmog_not_gear'
```

### buyback_take

Ankare:
```
from_vendor, gem_region, gem_pct, gem_good, god_roll, base_level, charmed, apex)
```
Ersatts med:
```
... charmed, apex, mod_socket, mod_chip, bound) + tre varden sist i select
```

### craft_output

Ankare:
```
  select * into v_stack from public.stack_item_config where key = v_rc.item_key;
  if found then
    perform public.add_stack(p_character, v_rc.item_key, 'item', 1, null);
```
Ersatts med:
```
  /* [TILLAGT v5.1358.0] MOD CHIPS gors av modchip_make (eget rullat varde +-5 %, obundet), aldrig av roll_item. */
  if v_rc.item_key like 'modchip\_%' then
    v_item := public.modchip_make(p_character, v_rc.item_key, v_rc.rarity, split_part(v_rc.item_key, '_', 2), 'craft', 'bag');
    return json_build_object('crafted', v_rc.item_key, 'kind', 'gear', 'item', v_item.id, 'rarity', v_item.rarity, 'affixes', v_item.affixes, 'xp_gained', v_xp);
  end if;
  select * into v_stack from public.stack_item_config where key = v_rc.item_key;
  if found then
    perform public.add_stack(p_character, v_rc.item_key, 'item', 1, null);
```

### wb_marks_redeem

Ankare:
```
  elsif p_what = 'broken_charm_mythic' then v_cost := coalesce(public.idle_val('wb_marks_charm_mythic'), 10)::integer;

```
Ersatts med:
```
  elsif p_what = 'broken_charm_mythic' then v_cost := coalesce(public.idle_val('wb_marks_charm_mythic'), 10)::integer;
  elsif p_what = 'socket_drill' then v_cost := coalesce(nullif(public.idle_val('socket_drill_marks'), 0), 15)::integer;   /* [TILLAGT v5.1358.0] Socket Drill 15 marks (Chris), bunden */

```

### wb_marks_redeem

Ankare:
```
      perform public.send_mail(p_character, 'World Boss Courier', 'Your Boss Mark reward', 'Your backpack was full, so the charm waits here.', jsonb_build_array(jsonb_build_object('stack_key', p_what, 'kind', 'item', 'qty', 1)));
```
Ersatts med:
```
      perform public.send_mail(p_character, 'World Boss Courier', 'Your Boss Mark reward', 'Your backpack was full, so it waits here.', jsonb_build_array(jsonb_build_object('stack_key', p_what, 'kind', 'item', 'qty', 1)));   /* [ANDRAT v5.1358.0] aven borren */
```

### pve_fight

Ankare:
```
  v_tier integer; v_credits integer := 0; v_em numeric := 1;

```
Ersatts med:
```
  v_tier integer; v_credits integer := 0; v_em numeric := 1;
  v_mc jsonb := null;   /* [TILLAGT v5.1358.0] Salvaged Mod Chip / Mod Chip Design */

```

### pve_fight

Ankare:
```
    v_scrap_qty := round(coalesce(public.pve_val('scrap_qty'), 0)

```
Ersatts med:
```
    /* [TILLAGT v5.1358.0] MOD CHIPS: Salvaged 0,05 % per vinst (alla regioner), papper Epic 0,05 % (Drakemark+), Legendary 0,015 % (Cutlass Bay+), Mythic 0,003 % (Nova Command+). Loot Luck paverkar inte. */
    begin v_mc := public.modchip_world_drops(p_character, 'encounter', coalesce(v_tier, 0), 0, true); exception when others then v_mc := null; end;
    v_scrap_qty := round(coalesce(public.pve_val('scrap_qty'), 0)

```

### pve_fight

Ankare ([ANDRAT 2026-10-30] Halloween lade 'event_marks' mellan raderna, sa ankaret ar nu bara sista raden):
```
          'schematic', v_sch_got) end);
```
Ersatts med:
```
          'schematic', v_sch_got,
          'modchips', v_mc) end);   /* [TILLAGT v5.1358.0] */
```

### claim_expedition

Ankare ([ANDRAT 2026-10-30] Halloween lade v_evm fore begin, sa ankaret ar nu bara raden):
```
  v_shard text; v_shard_got text := null; v_first_clear boolean; v_lap json;
```
Ersatts med:
```
  v_shard text; v_shard_got text := null; v_first_clear boolean; v_lap json;
  v_mc jsonb := null;   /* [TILLAGT v5.1358.0] Salvaged Mod Chip / Mod Chip Design */
```

### claim_expedition

Ankare:
```
  if jsonb_array_length(v_mailed) > 0 then
    perform public.send_mail(p_character, 'Expedition Depot',
```
Ersatts med:
```
  /* [TILLAGT v5.1358.0] MOD CHIPS: Salvaged 1 %, papper 1,5 / 0,5 / 0,1 % vid 8 h tier 4 - skalar med langd och region. Loot Luck paverkar inte. */
  begin v_mc := public.modchip_world_drops(p_character, 'expedition', v_tier, v_def.mins, true); exception when others then v_mc := null; end;
  if jsonb_array_length(v_mailed) > 0 then
    perform public.send_mail(p_character, 'Expedition Depot',
```

### claim_expedition

Ankare ([ANDRAT 2026-10-30] Halloween lade 'event_marks' pa samma rad):
```
    'relic', v_relic, 'recipe', v_rec, 'melon', v_melon,
```
Ersatts med:
```
    'relic', v_relic, 'recipe', v_rec, 'melon', v_melon, 'modchips', v_mc,
```

### pve_dungeon_claim

Ankare:
```
  v_klar boolean := false; v_charms jsonb := '[]'::jsonb; v_ck text;
```
Ersatts med:
```
  v_klar boolean := false; v_charms jsonb := '[]'::jsonb; v_ck text; v_mc jsonb := null;   /* [TILLAGT v5.1358.0] Mod Chips */
```

### pve_dungeon_claim

Ankare:
```
  update public.pve_dungeon_runs set state = 'claimed', claimed_at = now(),
```
Ersatts med:
```
  /* [TILLAGT v5.1358.0] MOD CHIPS vid klarat lopp (slutbossen besegrad, ingen dod): Salvaged 3 %, papper Epic 3 % / Legendary 1 % / Mythic 0,4 % (Mythic bara tier 3-4). */
  if v_klar then
    begin v_mc := public.modchip_world_drops(p_character, 'dungeon', coalesce(v_sch_tier, 0), 0, true); exception when others then v_mc := null; end;
  end if;
  update public.pve_dungeon_runs set state = 'claimed', claimed_at = now(),
```

### pve_dungeon_claim

Ankare ([ANDRAT 2026-10-30] Halloween lade 'event_marks' pa samma rad):
```
    'schematic', v_sch_got,
```
Ersatts med:
```
    'schematic', v_sch_got, 'modchips', v_mc,
```

### wb_reward

Ankare:
```
  v_items jsonb; v_body text; v_ck text; v_r numeric; v_we numeric; v_wl numeric; v_wm numeric; v_got_charm boolean; v_got_apex boolean;
```
Ersatts med:
```
  v_items jsonb; v_body text; v_ck text; v_r numeric; v_we numeric; v_wl numeric; v_wm numeric; v_got_charm boolean; v_got_apex boolean;
  v_mc jsonb;   /* [TILLAGT v5.1358.0] Mod Chip Design (minst 20 slag) */
```

### wb_reward

Ankare:
```
    if v_h.damage <= 0 then continue; end if;

```
Ersatts med:
```
    if v_h.damage <= 0 then continue; end if;
    v_mc := null;   /* [TILLAGT v5.1358.0] per spelare */

```

### wb_reward

Ankare:
```
    v_gold := round(public.expedition_gold(15, public.world_tier(v_h.character_id, coalesce(v_tier, 0))) * 3
```
Ersatts med:
```
    /* [TILLAGT v5.1358.0] MOD CHIP DESIGN fran World Boss: minst 20 slag. Epic 4 % / Legendary 1,5 % / Mythic 0,6 %. Inga Salvaged. Pappret laggs i brevet. */
    if coalesce(v_h.attacks_used, 0) >= 20 then
      begin v_mc := public.modchip_world_drops(v_h.character_id, 'worldboss', public.world_tier(v_h.character_id, coalesce(v_tier, 0)), 0, false); exception when others then v_mc := null; end;
      if v_mc->'design'->>'key' is not null then v_items := v_items || jsonb_build_array(jsonb_build_object('stack_key', v_mc->'design'->>'key', 'kind', 'item', 'qty', 1)); end if;
    end if;
    v_gold := round(public.expedition_gold(15, public.world_tier(v_h.character_id, coalesce(v_tier, 0))) * 3
```

### wb_reward

Ankare ([ANDRAT 2026-10-30] Halloween lade en rad om event marks efter, sa satsen slutar inte langre har):
```
              || (case when v_paper is not null then ' A schematic is in the box.' else '' end)
```
Ersatts med:
```
              || (case when v_paper is not null then ' A schematic is in the box.' else '' end)
              || (case when v_mc->'design'->>'key' is not null then ' A Mod Chip Design is in the box.' else '' end)   /* [TILLAGT v5.1358.0] */
```

### wb_reward

Ankare:
```
'paper', v_paper, 'rarity', v_rar, 'gold', v_gold, 'xp', v_xp, 'charm', v_got_charm, 'apex', v_got_apex,
```
Ersatts med:
```
'paper', v_paper, 'rarity', v_rar, 'gold', v_gold, 'xp', v_xp, 'charm', v_got_charm, 'apex', v_got_apex, 'modchip_design', v_mc->'design'->>'key',
```

### inspect_player

Ankare:
```
'gem_region', i.gem_region, 'gem_pct', i.gem_pct, 'gem_good', i.gem_good)
```
Ersatts med:
```
'gem_region', i.gem_region, 'gem_pct', i.gem_pct, 'gem_good', i.gem_good,
               'mod_socket', i.mod_socket, 'mod_chip', i.mod_chip)
```

