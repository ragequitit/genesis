-- =====================================================================================================
-- WINDFALL (region 6, tier 5) - serverdelen. [TILLAGT v5.1378.0 gren windfall]
-- INGET AV DETTA AR INLAGT PA SERVERN. Filen kors forst nar Chris sagt "slapp Windfall".
--
-- DEL A (innehall, dolt): regionen, zoner, fiender, expeditioner, dungeon The Beacon, World Boss Cumulo,
--   gem, hjalpare, set, vaskor, uppdrag + sma tillagg i befintliga funktioner (med ankare - avbryter om
--   ankaret saknas, hoppar over om redan lappat). region_config.released = false: bara testkontot
--   (region_released) ser och kan resa till Windfall.
-- DEL B (slappet): achievements + released = true (INTE release_expansion: nivataket ska vara kvar pa 50). Kors NAR Chris sager kor.
--
-- Torrkors med: begin; <DEL A>; <test>; rollback  (eller DO ... RAISE EXCEPTION 'DRY RUN OK').
-- Inga ord som SQL-verktyget stoppar (se CLAUDE.local.md) - darfor "let fall" i stallet for det vanliga ordet.
-- Forslag som Chris inte bestamt ar markerade FORSLAG (tal for tier 5, gemmens extra formagor m.m.).
-- =====================================================================================================

-- ---------- 1. Regionen ----------
insert into public.region_config (id, name, tier, adj, released, release_at)
values ('windfall', 'Windfall', 5, '{quarantine}', false, null)
on conflict (id) do nothing;
update public.region_config set adj = array_append(adj, 'windfall')
 where id = 'quarantine' and not ('windfall' = any(adj));

-- ---------- 2. Tier 5-rader (regelboken kraver egna rader). Windfall ar en niva 50-region: SAMMA tal som tier 4 / The Quarantine (Chris 2026-10-30) ----------
insert into public.cache_weights (tier, weights) values (5, '{510,480,500,400,80,30}') on conflict do nothing;
insert into public.helper_cache_weights (tier, weights) values (5, '{510,480,500,400,80,30}') on conflict do nothing;
insert into public.expedition_gold_config (tier, per_hour) values (5, 400000) on conflict do nothing;
insert into public.pve_cooldown_config (tier, secs) values (5, 90) on conflict do nothing;
insert into public.scrap_weights (tier, rank, pct) values (5,1,5),(5,2,5),(5,3,10),(5,4,80) on conflict do nothing;
insert into public.travel_config (tier, secs, fuel_step) values (5, 1200, 35) on conflict do nothing;  -- anvands forst for resor vidare fran Windfall
insert into public.gather_chance (tier, rare, gem) values (5, 0.24, 0.06) on conflict do nothing;

-- ---------- 3. Zoner (ord 5 = dungeonzonen) ----------
insert into public.zone_config (region, zone, ord, lvl_offset) values
 ('windfall','Dawnmeadow',0,-2), ('windfall','The Kite Yards',1,-1), ('windfall','Gullmarket',2,0),
 ('windfall','The Cloudbanks',3,1), ('windfall','The Windspire',4,2), ('windfall','The Beacon',5,3)
on conflict do nothing;

