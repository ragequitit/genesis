-- ============================================================================
-- GENESIS v5.1353.0 - VARLDEN (3D-kartan i spelet)  -  serverdel  [TILLAGT v5.1353.0]
-- Bara CREATE OR REPLACE / villkorade tillagg. Inga DROP. Kors av Claude lokalt efter provkorning.
--
-- VIKTIGT: 3D-kartan BEHOVER INGEN serverandring for att fungera. Positioner och pratbubblor gar via
-- Supabase Realtime (broadcast pa en OPPEN kanal per region, "varld-<region>") och sparas aldrig i nagon
-- tabell. world_view() finns redan (askadarvyn) och anvands som den ar.
--
-- Det som star har ar VALFRITT och bara om Chris vill lasa kanalerna sa att enbart inloggade spelare kan
-- lyssna och sanda (privata kanaler). Da byts {private: false} mot {private: true} i index.html (wrldSockOpen)
-- och policyerna nedan slapper igenom inloggade. Utan detta ar kanalerna oppna for alla med den publika
-- nyckeln - vilket ar samma skyddsniva som world_view() redan har (bara spelnamn och positioner pa kartan).
-- ============================================================================

-- Realtime: inloggade far lasa (ta emot broadcast) pa varldskanalerna.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'realtime' and tablename = 'messages' and policyname = 'varld_lyssna') then
    create policy varld_lyssna on realtime.messages
      for select to authenticated
      using (realtime.topic() like 'varld-%' and realtime.messages.extension = 'broadcast');
  end if;
end $$;

-- Realtime: inloggade far sanda (broadcast) pa varldskanalerna.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'realtime' and tablename = 'messages' and policyname = 'varld_sanda') then
    create policy varld_sanda on realtime.messages
      for insert to authenticated
      with check (realtime.topic() like 'varld-%' and realtime.messages.extension = 'broadcast');
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- FRAMTID (inte infort, bara antecknat): om hjalparen ska synas aven for spelare som INTE star i samma
-- region (world_view-listan) behover world_view() skicka med 'hjalpare' per spelare:
--   'hjalpare', (select jsonb_build_object('key', p0.species, 'namn', coalesce(nullif(p0.nickname,''), initcap(replace(p0.species,'_',' '))))
--                  from public.pets p0 where p0.character_id = c.id and p0.team_slot is not null order by p0.team_slot limit 1)
-- inne i sp-blockets jsonb_build_object. I samma region kommer hjalparen redan med i realtidspaketet,
-- sa det behovs inte for det Chris bad om nu.
-- ----------------------------------------------------------------------------
