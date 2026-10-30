/* [TILLAGT v5.1381.0] CLAUDE I GENESIS (Chris 2026-10-30: anvand de 200 dollar i API-krediter varje manad).
   Tre delar, alla i edge-funktionen genesis-ai (supabase/functions/genesis-ai):
   1. NIXIE SVARAR PA FRAGOR i spelet (How to play + patch notes som kunskap). Kvot per konto och dygn (ai_nixie_daily).
   2. RAPPORTERNA sorteras: var 10:e minut far nya bugg-/iderapporter en kort svensk sammanfattning i bug_reports.ai_note.
   3. CHATTEN GRANSKAS innan den syns: chat_send sparar status 'review', Claude godkanner (status ok -> ping) eller stoppar
      (status deleted). Fail-open: fel, saknad nyckel eller ingen svar inom 20 s -> meddelandet slapps.
   Av/pa: idle_config ai_chat_on (0/1), ai_triage_on (0/1), ai_nixie_daily (antal, 0 = av).
   API-nyckeln ligger som hemlighet ANTHROPIC_API_KEY pa edge-funktionerna (Chris lagger in den). */

create extension if not exists pg_net with schema extensions;

create table if not exists public.ai_log (
  id bigserial primary key, at timestamptz not null default now(), kind text not null,
  profile_id uuid, character_id uuid, ref text, input text, output text, verdict text,
  tokens_in integer, tokens_out integer, ms integer);
alter table public.ai_log enable row level security;
create index if not exists ai_log_kind_at on public.ai_log (kind, at);
create index if not exists ai_log_profile_at on public.ai_log (profile_id, at) where kind = 'nixie';

alter table public.bug_reports add column if not exists ai_note text;
alter table public.bug_reports add column if not exists ai_at timestamptz;

insert into public.idle_config (key, value) values ('ai_chat_on', 0), ('ai_triage_on', 1), ('ai_nixie_daily', 30)
on conflict (key) do nothing;

/* hemlig token mellan databasen och edge-funktionen (pg_net skickar den, funktionen kollar den) */
do $v$ begin
  if not exists (select 1 from vault.secrets where name = 'ai_hook_token') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(24), 'hex'), 'ai_hook_token', 'genesis-ai: databasens anrop till edge-funktionen');
  end if;
end $v$;

create or replace function public.ai_hook_ok(p_token text)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $f$ select coalesce(p_token, '') <> '' and p_token = (select decrypted_secret from vault.decrypted_secrets where name = 'ai_hook_token' limit 1) $f$;
revoke execute on function public.ai_hook_ok(text) from public, anon, authenticated;
grant execute on function public.ai_hook_ok(text) to service_role;

/* databasens anrop till edge-funktionen (asynkront via pg_net) */
create or replace function public.ai_post(p_action text, p_body jsonb)
 returns bigint language plpgsql security definer set search_path to 'public', 'pg_temp'
as $f$
declare v_id bigint;
begin
  select net.http_post(
    url := 'https://lbssixfkqoqvpapprpab.supabase.co/functions/v1/genesis-ai',
    body := coalesce(p_body, '{}'::jsonb) || jsonb_build_object('action', p_action),
    headers := jsonb_build_object('Content-Type', 'application/json',
      'x-ai-token', (select decrypted_secret from vault.decrypted_secrets where name = 'ai_hook_token' limit 1)),
    timeout_milliseconds := 30000) into v_id;
  return v_id;
exception when others then
  raise warning 'ai_post %: %', p_action, sqlerrm; return null;
end $f$;
revoke execute on function public.ai_post(text, jsonb) from public, anon, authenticated;

/* NIXIE: kontroll + kvot + logg, anropas av edge-funktionen MED spelarens inloggning */
create or replace function public.ai_nixie_begin(p_character uuid, p_question text)
 returns bigint language plpgsql security definer set search_path to 'public', 'pg_temp'