-- ---------- 4. Fiender (35). Zon = zonen bilden ar malad for (PROMPTER.md "Fiendernas zoner"). ----------
insert into public.pve_name_config (key, ptype, name, blurb, region, zone, family, rank, hp_mult, atk_mult) values
 -- Dawnmeadow
 ('win_sky_rustler','humanoid','Sky Rustler','He came for one sheep. He is leaving with three, if the balloon holds.','windfall','Dawnmeadow','Island Pests',1,0.95,1.1),
 ('win_cloud_ram','creature','Cloud Ram','It has decided the meadow is its meadow.','windfall','Dawnmeadow','Meadow Beasts',1,1.4,1.15),
 ('win_nettle_goat','creature','Nettle Goat','It eats the nettles. The nettles keep growing back on it.','windfall','Dawnmeadow','Meadow Beasts',1,1.4,1.15),
 ('win_pollen_swarm','creature','Pollen Swarm','A hundred busy bees with one shared opinion of you.','windfall','Dawnmeadow','Meadow Beasts',1,1.4,1.15),
 ('win_nestless_hatchling','creature','Nestless Hatchling','It flew up from Drakemark and thinks the sun is its mother.','windfall','Dawnmeadow','Drifted In',1,1.25,1.0),
 -- The Kite Yards
 ('win_lanyard_gull','creature','Lanyard Gull','Half gull, half kite string, all bad temper.','windfall','The Kite Yards','Cloud Gulls',1,0.88,1.25),
 ('win_gust_imp','elemental','Gust Imp','It unties every knot in the yards, just to watch.','windfall','The Kite Yards','Weather Sprites',1,0.78,1.45),
 ('win_snapline_kite','machine','Snapline Kite','Its line snapped years ago. It never came down.','windfall','The Kite Yards','Runaway Kites',1,0.62,1.85),
 ('win_boxkite_brute','machine','Box-Kite Brute','Built to fly, decided to walk, and now it stomps.','windfall','The Kite Yards','Runaway Kites',1,0.62,1.85),
 ('win_dragon_kite','machine','Dragon Kite','A festival kite that took the dragon part seriously.','windfall','The Kite Yards','Runaway Kites',1,0.62,1.85),
 ('win_cube_kite','machine','Cube-Caught Kite','It came up from Voxholm stuck in a blue cube and only flies in right angles.','windfall','The Kite Yards','Drifted In',1,1.25,1.0),
 -- Gullmarket
 ('win_pie_gull','creature','Pie Gull','It did not buy that pie.','windfall','Gullmarket','Cloud Gulls',1,0.88,1.25),
 ('win_balloon_hornet','creature','Balloon Hornet','It floats on its own little balloon and stings on the way down.','windfall','Gullmarket','Island Pests',1,0.95,1.1),
 ('win_thumb_scale','humanoid','Thumb-on-the-Scale','His scale is always right. His thumb is always on it.','windfall','Gullmarket','Market Hustlers',1,1.0,1.0),
 ('win_balloon_tout','humanoid','Balloon Tout','Everything he sells is a bargain, especially the air.','windfall','Gullmarket','Market Hustlers',1,1.0,1.0),
 ('win_receipt_forger','humanoid','Receipt Forger','He has a receipt for everything, including things that never happened.','windfall','Gullmarket','Market Hustlers',1,1.0,1.0),
 -- The Cloudbanks
 ('win_harbour_gull','creature','Harbour Gull','The oldest gull on the jetty. It wants your fish and your respect.','windfall','The Cloudbanks','Cloud Gulls',1,0.88,1.25),
 ('win_drizzle_wisp','elemental','Drizzle Wisp','A small sulky cloud that rains on whoever stands closest.','windfall','The Cloudbanks','Weather Sprites',1,0.78,1.45),
 ('win_mist_pike','creature','Mist Pike','It swims through the haze faster than through water.','windfall','The Cloudbanks','Haze Fish',1,0.55,2.05),
 ('win_cloud_eel','creature','Cloud Eel','Long, soft, smug, and surprisingly bitey.','windfall','The Cloudbanks','Haze Fish',1,0.55,2.05),
 ('win_thunder_carp','creature','Thunder Carp','It crackles when it is happy. It is never happy.','windfall','The Cloudbanks','Haze Fish',1,0.55,2.05),
 ('win_saltfog_deckhand','humanoid','Salt-Fog Deckhand','He rode a fog bank up from Cutlass Bay and still has his mop.','windfall','The Cloudbanks','Drifted In',1,1.25,1.0),
 -- The Windspire
 ('win_weathervane_rooster','machine','Weathervane Rooster','It jumped off the mast and kept pointing at things.','windfall','The Windspire','Island Pests',1,0.95,1.1),
 ('win_barometer_bot','machine','Barometer Bot','Its forecast for you is stormy.','windfall','The Windspire','Weather Automata',1,1.7,0.72),
 ('win_raingauge_walker','machine','Rain-Gauge Walker','It measures every raindrop, and you are standing in its way.','windfall','The Windspire','Weather Automata',1,1.7,0.72),
 ('win_sundial_sentry','machine','Sundial Sentry','It guards the mast by day. Nobody asked what it does at night.','windfall','The Windspire','Weather Automata',1,1.7,0.72),
 ('win_spire_zephyr','elemental','Spire Zephyr','A calm wind with a firm opinion about visitors.','windfall','The Windspire','Updraft Elementals',1,1.4,0.85),
 ('win_static_crackle','elemental','Static Crackle','A ball of static that has never once stood still.','windfall','The Windspire','Updraft Elementals',1,1.4,0.85),
 ('win_thunderhead_calf','elemental','Thunderhead Calf','A baby storm cloud. It will grow up to be a big one.','windfall','The Windspire','Updraft Elementals',1,1.4,0.85),
 ('win_survey_drone','machine','Stray Survey Drone','It drifted up from The Last Armada to map an island that keeps moving.','windfall','The Windspire','Drifted In',1,1.25,1.0),
 -- The Beacon
 ('win_sunglare','elemental','Sunglare','It is very pleased with how bright it is.','windfall','The Beacon','Weather Sprites',1,0.78,1.45),
 ('win_lamplighter_echo','spirit','Lamplighter Echo','It still lights the lamps along the path, every evening.','windfall','The Beacon','Lamp Echoes',1,1.55,0.8),
 ('win_signalman_echo','spirit','Signalman Echo','It keeps sending the same signal downward.','windfall','The Beacon','Lamp Echoes',1,1.55,0.8),
 ('win_keepers_echo','spirit','Keeper''s Echo','It looks down at the clouds as if waiting for an answer.','windfall','The Beacon','Lamp Echoes',1,1.55,0.8),
 ('win_windborne_spore','creature','Windborne Spore','A spore from The Quarantine that rode the warm air all the way up.','windfall','The Beacon','Drifted In',1,1.25,1.0)
on conflict do nothing;

-- ---------- 5. Expeditioner + shards (alla niva 50 - Windfall ar en extra 50-region, Chris 2026-10-30) ----------
insert into public.expedition_config (id, region_id, zone, name, mins, lvl) values
 ('win_dawnmead_1','windfall','Dawnmeadow','Shear the Cloud Sheep',5,50),
 ('win_kiteyard_1','windfall','The Kite Yards','Fly the Morning Race',15,50),
 ('win_gullmark_2','windfall','Gullmarket','Haggle Above the Clouds',45,50),
 ('win_cloudban_2','windfall','The Cloudbanks','Fish the Edge of the Haze',120,50),
 ('win_windspir_3','windfall','The Windspire','Read the Winds From the Top',240,50),
 ('win_beacon_3','windfall','The Beacon','Keep the Lamp Lit Till Morning',480,50)
on conflict do nothing;
insert into public.shard_config (key, exp_id, region_id, name)
select 'shard_' || id, id, 'windfall', name || ' Shard' from public.expedition_config where region_id = 'windfall'
on conflict do nothing;

-- ---------- 6. Undersokning (dronaren) och handel - samma som The Quarantine ----------
insert into public.survey_cost_config (region, step, cost_copper, secs) values
 ('windfall',0,1450000,3300), ('windfall',1,100000,90), ('windfall',2,210000,105),
 ('windfall',3,210000,120), ('windfall',4,310000,135), ('windfall',5,420000,150)
on conflict do nothing;
insert into public.survey_xp_config (region, xp) values ('windfall', 400) on conflict do nothing;
insert into public.credit_trade_config (region, mat_key, qty, credits)
select 'windfall', mat_key, qty, credits from public.credit_trade_config where region = 'quarantine'
on conflict do nothing;
insert into public.stack_item_config (key, name, sell, vendor_sells, bop)
values ('melon_windfall', 'Windfall Mystery Melon', 50000, false, false) on conflict do nothing;

