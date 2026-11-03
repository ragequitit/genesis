-- ============================================================================
-- GENESIS v5.1452.0 - 3D-FIGUREN PA SERVERN  [TILLAGT v5.1452.0]
-- Chris 2026-11-01: figurvalet sparas pa servern nar 3D-kartan slapps, sa att det foljer med till andra enheter.
-- Bara utseende: ror varken guld, XP, loot eller topplistor. Listorna ska saga samma sak som FIG_LIST, FIG_SKIN
-- och FIG_COL_ACH i index.html.
-- ============================================================================
alter table public.characters add column if not exists map_fig text, add column if not exists map_col text;

create or replace function public.map_fig_set(p_character uuid, p_fig text default null, p_col text default null)
returns json language plpgsql security definer set search_path to 'public', 'pg_temp' as $function$
declare
  v_fig text := nullif(p_fig, '');
  v_col text := nullif(p_col, '');
  v_need text;
  v_base text;
  v_skin text[];
  v_i int;
begin
  perform public.owned_character(p_character);
  if v_fig is not null then
    if v_fig not in ('warden', 'breaker', 'fabricator', 'prospector', 'runner', 'ranger', 'paladin', 'skel_minion', 'skel_rogue', 'skel_warrior', 'skel_mage') then
      raise exception 'fig_unknown' using errcode = 'P0001';
    end if;
    v_need := case v_fig when 'paladin' then 'dung_heroic_1' when 'skel_minion' then 'dung_clear_1' when 'skel_rogue' then 'dung_clear_10'
      when 'skel_warrior' then 'wb_kill_1' when 'skel_mage' then 'dung_heroic_10' end;
    if v_need is not null and not exists (select 1 from public.profile_achievements where profile_id = auth.uid() and ach_id = v_need) then
      raise exception 'fig_locked' using errcode = 'P0001';
    end if;
  end if;
  if v_col is not null then
    select coalesce(v_fig, c.class_id, 'warden') into v_base from public.characters c where c.id = p_character;
    v_skin := case v_base when 'warden' then array['blue', 'purple'] when 'breaker' then array['white', 'black'] when 'fabricator' then array['green', 'red']
      when 'prospector' then array['blue', 'red'] when 'runner' then array['purple', 'red'] when 'ranger' then array['red', 'green'] when 'paladin' then array['red', 'purple']
      when 'skel_minion' then array['blue', 'green'] when 'skel_rogue' then array['blue', 'green'] when 'skel_warrior' then array['blue', 'green'] when 'skel_mage' then array['blue', 'green'] else array[]::text[] end;
    v_i := array_position(v_skin, v_col);
    if v_i is null then raise exception 'col_unknown' using errcode = 'P0001'; end if;
    if v_i = 2 and not exists (select 1 from public.profile_achievements where profile_id = auth.uid() and ach_id = 'epic_first') then
      raise exception 'col_locked' using errcode = 'P0001';
    end if;
  end if;
  update public.characters set map_fig = v_fig, map_col = v_col where id = p_character;
  return json_build_object('fig', coalesce(v_fig, ''), 'col', coalesce(v_col, ''));
end $function$;

create or replace function public.map_fig_get(p_character uuid)
returns json language plpgsql stable security definer set search_path to 'public', 'pg_temp' as $function$
declare v_r record;
begin
  perform public.owned_character(p_character);
  select map_fig, map_col into v_r from public.characters where id = p_character;
  return json_build_object('fig', v_r.map_fig, 'col', v_r.map_col);
end $function$;

revoke execute on function public.map_fig_set(uuid, text, text) from public, anon;
revoke execute on function public.map_fig_get(uuid) from public, anon;
grant execute on function public.map_fig_set(uuid, text, text) to authenticated;
grant execute on function public.map_fig_get(uuid) to authenticated;