as $f$
declare v_ch public.characters; v_n integer; v_max integer; v_id bigint; v_q text;
begin
  v_ch := public.owned_character(p_character);
  v_q := btrim(coalesce(p_question, ''));
  if char_length(v_q) < 2 then raise exception 'nixie_empty' using errcode = 'P0001'; end if;
  if char_length(v_q) > 500 then raise exception 'nixie_too_long' using errcode = 'P0001'; end if;
  v_max := coalesce(public.idle_val('ai_nixie_daily'), 30)::integer;
  if v_max <= 0 then raise exception 'nixie_off' using errcode = 'P0001'; end if;
  select count(*) into v_n from public.ai_log where kind = 'nixie' and profile_id = v_ch.profile_id and at > now() - interval '24 hours';
  if v_n >= v_max then raise exception 'nixie_quota' using errcode = 'P0001', detail = v_max::text; end if;
  insert into public.ai_log (kind, profile_id, character_id, input) values ('nixie', v_ch.profile_id, p_character, v_q) returning id into v_id;
  return v_id;
end $f$;
revoke execute on function public.ai_nixie_begin(uuid, text) from public, anon;
grant execute on function public.ai_nixie_begin(uuid, text) to authenticated;

/* CHATTEN: granskade meddelanden pingar forst nar de slapps */
create or replace function public.trg_chat_ai_review()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $f$
begin
  perform public.ai_post('chatguard', jsonb_build_object('id', new.id));
  return new;
end $f$;
create or replace trigger chat_ai_review after insert on public.chat_messages for each row when (new.status = 'review') execute function public.trg_chat_ai_review();
create or replace trigger chat_ping_release after update of status on public.chat_messages for each row when (old.status = 'review' and new.status = 'ok') execute function public.trg_chat_ping();

/* fail-open: det som inte hunnit granskas pa 20 s slapps, och rapportsorteringen startas */
create or replace function public.ai_tick()
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $f$
begin
  update public.chat_messages set status = 'ok' where status = 'review' and created_at < now() - interval '20 seconds';
  if coalesce(public.idle_val('ai_triage_on'), 0) > 0 and extract(minute from now())::integer % 10 = 0
     and exists (select 1 from public.bug_reports where status = 'new' and ai_note is null) then
    perform public.ai_post('triage', '{}'::jsonb);
  end if;
end $f$;
revoke execute on function public.ai_tick() from public, anon, authenticated;

do $p$ declare d text; a text; begin
  /* chat_send: spelarens text sparas som 'review' nar granskningen ar pa (inte emotes, de skriver servern) */
  d := pg_get_functiondef('public.chat_send'::regproc);
  a := E'  insert into public.chat_messages (channel, shard, sender_profile, sender_char, sender_name, sender_tag,\n    to_profile, to_char, to_name, conv, body, attach, sender_handle)\n  values (p_channel, v_shard, v_me, p_character, v_ch.name, v_tag, v_toprof, p_to, v_to.name, v_conv, v_body, v_att,\n          (select handle from public.profiles where id = v_me))';
  if position(a in d) = 0 then raise exception 'ankare chat_send'; end if;
  d := replace(d, a, E'  insert into public.chat_messages (channel, shard, sender_profile, sender_char, sender_name, sender_tag,\n    to_profile, to_char, to_name, conv, body, attach, sender_handle, status)\n  values (p_channel, v_shard, v_me, p_character, v_ch.name, v_tag, v_toprof, p_to, v_to.name, v_conv, v_body, v_att,\n          (select handle from public.profiles where id = v_me),\n          case when coalesce(public.idle_val(''ai_chat_on''), 0) > 0 and v_emj is null and char_length(v_body) > 0 then ''review'' else ''ok'' end)   /* [ANDRAT v5.1381.0] Claude granskar */');
  execute d;
  /* chat_fetch: avsandaren ser sitt eget meddelande medan det granskas */
  d := pg_get_functiondef('public.chat_fetch'::regproc);
  a := 'where c.status = ''ok'' and (p_before is null or c.id < p_before)';
  if position(a in d) = 0 then raise exception 'ankare chat_fetch'; end if;
  d := replace(d, a, 'where (c.status = ''ok'' or (c.status = ''review'' and c.sender_profile = auth.uid())) and (p_before is null or c.id < p_before)   /* [ANDRAT v5.1381.0] */');
  execute d;
end $p$;

select cron.schedule('ai-tick', '* * * * *', 'select public.ai_tick()');