-- ---------- 7. Dungeon The Beacon (spegel av Patient Zero: tider, chanser, heroic) ----------
insert into public.pve_dungeon_config (id, region, zone, name, minutes, revive_max, gear_chance_boss, gear_chance_final,
  w_common, w_uncommon, w_rare, xp_mult_boss, xp_mult_final, scrap_trash, scrap_boss, scrap_final, sig_chance,
  h_minutes, h_revive_max, h_hp_mult, h_atk_mult, h_gear_chance_boss, h_gear_chance_final, h_sig_chance,
  h_w_uncommon, h_w_rare, h_w_epic, event_key, extra_item, extra_chance, h_extra_chance, no_rift)
select 'beacon', 'windfall', 'The Beacon', 'The Beacon', minutes, revive_max, gear_chance_boss, gear_chance_final,
  w_common, w_uncommon, w_rare, xp_mult_boss, xp_mult_final, scrap_trash, scrap_boss, scrap_final, sig_chance,
  h_minutes, h_revive_max, h_hp_mult, h_atk_mult, h_gear_chance_boss, h_gear_chance_final, h_sig_chance,
  h_w_uncommon, h_w_rare, h_w_epic, null, null, 0, 0, false
from public.pve_dungeon_config where id = 'patientzero'
on conflict do nothing;
insert into public.pve_dungeon_fight_config (dungeon_id, ord, minute, kind, name, ptype, level, hp_mult, atk_mult) values
 ('beacon',1,2,'trash','Gallery Gulls','creature',49,0.8,0.5),
 ('beacon',2,5,'trash','Stairwell Echoes','spirit',49,0.8,0.5),
 ('beacon',3,8,'boss','Keeper Hollis Brae','humanoid',50,1.5,0.85),
 ('beacon',4,9,'trash','Loose Prisms','machine',49,0.8,0.5),
 ('beacon',5,12,'trash','Glare Motes','elemental',49,0.8,0.5),
 ('beacon',6,16,'boss','The Great Lens','machine',50,1.5,0.85),
 ('beacon',7,18,'trash','Fog Wisps','elemental',49,0.8,0.5),
 ('beacon',8,21,'trash','Gallery Gulls','creature',49,0.8,0.5),
 ('beacon',9,25,'boss','The Foghorn','machine',50,1.5,0.85),
 ('beacon',10,27,'trash','Stairwell Echoes','spirit',49,0.8,0.5),
 ('beacon',11,30,'trash','Nesting Gulls','creature',49,0.8,0.5),
 ('beacon',12,35,'boss','Gullmother','creature',50,1.5,0.85),
 ('beacon',13,37,'trash','Glare Motes','elemental',49,0.8,0.5),
 ('beacon',14,40,'trash','Lamp Room Echoes','spirit',49,0.8,0.5),
 ('beacon',15,45,'final','The Last Signal','elemental',50,2.5,0.95)
on conflict do nothing;

