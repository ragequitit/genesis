/* [TILLAGT v5.1380.0] ACHIEVEMENTS FOR SOCKETS (under Professions) OCH HALLOWEEN (Events) (Chris 2026-10-30).
   Nya raknare: sockets_dropped(_r5) i roll_item, chips_crafted(_r5) i trg_crafted_counter, extractors_crafted i craft_output.
   Nya beraknade varden i stat_of: chips_worn, chip_capped, hh_clears, hh_heroic, ghost_sheet, horseman_kills. */
do $p$ declare d text; a text; begin
  /* roll_item: en drop med socket */
  d := pg_get_functiondef('public.roll_item'::regproc);
  a := 'v_sock := public.socket_roll(p_character, v_r, v_item.slot_idx, p_location, v_made);';
  if position(a in d) = 0 then raise exception 'ankare roll_item'; end if;
  d := replace(d, a, a || ' if v_sock then perform public.bump_stat(p_character, ''sockets_dropped'', 1); if v_r >= 5 then perform public.bump_stat(p_character, ''sockets_dropped_r5'', 1); end if; end if;   /* [TILLAGT v5.1380.0] achievements */');
  execute d;
  /* trg_crafted_counter: tillverkade chip */
  d := pg_get_functiondef('public.trg_crafted_counter'::regproc);
  a := 'perform public.bump_stat(new.character_id, ''crafted'', 1);';
  if position(a in d) = 0 then raise exception 'ankare crafted'; end if;
  d := replace(d, a, a || E'\n    if new.slot_idx = 15 then perform public.bump_stat(new.character_id, ''chips_crafted'', 1); if new.rarity >= 5 then perform public.bump_stat(new.character_id, ''chips_crafted_r5'', 1); end if; end if;   /* [TILLAGT v5.1380.0] */');
  execute d;
  /* craft_output: tillverkade Chip Extractors */
  d := pg_get_functiondef('public.craft_output'::regproc);
  a := E'    perform public.add_stack(p_character, v_rc.item_key, ''item'', 1, null);\n    return json_build_object(''crafted'', v_rc.item_key, ''kind'', ''item'', ''xp_gained'', v_xp);';
  if position(a in d) = 0 then raise exception 'ankare craft_output'; end if;
  d := replace(d, a, E'    perform public.add_stack(p_character, v_rc.item_key, ''item'', 1, null);\n    if v_rc.item_key like ''chip\\_extractor%'' then perform public.bump_stat(p_character, ''extractors_crafted'', 1); end if;   /* [TILLAGT v5.1380.0] */\n    return json_build_object(''crafted'', v_rc.item_key, ''kind'', ''item'', ''xp_gained'', v_xp);');
  execute d;
  /* stat_of: beraknade varden */
  d := pg_get_functiondef('public.stat_of'::regproc);
  a := '    else coalesce((select value from public.character_stats_counters where character_id = p_character and stat = p_stat), 0) end;';
  if position(a in d) = 0 then raise exception 'ankare stat_of'; end if;
  d := replace(d, a,
'    /* [TILLAGT v5.1380.0] sockets och Halloween */
    when ''chips_worn'' then (select count(*) from public.items where character_id = p_character and location = ''equipped'' and mod_chip is not null)
    when ''chip_capped'' then (select count(*) from (select c.cap, sum((i.mod_chip->>''v'')::numeric) s from public.items i join public.modchip_config c on c.sort = i.mod_chip->>''k''
        where i.character_id = p_character and i.location = ''equipped'' and i.mod_chip is not null group by c.sort, c.cap) z where z.s >= z.cap)
    when ''hh_clears'' then (select count(*) from public.pve_dungeon_runs r where r.character_id = p_character and r.dungeon_id = ''hauntedhouse'' and r.claimed_at is not null and not r.died)
    when ''hh_heroic'' then case when public.heroic_done(p_character, ''hauntedhouse'') then 1 else 0 end
    when ''ghost_sheet'' then case when exists (select 1 from public.character_appearances where character_id = p_character and item_key = ''ghost_sheet'') then 1 else 0 end
    when ''horseman_kills'' then (select count(*) from public.world_boss_hits h join public.world_boss_events e on e.id = h.event_id
        where h.character_id = p_character and e.boss_key = ''horseman'' and e.state = ''dead'' and h.damage > 0)
' || a);
  execute d;
end $p$;

insert into public.achievement_config (id, grp, name, descr, reward_kind, reward_amt, stat, threshold, reward_text, hidden, first) values
 ('pc_chip_1',      'Professions', 'Plugged In',       'Put a Mod Chip in a socket.',                     'silver',  20, 'chips_inserted',       1, null, false, false),
 ('pc_chip_10',     'Professions', 'Fully Wired',      'Put 10 Mod Chips in sockets.',                    'credits',  5, 'chips_inserted',      10, null, false, false),
 ('pc_extract_1',   'Professions', 'Hot Swap',         'Take a Mod Chip out with a Chip Extractor.',      'silver',  20, 'chips_extracted',      1, null, false, false),
 ('pc_press_1',     'Professions', 'Pressed',          'Use a Socket Press.',                             'credits',  5, 'sockets_drilled',      1, null, false, false),
 ('pc_fuse_1',      'Professions', 'Fusion Reactor',   'Fuse three Salvaged Mod Chips into one.',         'silver',  50, 'chips_fused',          1, null, false, false),
 ('pc_fuse_10',     'Professions', 'Chain Reaction',   'Do 10 Chip Fusions.',                             'credits', 10, 'chips_fused',         10, null, false, false),
 ('pc_salv_10',     'Professions', 'Scrap Picker',     'Find 10 Salvaged Mod Chips.',                     'silver',  50, 'salvaged_chips_found',10, null, false, false),
 ('pc_design_1',    'Professions', 'Blueprint',        'Find a Mod Chip Design.',                         'credits',  5, 'chip_designs_found',   1, null, false, false),
 ('pc_design_10',   'Professions', 'Chipwright',       'Find 10 Mod Chip Designs.',                       'title',    1, 'chip_designs_found',  10, 'the Chipwright', false, false),
 ('pc_sock_drop',   'Professions', 'Socket Lottery',   'Get a gear drop with a socket.',                  'credits',  5, 'sockets_dropped',      1, null, false, false),
 ('pc_sock_r5',     'Professions', 'Jackpot',          'Get a Mythic drop with a socket.',                'title',    1, 'sockets_dropped_r5',   1, 'the Socketed', false, false),
 ('pc_chips_worn5', 'Professions', 'Fully Modded',     'Wear Mod Chips in 5 pieces at once.',             'credits', 10, 'chips_worn',           5, null, false, false),
 ('pc_chip_cap',    'Professions', 'Capped Out',       'Reach the cap for one kind of Mod Chip.',         'credits', 10, 'chip_capped',          1, null, false, false),
 ('pc_chipcraft_10','Professions', 'Chipsmith',        'Craft 10 Mod Chips.',                             'silver',  50, 'chips_crafted',       10, null, false, false),
 ('pc_chipcraft_r5','Professions', 'Pure Signal',      'Craft a Mythic Mod Chip.',                        'title',    1, 'chips_crafted_r5',     1, 'the Wired', false, false),
 ('pc_extr_10',     'Professions', 'Tool Maker',       'Craft 10 Chip Extractors.',                       'silver',  50, 'extractors_crafted',  10, null, false, false),
 ('hw26_hh_1',      'Events', 'Haunted Hallways',      'Clear The Haunted House.',                        'silver',  50, 'hh_clears',            1, null, false, false),
 ('hw26_hh_10',     'Events', 'House Regular',         'Clear The Haunted House 10 times.',               'credits', 10, 'hh_clears',           10, null, false, false),
 ('hw26_hh_h',      'Events', 'Haunted Heroics',       'Clear The Haunted House on Heroic.',              'credits', 10, 'hh_heroic',            1, null, false, false),
 ('hw26_ghost',     'Events', 'Boo!',                  'Get a Ghost Sheet.',                              'title',    1, 'ghost_sheet',          1, 'the Spooky', false, false),
 ('hw26_hm_1',      'Events', 'Headhunter',            'Help bring down The Headless Horseman.',          'credits',  5, 'horseman_kills',       1, null, false, false),
 ('hw26_hm_5',      'Events', 'Sleepy Hollow',         'Help bring down The Headless Horseman 5 times.',  'title',    1, 'horseman_kills',       5, 'the Headless', false, false),
 ('ev_mark_10',     'Events', 'Bag of Candy',          'Collect 10 event marks, across all seasonal events.',    'silver', 50, 'event_marks_found',   10, null, false, false),
 ('ev_mark_500',    'Events', 'Pumpkin Patch',         'Collect 500 event marks, across all seasonal events.',   'credits', 25, 'event_marks_found', 500, null, false, false),
 ('ev_mark_1000',   'Events', 'The Great Pumpkin',     'Collect 1,000 event marks, across all seasonal events.', 'title',    1, 'event_marks_found', 1000, 'the Great Pumpkin', false, false)
on conflict (id) do nothing;
