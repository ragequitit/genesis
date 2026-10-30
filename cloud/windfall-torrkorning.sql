-- Torrkorning av Windfall som testkaraktaren Pinguu. Kors EFTER DEL A i windfall-server.sql i SAMMA anrop.
-- Slutar alltid med RAISE EXCEPTION 'DRY RUN OK: ...' sa att allt rullas tillbaka.
-- Resultat 2026-10-30 (DEL A + detta block): rattigheter stangda, resa 35 bransle (niva 50 kravs, 43 nekas),
-- strid vunnen, expedition (niva 50) startad och hamtad, alla Windfall-niva 50, Cumulo syns bara for testkontot,
-- set Skyward/Patchwork faller i Windfall, ingen annan karaktar ser regionen, expansion_check(5) ok efter handlarbesok.
do $t$
declare
  c constant uuid := '1272a327-0109-4b39-a7df-4a87e9b619de';   -- Pinguu
  o text := ''; j json; v_enc uuid; v_tok text;
begin
  select session_token into v_tok from public.profiles where id = '8fa27ae5-e0fc-4106-8e8e-737136af78ec';
  perform set_config('request.jwt.claims', json_build_object('sub','8fa27ae5-e0fc-4106-8e8e-737136af78ec','role','authenticated')::text, true);
  perform set_config('request.headers', json_build_object('x-genesis-session', v_tok)::text, true);
  o := concat('anon: tailwind=', has_function_privilege('anon', 'public.gem_tailwind_pct(uuid)', 'execute'),
              ' preview=', has_function_privilege('anon', 'public.test_preview(uuid,text)', 'execute'),
              ' auth_preview=', has_function_privilege('authenticated', 'public.test_preview(uuid,text)', 'execute'));
  update public.characters set xp = 9e9, fuel = 100, fuel_at = now(), travel_ends = null, travel_to = null where id = c;
  insert into public.character_regions (character_id, region) values (c, 'windfall') on conflict do nothing;
  begin j := public.travel_to(c, 'windfall'); o := concat(o, ' | travel fuel=', j->>'fuel_paid');
  exception when others then o := concat(o, ' | travel FEL ', sqlerrm); end;
  update public.characters set travel_ends = now() - interval '1 second' where id = c;
  perform public.arrive(c);
  o := concat(o, ' | nu=', (select concat(region, '/', zone) from public.characters where id = c));
  begin
    j := public.pve_reveal(c, 'windfall', 'Dawnmeadow'); o := concat(o, ' | reveal=', j->>'name', ' lvl ', j->>'level');
    select id into v_enc from public.pve_encounters where character_id = c order by created_at desc limit 1;
    j := public.pve_fight(c, v_enc); o := concat(o, ' win=', j->>'win');
  exception when others then o := concat(o, ' | strid FEL ', sqlerrm); end;
  begin
    j := public.start_expedition(c, 'win_dawnmead_1');
    update public.expedition_runs set ends_at = now() - interval '1 second' where character_id = c and exp_id = 'win_dawnmead_1' and claimed_at is null;
    j := public.claim_expedition(c, 'win_dawnmead_1'); o := concat(o, ' | exp=', left(j::text, 160));
  exception when others then o := concat(o, ' | exp FEL ', sqlerrm); end;
  begin j := public.pve_dungeon_sim(c, 'beacon', false, 5, 5, 1, 40, 80, 100, true, false, 0); o := concat(o, ' | dungeon died=', j->>'died');
  exception when others then o := concat(o, ' | dungeon FEL ', sqlerrm); end;
  begin j := public.vendor_look(c, 'windfall'); o := concat(o, ' | vendor ok'); exception when others then o := concat(o, ' | vendor FEL ', sqlerrm); end;
  begin j := public.quest_state(c); o := concat(o, ' | quests_wf=', (select count(*) from public.character_quests where character_id = c and region = 'windfall'));
  exception when others then o := concat(o, ' | quest FEL ', sqlerrm); end;
  o := concat(o, ' | wb_cumulo=', (select count(*) from json_array_elements(public.wb_bosses_json()) e where e->>'key' = 'cumulo'));
  o := concat(o, ' | stat=', public.stat_of(c, 'heroic_beacon'));
  o := concat(o, ' | wf_items_200=', (select count(*) from generate_series(1,200) g where public.gear_drop_pick(c, 3, 1)::text ~ '(skyward|patchwork)_'));
  o := concat(o, ' | other_char_sees=', (select bool_or(public.region_released('windfall', id)) from public.characters where profile_id <> '8fa27ae5-e0fc-4106-8e8e-737136af78ec'));
  o := concat(o, ' | exp5=', public.expansion_check(5)::text);
  raise exception 'DRY RUN OK: %', o;
end $t$;