-- ---------- 8. Gear: signatursetet (sigb_), slumpseten Skyward + Patchwork (bara i Windfall), 24 vaskor ----------
insert into public.item_config (key, name, slot_idx, rarities, bag_slots, drop_rarities, two_hand, region) values
 ('sigb_monocle','Lens-Cut Monocle',0,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_oilskin','Keeper Brae''s Oilskin',1,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_waders','Gallery Waders',2,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_lampwick','Lampwick Gloves',3,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_tailwind','Tailwind Boots',4,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_foghorn','The Foghorn Reed',5,'{0,1,2,3,4,5}',null,'{}',true,null),
 ('sigb_pike','Beacon Pike',5,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_collar','Gullmother''s Down Collar',6,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_keybelt','Keeper''s Key Belt',7,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_signal','Signal Band',8,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_reply','Reply Ring',8,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_lamp','The Unanswered Lamp',9,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_skiff','The Cloud Skiff',11,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('sigb_logbook','Keeper''s Logbook',13,'{0,1,2,3,4,5}',null,'{}',false,null),
 ('skyward_cap','Skyward Aviator Cap',0,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_vest','Skyward Flight Jacket',1,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_trousers','Skyward Trousers',2,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_gloves','Skyward Gloves',3,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_boots','Skyward Boots',4,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_blade','Skyward Cutlass',5,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_neck','Skyward Compass',6,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_waist','Skyward Harness',7,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_band','Skyward Band',8,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_ring','Skyward Signet',8,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_offhand','Skyward Kite Shield',9,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_relic','Skyward Altimeter',13,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('skyward_transport','Skyward Propeller Plane',11,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_cap','Patchwork Top Hat',0,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_vest','Patchwork Coat',1,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_trousers','Patchwork Breeches',2,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_gloves','Patchwork Gloves',3,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_boots','Patchwork Boots',4,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_blade','Patchwork Parasol Blade',5,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_neck','Patchwork Locket',6,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_waist','Patchwork Sash',7,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_band','Patchwork Band',8,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_ring','Patchwork Thimble Ring',8,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_offhand','Patchwork Buckler',9,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_relic','Patchwork Sewing Kit',13,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 ('patchwork_transport','Patchwork Hot-Air Balloon',11,'{0,1,2,3,4,5}',null,'{0,1,2,3,4,5}',false,'windfall'),
 -- vaskor: kolumn = storlek 4/6/8/10/12/14 = raritet 0..5 (godkanda 2026-10-26)
 ('bag_ballast_pouch','Ballast Pouch',10,'{0}',4,'{0}',false,'windfall'),
 ('bag_envelope_satchel','Envelope Satchel',10,'{1}',6,'{1}',false,'windfall'),
 ('bag_basket_rope_pack','Basket Rope Pack',10,'{2}',8,'{2}',false,'windfall'),
 ('bag_balloonists_duffel','Balloonist''s Duffel',10,'{3}',10,'{3}',false,'windfall'),
 ('bag_gondola_travel_pack','Gondola Travel Pack',10,'{4}',12,'{4}',false,'windfall'),
 ('bag_grand_envelope_trunk','Grand Envelope Trunk',10,'{5}',14,'{5}',false,'windfall'),
 ('bag_fleece_pouch','Fleece Pouch',10,'{0}',4,'{0}',false,'windfall'),
 ('bag_shepherds_satchel','Shepherd''s Satchel',10,'{1}',6,'{1}',false,'windfall'),
 ('bag_woolly_backpack','Woolly Backpack',10,'{2}',8,'{2}',false,'windfall'),
 ('bag_cloudfelt_duffel','Cloud-Felt Duffel',10,'{3}',10,'{3}',false,'windfall'),
 ('bag_drovers_travel_pack','Drover''s Travel Pack',10,'{4}',12,'{4}',false,'windfall'),
 ('bag_cumulo_fleece_trunk','Cumulo Fleece Trunk',10,'{5}',14,'{5}',false,'windfall'),
 ('bag_kitetail_pouch','Kite-Tail Pouch',10,'{0}',4,'{0}',false,'windfall'),
 ('bag_sailcloth_satchel','Sailcloth Satchel',10,'{1}',6,'{1}',false,'windfall'),
 ('bag_raceline_pack','Race-Line Pack',10,'{2}',8,'{2}',false,'windfall'),
 ('bag_spool_duffel','Spool Duffel',10,'{3}',10,'{3}',false,'windfall'),
 ('bag_kitewrights_travel_pack','Kitewright''s Travel Pack',10,'{4}',12,'{4}',false,'windfall'),
 ('bag_dragon_kite_trunk','Dragon Kite Trunk',10,'{5}',14,'{5}',false,'windfall'),
 ('bag_vane_pouch','Vane Pouch',10,'{0}',4,'{0}',false,'windfall'),
 ('bag_barometer_satchel','Barometer Satchel',10,'{1}',6,'{1}',false,'windfall'),
 ('bag_mast_climbers_pack','Mast Climber''s Pack',10,'{2}',8,'{2}',false,'windfall'),
 ('bag_weatherkeepers_duffel','Weatherkeeper''s Duffel',10,'{3}',10,'{3}',false,'windfall'),
 ('bag_windspire_travel_pack','Windspire Travel Pack',10,'{4}',12,'{4}',false,'windfall'),
 ('bag_beacon_keepers_trunk','Beacon Keeper''s Trunk',10,'{5}',14,'{5}',false,'windfall')
on conflict do nothing;

-- signaturpjasernas bossar (3 per boss, slutbossen 2 - som de andra dungeonerna). Effekter godkanda av Chris 2026-10-30.
insert into public.pve_signature_config (dungeon_id, boss_ord, item_key, effect_key) values
 ('beacon',3,'sigb_oilskin','armor'), ('beacon',3,'sigb_keybelt','loot_bonus'), ('beacon',3,'sigb_logbook','heal_received'),
 ('beacon',6,'sigb_monocle','opening_strike'), ('beacon',6,'sigb_waders','armor'), ('beacon',6,'sigb_signal','vs_machine'),
 ('beacon',9,'sigb_foghorn','opening_strike'), ('beacon',9,'sigb_lampwick','vs_elemental'), ('beacon',9,'sigb_reply','second_wind'),
 ('beacon',12,'sigb_collar','heal_received'), ('beacon',12,'sigb_tailwind','second_wind'), ('beacon',12,'sigb_skiff','loot_bonus'),
 ('beacon',15,'sigb_lamp','armor'), ('beacon',15,'sigb_pike','vs_spirit')
on conflict do nothing;

-- ---------- 9. World Boss Cumulo (ord 6: helgerna i turordningen - vardagarna 1-5 ar upptagna) ----------
insert into public.world_boss_config (key, name, region, ptype, dungeon, blurb, ord, specials, event_key, hour, zone, enabled)
values ('cumulo', 'Cumulo, the Grazing Giant', 'windfall', 'creature', 'beacon',
  'A cloud sheep as big as an island. Nobody shears it. Nobody has found the front.', 6,
  '{"frost":"Hailfleece","slam":"Hoof Thunder","spores":"Pollen Sneeze","regrow":"Fresh Fleece"}'::jsonb, null, null, null, true)
on conflict do nothing;

-- ---------- 10. Gem: Sunrise Gem of Windfall (Chris 2026-10-25: resor 20 % billigare, 25 % vid god roll; procentdel = hjalpar-XP) ----------
insert into public.gem_config (region_id, key, name, unique_key, unique_text, pct_key, pct_text, good_chance, sell)
values ('windfall', 'gem_windfall', 'Sunrise Gem of Windfall', 'tailwind', 'Travel costs 20% less fuel (25% on a perfect roll)',
        'helper_xp', 'helper XP', 0.05, 150000)
on conflict do nothing;
insert into public.gem_ability_config (key, name, descr, region_id, pool, neg, sort) values
 ('helper_xp', 'Helper XP', 'Helpers in your team level up faster.', 'windfall', false, false, 0),
 ('travel_time', 'Travel time', 'Trips between regions are shorter.', 'windfall', true, true, 1),     -- FORSLAG
 ('fuel_regen', 'Fuel refill', 'Fuel comes back faster.', 'windfall', true, false, 2)                -- FORSLAG
on conflict do nothing;

-- ---------- 11. Hjalpare (10) ----------
insert into public.pet_config (key, name, universal, region_id) values
 ('puff','Puff',false,'windfall'), ('zeph','Zeph',false,'windfall'), ('gale','Gale',false,'windfall'),
 ('nimbus','Nimbus',false,'windfall'), ('dawn','Dawn',false,'windfall'), ('wick','Wick',false,'windfall'),
 ('fluff','Fluff',false,'windfall'), ('skipper','Skipper',false,'windfall'), ('tuft','Tuft',false,'windfall'),
 ('lumen','Lumen',false,'windfall')
on conflict do nothing;

-- ---------- 12. Uppdrag (5 personer x 5; nr 5 = advanced med steg) ----------
insert into public.quest_config (id, category, tier, name, flavor, obj_kind, obj_key, obj_qty, min_lvl, weight, rew_rep, rew_gold, rew_frags, req_prof, steps, region, zone, giver, regions, giver_role) values
 ('wf_wren_01','travel','standard','Mind the Edge','Wren waves you over the meadow gate. First rule up here: know where the islands end. Visit three different zones and come back with your feet still on the grass.','visit',null,3,50,10,22,1500,0,null,null,'windfall',null,'Wren Halloway','{windfall}','Cloud Shepherd'),
 ('wf_wren_02','pve','standard','Sheep in the Sky','Three of Wren''s cloud sheep have floated off again, and the Cloud Rams are not helping. Win three encounters in Dawnmeadow so she can count heads in peace.','pve_wins','zone',3,50,10,26,1800,0,null,null,'windfall','Dawnmeadow','Wren Halloway','{windfall}','Cloud Shepherd'),
 ('wf_wren_03','travel','standard','Breakfast First','Wren has decided you look like someone who skipped breakfast. Open two gear caches while she fries something golden.','cache','gear',2,50,10,28,2000,0,null,null,'windfall',null,'Wren Halloway','{windfall}','Cloud Shepherd'),
 ('wf_wren_04','deliver','standard','A Sore Little Hoof','A cloud lamb hurt its hoof and Wren''s first-aid kit is nearly empty. Craft three items so she can fill it up again.','craft',null,3,50,10,30,2200,0,null,null,'windfall',null,'Wren Halloway','{windfall}','Cloud Shepherd'),
 ('wf_wren_05','pve','advanced','Addressed: Down','Wren has wrapped a parcel addressed only "Down". Carry it to the edge at The Cloudbanks, clear the jetty so it can be lowered safely, then come back to Dawnmeadow.','deliver',null,1,50,10,38,2900,1,null,'[{"qty":1,"kind":"travel","zone":"The Cloudbanks"},{"key":"zone","qty":2,"kind":"pve_wins","zone":"The Cloudbanks"},{"qty":1,"kind":"travel"}]'::jsonb,'windfall','Dawnmeadow','Wren Halloway','{windfall}','Cloud Shepherd'),
 ('wf_dorrit_01','deliver','standard','The Giant Kite','Dorrit''s giant kite needs a frame that will not snap at altitude. Find two pieces of Uncommon quality or better for him to take apart.','find_gear','1',2,50,10,24,1600,0,null,null,'windfall',null,'Dorrit Spindle','{windfall}','Kite Builder'),
 ('wf_dorrit_02','pve','standard','Line Snapped','A kite got loose from The Kite Yards and took three friends with it. Win three encounters there before they start a club.','pve_wins','zone',3,50,10,26,1800,0,null,null,'windfall','The Kite Yards','Dorrit Spindle','{windfall}','Kite Builder'),
 ('wf_dorrit_03','travel','standard','Reading the Streamer','Dorrit measures the wind with a paper streamer and wants a second opinion. Travel to The Windspire and see what the big mast says.','travel',null,1,50,10,26,1900,0,null,null,'windfall','The Windspire','Dorrit Spindle','{windfall}','Kite Builder'),
 ('wf_dorrit_04','deliver','standard','Glue and Feathers','The last test went wrong in a very sticky way. Recycle three pieces of gear so Dorrit has parts for the next attempt.','salvage',null,3,50,10,28,2000,0,null,null,'windfall',null,'Dorrit Spindle','{windfall}','Kite Builder'),
 ('wf_dorrit_05','deliver','advanced','The Morning Race','Dorrit holds the starting flag for the Morning Race, and half the racers still have no tails on their kites. Craft two items for them, then meet him at the start line in The Kite Yards.','deliver',null,1,50,10,36,2700,1,null,'[{"qty":2,"kind":"craft"},{"qty":1,"kind":"travel"}]'::jsonb,'windfall','The Kite Yards','Dorrit Spindle','{windfall}','Kite Builder'),
 ('wf_juno_01','travel','standard','Queen of the Market','"Everything up here is for sale, darling. Go and look at all of it." Visit four different zones and tell Juno what you liked.','visit',null,4,50,10,30,2100,0,null,null,'windfall',null,'Juno Marrow','{windfall}','Balloon Maker'),
 ('wf_juno_02','travel','standard','Three Fingers','Juno holds up three fingers and will not say what they mean. Open three gear caches and she will call it a fair price.','cache','gear',3,50,10,30,2200,0,null,null,'windfall',null,'Juno Marrow','{windfall}','Balloon Maker'),
 ('wf_juno_03','deliver','standard','A Hole in the Envelope','Juno found a hole in her best balloon, and only first-rate material will patch it. Find a piece of Rare quality or better.','find_gear','2',1,50,10,34,2500,1,null,null,'windfall',null,'Juno Marrow','{windfall}','Balloon Maker'),
 ('wf_juno_04','pve','standard','Stop, Thief!','Something was lifted from a Gullmarket stall and the gulls are laughing about it. Win three encounters in Gullmarket until somebody stops laughing.','pve_wins','zone',3,50,10,32,2400,0,null,null,'windfall','Gullmarket','Juno Marrow','{windfall}','Balloon Maker'),
 ('wf_juno_05','pve','advanced','A Letter for a Captain','Juno has a sealed letter for a captain on The Last Armada, who answers every time, just not with words. The only balloon that goes that far down is moored at The Beacon. Clear The Beacon without dying, then come back to Gullmarket.','deliver',null,1,50,10,40,3000,1,null,'[{"key":"beacon","qty":1,"kind":"dungeon"},{"qty":1,"kind":"travel"}]'::jsonb,'windfall','Gullmarket','Juno Marrow','{windfall}','Balloon Maker'),
 ('wf_pip_01','travel','standard','Special Delivery','Pip delivered a parcel to Dawnmeadow from very high up. Go and check that the parcel, and the islander under it, are fine.','travel',null,1,50,10,20,1400,0,null,null,'windfall','Dawnmeadow','Pip','{windfall}','Lighthouse Courier'),
 ('wf_pip_02','expedition','standard','Mail Call','Pip salutes from the mail post with a stack of letters taller than itself. Run an expedition and collect it, and Pip will deliver the news. Eventually.','expeditions',null,1,50,10,34,2500,1,null,null,'windfall',null,'Pip','{windfall}','Lighthouse Courier'),
 ('wf_pip_03','deliver','standard','Three Parcels for You','Pip has been sorting the post and found three parcels with your name on them, all of them clothes. Equip three pieces of gear so they were worth the trip.','equip',null,3,50,10,28,2000,0,null,null,'windfall',null,'Pip','{windfall}','Lighthouse Courier'),
 ('wf_pip_04','deliver','standard','Shiny Bits','Pip sorts letters on a chimney and keeps every shiny thing that falls by. Gather eight Scrap for the new mail slots in the nest.','gather','scrap',8,50,10,26,1800,0,null,null,'windfall',null,'Pip','{windfall}','Lighthouse Courier'),
 ('wf_pip_05','pve','advanced','No Address','Pip found a letter with no address, only a small drawing of a light pointing down. Clear The Beacon on Heroic without dying, then take it to Oswin at The Windspire.','deliver',null,1,50,10,40,3000,1,null,'[{"key":"h:beacon","qty":1,"kind":"dungeon"},{"qty":1,"kind":"travel"}]'::jsonb,'windfall','The Windspire','Pip','{windfall}','Lighthouse Courier'),
 ('wf_oswin_01','travel','standard','A Book of Clear Days','Oswin keeps a book of clear days and needs someone to confirm today''s. Travel to The Beacon and look at the sky for him.','travel',null,1,50,10,28,2000,0,null,null,'windfall','The Beacon','Oswin Tallow','{windfall}','Weather Keeper'),
 ('wf_oswin_02','pve','standard','The Wrong Way','Every vane on the mast points the same wrong way this morning. Win three encounters at The Windspire before anything else decides to change direction.','pve_wins','zone',3,50,10,32,2300,0,null,null,'windfall','The Windspire','Oswin Tallow','{windfall}','Weather Keeper'),
 ('wf_oswin_03','travel','standard','A Gap in the Clouds','Oswin saw something through a gap in the clouds and would rather not say what. Visit five different zones so he can take readings from every side.','visit',null,5,50,10,36,2700,1,null,null,'windfall',null,'Oswin Tallow','{windfall}','Weather Keeper'),
 ('wf_oswin_04','expedition','standard','Closer Every Season','Oswin pins up the map again. The islands have moved closer, as they do every season. Run an expedition and collect it so he can measure how far.','expeditions',null,1,50,10,34,2500,1,null,null,'windfall',null,'Oswin Tallow','{windfall}','Weather Keeper'),
 ('wf_oswin_05','pve','advanced','Signal Sent','Every night for years Oswin has watched the lighthouse beam point downward. Tonight he wants to know who it is talking to. Go to The Beacon, clear the gallery, then come back to the mast.','deliver',null,1,50,10,40,3000,1,null,'[{"qty":1,"kind":"travel","zone":"The Beacon"},{"key":"zone","qty":2,"kind":"pve_wins","zone":"The Beacon"},{"qty":1,"kind":"travel"}]'::jsonb,'windfall','The Windspire','Oswin Tallow','{windfall}','Weather Keeper')
on conflict do nothing;

-- ---------- 13. Hjalpfunktion: gemmens resrabatt (Tailwind) ----------
create or replace function public.gem_tailwind_pct(p_character uuid) returns numeric
language sql stable security definer set search_path to 'public', 'pg_temp' as $f$
  /* [TILLAGT v5.1378.0 windfall] Sunrise Gem of Windfall: resor 20 % billigare, 25 % pa en perfekt sten (Chris 2026-10-25). */
  select coalesce((select case when i.gem_good then 25 else 20 end from public.items i
                   join public.gem_config g on g.region_id = i.gem_region
                   where i.character_id = p_character and i.location = 'equipped' and i.slot_idx = 14
                     and g.unique_key = 'tailwind' limit 1), 0)
$f$;
revoke execute on function public.gem_tailwind_pct(uuid) from public, anon, authenticated;

-- Regionens nivaband. Windfall ar en EXTRA 50-REGION (Chris 2026-10-30): allt ar niva 50, nivataket hojs INTE.
-- Forut raknades bandet alltid som tier*10+1 .. +10; nu kan en region ha eget band (lvl_lo/lvl_hi), annars som forut.
alter table public.region_config add column if not exists lvl_lo integer, add column if not exists lvl_hi integer;
update public.region_config set lvl_lo = 50, lvl_hi = 50 where id = 'windfall';
create or replace function public.region_lvl_lo(p_region text) returns integer
language sql stable security definer set search_path to 'public', 'pg_temp' as $f$
  /* [TILLAGT v5.1378.0 windfall] regionens lagsta niva */
  select coalesce((select coalesce(r.lvl_lo, r.tier * 10 + 1) from public.region_config r where r.id = p_region), 1)
$f$;
create or replace function public.region_lvl_hi(p_region text) returns integer
language sql stable security definer set search_path to 'public', 'pg_temp' as $f$
  /* [TILLAGT v5.1378.0 windfall] regionens hogsta niva */
  select coalesce((select coalesce(r.lvl_hi, r.tier * 10 + 10) from public.region_config r where r.id = p_region), 10)
$f$;
revoke execute on function public.region_lvl_lo(text) from public, anon, authenticated;
revoke execute on function public.region_lvl_hi(text) from public, anon, authenticated;
-- Guldsteget (ring_mult) foljer nivabandet i stallet for numret: Windfall (niva 50) ger som The Quarantine (Chris 2026-10-30).
-- For de fem gamla ar (hi-1)/10 = tier, sa inget andras for dem.
create or replace function public.region_ring_tier(p_region text) returns integer
language sql stable security definer set search_path to 'public', 'pg_temp' as $f$
  /* [TILLAGT v5.1378.0 windfall] */
  select coalesce((select (public.region_lvl_hi(p_region) - 1) / 10 from public.region_config where id = p_region), 0)
$f$;
revoke execute on function public.region_ring_tier(text) from public, anon, authenticated;
create or replace function public.region_level_roll(p_region text)
 returns integer language sql security definer set search_path to 'public', 'pg_temp'
as $function$ /* [ANDRAT v5.1378.0 windfall] regionens eget band (samma som tier*10+1..+10 for de fem gamla) */
  select (public.region_lvl_lo(p_region) + floor(random() * (public.region_lvl_hi(p_region) - public.region_lvl_lo(p_region) + 1)))::integer $function$;

-- ---------- 14. Lappar i befintliga funktioner (ankare; avbryter om ankaret saknas, hoppar over om redan lappat) ----------
do $patch$
declare
  v_def text; v_new text;
  v_test constant text := '8fa27ae5-e0fc-4106-8e8e-737136af78ec';
  r record;
begin
  for r in select * from (values
    -- malbytet: Windfall ar regionsteg 6
    ('ore_exchange(uuid,text,text,integer)', 'ore_exchange',
     'when ''quarantine'' then 5 else 0 end',
     'when ''quarantine'' then 5 when ''windfall'' then 6 else 0 end /* [TILLAGT v5.1378.0 windfall] */',
     'windfall'),
    -- bragder: heroic och Rift i The Beacon
    (null, 'stat_of',
     'when ''rift_patientzero'' then public.rift_best_in(p_character, ''patientzero'')',
     'when ''rift_patientzero'' then public.rift_best_in(p_character, ''patientzero'')' || chr(10) ||
     '    when ''heroic_beacon'' then case when public.heroic_done(p_character, ''beacon'') then 1 else 0 end   /* [TILLAGT v5.1378.0 windfall] */' || chr(10) ||
     '    when ''rift_beacon'' then public.rift_best_in(p_character, ''beacon'')',
     'heroic_beacon'),
    -- gemmen: bransle (Tailwind) i samma tak som klassens rabatt
    (null, 'travel_to',
     '* (1 - least(80, public.class_bonus(p_character, ''fuel_cost'')) / 100.0)))::integer;',
     '* (1 - least(80, public.class_bonus(p_character, ''fuel_cost'') + public.gem_tailwind_pct(p_character)) / 100.0)))::integer;   /* [ANDRAT v5.1378.0 windfall] Sunrise Gem */',
     'gem_tailwind_pct'),
    -- gemmen: kortare resor (FORSLAG), inom samma 60 %-tak
    (null, 'travel_to',
     '+ public.class_bonus(p_character, ''travel'')));',
     '+ public.class_bonus(p_character, ''travel'') + public.gem_pct(p_character, ''travel_time'')));   /* [ANDRAT v5.1378.0 windfall] */',
     'travel_time'),
    -- nivabandet: golvet for resan och zonens niva fran regionens band (Windfall = 50)
    (null, 'travel_to',
     'if public.character_level(v_ch.xp) < coalesce((select tier from public.region_config where id = p_region), 0) * 10 + 1 then',
     'if public.character_level(v_ch.xp) < public.region_lvl_lo(p_region) then   /* [ANDRAT v5.1378.0 windfall] regionens band */',
     'region_lvl_lo(p_region) then'),
    (null, 'travel_to',
     'detail = ((select tier from public.region_config where id = p_region) * 10 + 1)::text;',
     'detail = public.region_lvl_lo(p_region)::text;',
     'detail = public.region_lvl_lo'),
    (null, 'zone_level_roll',
     'v_lo := coalesce(v_tier,0) * 10 + 1;',
     'v_lo := public.region_lvl_lo(p_region);   /* [ANDRAT v5.1378.0 windfall] regionens band */',
     'region_lvl_lo'),
    (null, 'zone_level_roll',
     'v_level := least(v_lo + 9,',
     'v_level := least(public.region_lvl_hi(p_region),',
     'region_lvl_hi'),
    -- guldsteget efter nivabandet
    (null, 'ring_mult',
     'from (select tier from public.region_config where id = p_region) t',
     'from (select public.region_ring_tier(p_region) as tier from public.region_config where id = p_region) t   /* [ANDRAT v5.1378.0 windfall] */',
     'region_ring_tier'),
    (null, 'ring_mult_for',
     'coalesce((select tier from public.region_config where id = p_region), 0)',
     'public.region_ring_tier(p_region)',
     'region_ring_tier'),
    -- expeditionens, idle-fyndens och regionvarvets tal raknas pa guldsteget (Windfall = som The Quarantine)
    (null, 'claim_expedition',
     'select tier into v_tier from public.region_config where id = v_def.region_id;',
     'select public.region_ring_tier(v_def.region_id) into v_tier;   /* [ANDRAT v5.1378.0 windfall] guldsteget */',
     'region_ring_tier(v_def.region_id)'),
    (null, 'roll_idle_drops',
     'select r.tier into v_tier from public.region_config r',
     'select public.region_ring_tier(r.id) into v_tier from public.region_config r   /* [ANDRAT v5.1378.0 windfall] */',
     'region_ring_tier(r.id)'),
    (null, 'region_lap_check',
     'select tier into v_tier from public.region_config where id = p_region;',
     'select public.region_ring_tier(p_region) into v_tier;   /* [ANDRAT v5.1378.0 windfall] */',
     'region_ring_tier(p_region)'),
    -- gemmen: hjalpar-XP
    (null, 'grant_pet_xp',
     '+ public.class_bonus(p_character,''petxp'')) / 100);',
     '+ public.class_bonus(p_character,''petxp'')' || chr(10) ||
     '                   + public.gem_pct(p_character,''helper_xp'')) / 100);   /* [TILLAGT v5.1378.0 windfall] Sunrise Gem */',
     'helper_xp'),
    -- gemmen: snabbare bransle (FORSLAG)
    (null, 'refuel',
     '+ public.skill_pct(p_character, ''player'', ''p_fuel_regen'')) / 100);',
     '+ public.skill_pct(p_character, ''player'', ''p_fuel_regen'')' || chr(10) ||
     '                  + public.gem_pct(p_character, ''fuel_regen'')) / 100);   /* [TILLAGT v5.1378.0 windfall] */',
     'fuel_regen'),
    -- World Boss-listan: en boss i en osläppt region syns bara for testkontot
    (null, 'wb_bosses_json',
     'where c.event_key is null or (c.enabled',
     'where (c.event_key is null and (rc.released or rc.release_at <= now() or auth.uid() = ''' || v_test || '''::uuid))   /* [ANDRAT v5.1378.0 windfall] */' || chr(10) ||
     '     or (c.enabled',
     'v5.1378.0 windfall')
  ) as t(sig, fn, anchor, repl, done_mark)
  loop
    select pg_get_functiondef(p.oid) into v_def from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.proname = r.fn limit 1;
    if v_def is null then raise exception 'saknar funktion %', r.fn; end if;
    if position(r.done_mark in v_def) > 0 and position(r.anchor in v_def) = 0 then
      raise notice 'redan lappad: % (%)', r.fn, r.done_mark; continue;
    end if;
    if position(r.anchor in v_def) = 0 then raise exception 'ankare saknas i %: %', r.fn, r.anchor; end if;
    if (length(v_def) - length(replace(v_def, r.anchor, ''))) / length(r.anchor) <> 1 then
      raise exception 'ankaret finns flera ganger i %: %', r.fn, r.anchor; end if;
    v_new := replace(v_def, r.anchor, r.repl);
    execute v_new;
  end loop;
end $patch$;

-- ---------- 15. Kontroller (kors efter DEL A) ----------
-- select public.expansion_check(5);   -- ok=false tills nagon besokt handlaren i Windfall (vendor_stock) - se DEL B
-- select has_function_privilege('anon', 'public.gem_tailwind_pct(uuid)', 'execute');  -- ska vara false


-- =====================================================================================================
-- DEL B - SLAPPET. Kors BARA nar Chris sagt "slapp Windfall". (Achievements syns for alla direkt,
-- darfor ligger de har och inte i DEL A.)
-- =====================================================================================================
/*
insert into public.achievement_config (id, grp, name, descr, reward_kind, reward_amt, stat, threshold, reward_text, hidden, first) values
 ('rift_beacon_1','Rifts','The Beacon Rift 1','Clear Rift 1 in The Beacon.','credits',10,'rift_beacon',1,null,false,false),
 ('rift_beacon_5','Rifts','The Beacon Rift 5','Clear Rift 5 in The Beacon.','cache_gear',1,'rift_beacon',5,null,false,false),
 ('rift_beacon_10','Rifts','The Beacon Rift 10','Clear Rift 10 in The Beacon.','cache_helper',1,'rift_beacon',10,null,false,false),
 ('rift_beacon_15','Rifts','The Beacon Rift 15','Clear Rift 15 in The Beacon.','credits',25,'rift_beacon',15,null,false,false),
 ('rift_beacon_20','Rifts','The Beacon Rift 20','Clear Rift 20 in The Beacon.','cache_gear',2,'rift_beacon',20,null,false,false),
 ('rift_beacon_25','Rifts','The Beacon Rift 25','Clear Rift 25 in The Beacon.','title',1,'rift_beacon',25,'Keeper of the Last Light',false,false),
 ('repreg_windfall','Reputation','Windfall Trusts You','Reach five stars in Windfall','silver',20,'repreg_windfall',5,null,false,false),
 ('expd_win_dawnmead_1','Expeditions','Shear the Cloud Sheep','Complete Shear the Cloud Sheep in Windfall','silver',20,'expd_win_dawnmead_1',1,null,false,false),
 ('expd_win_kiteyard_1','Expeditions','Fly the Morning Race','Complete Fly the Morning Race in Windfall','silver',20,'expd_win_kiteyard_1',1,null,false,false),
 ('expd_win_gullmark_2','Expeditions','Haggle Above the Clouds','Complete Haggle Above the Clouds in Windfall','silver',20,'expd_win_gullmark_2',1,null,false,false),
 ('expd_win_cloudban_2','Expeditions','Fish the Edge of the Haze','Complete Fish the Edge of the Haze in Windfall','silver',20,'expd_win_cloudban_2',1,null,false,false),
 ('expd_win_windspir_3','Expeditions','Read the Winds From the Top','Complete Read the Winds From the Top in Windfall','silver',20,'expd_win_windspir_3',1,null,false,false),
 ('expd_win_beacon_3','Expeditions','Keep the Lamp Lit Till Morning','Complete Keep the Lamp Lit Till Morning in Windfall','silver',20,'expd_win_beacon_3',1,null,false,false),
 ('expreg_windfall','Expeditions','Windfall Charted','Complete every expedition in Windfall','silver',20,'expreg_windfall',6,null,false,false),
 ('questreg_windfall','Quests','Windfall Helped','Complete 25 quests in Windfall','silver',20,'questreg_windfall',25,null,false,false),
 ('dung_beacon','Dungeons','The Beacon Cleared','Clear The Beacon without dying','silver',20,'dung_beacon',1,null,false,false),
 ('dung_heroic_beacon','Dungeons','The Beacon Heroic','Clear The Beacon on Heroic.','credits',5,'heroic_beacon',1,null,false,false),
 ('w_wind_10','The world','Windfall Regular','Arrive in Windfall 10 times.','credits',5,'arrive_windfall',10,null,false,false),
 ('sf_heroic_beacon','Server First','Heroic Pioneer: The Beacon','Be the first on the server to clear The Beacon on Heroic.','title',1,'heroic_beacon',1,'Pioneer of the Beacon',false,true),
 ('sf_rift_beacon','Server First','First Reply','Be the first on the server to clear Rift 25 in The Beacon.','title',1,'rift_beacon',25,'First Reply',false,true)
on conflict do nothing;
-- handlarens rader (expansion_check kraver vendor_stock for regionen): testkaraktaren Pinguu besoker handlaren
select public.vendor_restock('1272a327-0109-4b39-a7df-4a87e9b619de'::uuid, 'windfall')
 where not exists (select 1 from public.vendor_stock where region_id = 'windfall');
select public.expansion_check(5);          -- ska vara ok:true
update public.region_config set released = true, release_at = coalesce(release_at, now()) where id = 'windfall';   -- nivataket kvar pa 50 (Chris 2026-10-30)
*/
