# Sockets och Mod Chips (v1) — GENESIS v5.1358.0 — SOCKETS

Gren: `sockets`. Main ar ororad. Inget ar live forran Chris sett bilderna i `docs-sockets/` och SQL:en korts.

## Vad som ar byggt

**Klienten (`index.html`)** – allt UI och alla listor:

- Pjaser kan ha EN socket och i den EN Mod Chip. Gearkortet visar `◆ +3.00% Crit Chance · Mythic Mod Chip` i egenskapens farg eller `◇ Empty socket`. Vaskan visar en liten sexkant i hornet pa pjaser med socket (tom = mork, fylld = sortens farg); Epic+ med socket glimmar.
- Mod Chips ar FOREMAL (inte staplar) med egen rullad siffra: nycklar `modchip_<sort>_<raritet>` och `salvaged_modchip`, plats 15. De ritas som CSS-sexkant (`.mc-hex`) tills bilder finns – byt klassen mot en `<img>` sa foljer alla stallen med.
- Fyra sorter med tak (klientens `MODCHIP` = serverns `modchip_config`): Crit Chance 1,3/1,7/2,3/3 % (tak 18), Crit Damage 1,8/2,4/3,2/4,2 % (tak 25), Gold Find 2,8/3,7/5,0/6,5 % (tak 40), Dungeon Speed 0,9/1,1/1,5/2 % (tak 12).
- Stats: chipens bidrag raknas in i Crit Chance, Crit Damage, Gold Find och Dungeon Speed (med taket, som servern), plus en egen rad **Mod Chips** (en sexkant per sort, stjarna = full; hovringen visar `Crit Chance 12 / 18 %`, over taket i gratt, Dungeon Speed i sekunder per run).
- Chipsvaljaren (tryck pa socketen / hogerklick / kortets knapp): chips som inte passar i gratt med skal ("Chip rarity too high"), "Cap reached" bara som varning. Omvant: ett chip i vaskan visar vilka pjaser med tom socket det passar.
- Uttag: "Remove chip" – kraver Chip Extractor (Weaponsmith) av chipets raritet eller hogre, den lagsta som racker forbrukas. Chipet kommer tillbaka bundet.
- Socket Drill: kops i World Boss-butiken (15 Boss Marks), anvands fran vaskan eller fran pjasens kort/meny. Pjasen blir bunden.
- Handlaren har en femte flik **Chip Fusion**: tre Salvaged -> ett Epic-chip av valfri sort bland de tre, 25 guld (`CHIP_FUSION_GOLD` i klienten, `idle_config.chip_fusion_gold` pa servern – koppar, 250000 = 25 g).
- Mod Chip Design (pappren): `design_modchip_<sort>_<epic|legendary>` och `design_modchip_mythic_<a>_<b>` (Mythic visar tva sorter, man valjer). Lars via `learn_modchip_design`. Yrke och niva kollas i klienten forst.
- Recept: Jewelcrafter 16 chips (`cr_jc_modchip_*`), Weaponsmith 4 extraktorer (`cr_ws_chip_extractor_*`). Inget guld, inga kits.
- Sparrar: en pjas med chip i kan inte saljas, atervinnas, auktioneras, handlas eller postas – knappar och menyer sager "Remove the Mod Chip first (needs a Chip Extractor)". Serverns felkoder finns i `SRV_ERRORS`.
- How to play: nytt kapitel "Sockets & Mod Chips". Patchnotes-post overst i `patchnotes.json` (discord: hold).
- Versionen `GENESIS v5.1358.0 — SOCKETS` pa de tre stallena.
- **Demo-lage** utan server: `index.html?demo=sockets` fyller karaktaren med exempelgear, chips, borr, extraktorer, papper och Boss Marks, och alla rutor gar att prova lokalt. Rors inte i vanligt spel.

**Servern** – allt i `cloud/sockets-server.sql` (se nedan).

## Vad SQL-filen gor

Kors i Supabase SQL Editor pa projektet `genesis`, hela filen i ett svep. Bara `CREATE OR REPLACE`, `INSERT ... ON CONFLICT`, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`. Ingen DROP. Gar att kora flera ganger. Syntaxen ar kontrollerad med pglast (74 satser, alla PL/pgSQL-kroppar).

1. **Kolumner**: `items.mod_socket boolean`, `items.mod_chip jsonb` (`{"key","k","v","r","salv"}`), `items.bound boolean` (Bind on Pickup), `characters.socket_pity integer` (dolt otursskydd), `stack_item_config.bop boolean`. Varfor inte `items.socket`: `socket_kind/socket_idx` finns redan och betyder vaskplats.
2. **Tabeller**: `slot_config` rad 15 `modchip`; `modchip_config` (sorter, varden, tak); `modchip_drop_config` (chanser per kalla); `modchip_design_config` (pappren); `idle_config` rattar `chip_fusion_gold` (250000), `socket_drill_marks` (15), `socket_pity` (150). `item_config` for 17 chip-nycklar (tom `drop_rarities` – faller aldrig som gear). `stack_item_config` for borren (sell 0, bop), extraktorerna, pappren. `recipe_config` for 20 recept.
3. **Nya funktioner**: `modchip_rar_key`, `modchip_base`, `modchip_gold`, `mod_chip_bonus` (summa per sort med tak), `socket_roll` (chans per raritet + otursskydd), `modchip_make` (skapar chip-foremal: craft +-5 %, salvaged -5 %, fusion exakt, extract samma varde), `socket_drill_use`, `modchip_insert`, `modchip_extract`, `modchip_fusion`, `learn_modchip_design`, `salvaged_modchip_drop`, `modchip_design_drop` (Mythic ger chattrad), `modchip_world_drops` (en rullning per kalla).
4. **Andrade funktioner** (hela funktionen star i filen, byggd ur serverns kod 2026-10-29): `gear_bonus` (+ `mod_chip_bonus` – darmed far pve_crit_of, gold_find_pct, pve_dungeon_start m.fl. chipen automatiskt), `roll_item` (socketrullning fore insert), `trg_loot_announce_item` ("with a socket" for Legendary/Mythic; chips annonseras aldrig), `chat_snapshot_item`, `can_be_traded` (bundet + chip i = stopp for auktion/post/handel), `sell_item`, `salvage_item`, `equip_item`, `tune_item`, `charm_apply`, `transmog_apply`, `buyback_take` (socket/chip/bindning foljer med vid aterkop), `craft_output` (chips via `modchip_make`), `wb_marks_redeem` (`socket_drill`), `pve_fight`, `claim_expedition`, `pve_dungeon_claim`, `wb_reward` (droppar), `inspect_player`.
5. Nya security definer-funktioner: `revoke execute from public, anon; grant execute to authenticated`.

### Ankarstrangar (for replace() lokalt om servern hunnit andras sedan 2026-10-29)

Hela listan med ankare -> ersattning finns i `cloud/sockets-anchors.md`. Kort:

| Funktion | Ankare | Vad som laggs till |
|---|---|---|
| gear_bonus | `  ), 0)\n  + case p_key` | `+ public.mod_chip_bonus(p_character, p_key)` |
| roll_item | `v_chance numeric; v_hits integer := 0; v_best numeric;` / `insert into public.items (... god_roll)` | `v_sock`, `socket_roll(...)`, kolumn `mod_socket` |
| trg_loot_announce_item | `if new.rarity >= 3 and new.location in (...)` / `'found ' || case when new.rarity >= 5` | chips undantas; ` item with a socket: [[item]]!` |
| can_be_traded | hela | bundet + chip_inserted |
| sell_item / salvage_item | `if v_it.favorite then raise exception 'item_favorite'` | `chip_inserted`, `chip_not_gear` |
| equip_item / tune_item | `if not found then raise exception 'item_not_found' using errcode='P0001'; end if;` | `chip_not_gear` |
| charm_apply | `if v_it.gem_region is not null or v_ic.bag_slots is not null then` | `or v_ic.slot_idx = 15` |
| craft_output | `select * into v_stack from public.stack_item_config where key = v_rc.item_key;` | chip-gren fore |
| wb_marks_redeem | `elsif p_what = 'broken_charm_mythic' then` | `elsif p_what = 'socket_drill'` |
| pve_fight | `v_scrap_qty := round(coalesce(public.pve_val('scrap_qty'), 0)` / `'schematic', v_sch_got) end);` | `v_mc := modchip_world_drops(..., 'encounter', ...)`; `'modchips', v_mc` |
| claim_expedition | `if jsonb_array_length(v_mailed) > 0 then` / `'relic', v_relic, 'recipe', v_rec, 'melon', v_melon,` | `'expedition'` |
| pve_dungeon_claim | `update public.pve_dungeon_runs set state = 'claimed', claimed_at = now(),` / `'schematic', v_sch_got,\n    'used'` | `if v_klar then ... 'dungeon'` |
| wb_reward | `v_gold := round(public.expedition_gold(15, public.world_tier(v_h.character_id` / `' A schematic is in the box.' else '' end);` | `attacks_used >= 20`, 'worldboss', brevtext |
| inspect_player / chat_snapshot_item | `'gem_region', i.gem_region, 'gem_pct', i.gem_pct, 'gem_good', i.gem_good)` / `'gem',v.gem_region,` | `mod_socket`, `mod_chip` |

## Siffrorna (Chris beslut, som i specen)

- Socket vid drop: Common/Uncommon 0 %, Rare 1 %, Epic 2 %, Legendary 4 %, Mythic 8 %. Bara de 12 barbara platserna, aldrig craftat, aldrig handlarens hylla. Loot Luck paverkar inte. Otursskydd 150 (Epic+). Max 1 socket.
- Salvaged Mod Chip: 90 % Rare / 10 % Epic, sort slumpad, alltid -5 %, bundet. Strid 0,05 % per vinst (alla regioner), expedition 1 % vid 8 h tier 4 (skalar), dungeon slutboss 3 %. Aldrig lador, aldrig World Boss.
- Mod Chip Design: strid Epic 0,05 % (Drakemark+), Legendary 0,015 % (Cutlass Bay+), Mythic 0,003 % (Nova Command+); expedition 1,5 / 0,5 / 0,1 % vid 8 h tier 4, skalar med langd (min/480) och region ((1+0,15*tier)/1,6); dungeon slutboss 3 / 1 / 0,4 % (Mythic bara tier 3-4); World Boss minst 20 slag 4 / 1,5 / 0,6 %. Allt i `modchip_drop_config`.
- Chipvarden/tak: se ovan. Craftade +-5 %. Fusion ger exakt Epic-grundvardet.
- Priser: Socket Drill 15 marks. Chip Fusion 25 guld. Extraktorer: Phase Scrap 50/100/200/400 + Charged Scrap 0/10/20/40. Chips: Rare 10 adelstenar + 10 Quartz Crystal + 4 Charged Scrap; Epic 25 + 10 Prism Crystal + 4 Phase Scrap; Legendary 60 + 10 Signal Crystal + 5 Phase Crystal + 8 Phase Scrap; Mythic 140 + 10 Phase Crystal + 4 Genesis Crystal + 16 Phase Scrap. Adelsten: Crit Chance Ruby, Crit Damage Sapphire, Gold Find Diamond, Dungeon Speed Sapphire.

## Sa testar Chris pa testkaraktaren

1. Kor `cloud/sockets-server.sql` i SQL Editor. Ladda om spelet (v5.1358.0 ska sta i hornet).
2. Ge testkaraktaren saker direkt i SQL (byt `<CHAR>` mot karaktarens id):
   ```sql
   -- ett Epic-chip, ett Salvaged, en borr, en extraktor, ett papper
   select public.modchip_make('<CHAR>', 'modchip_crit_epic', 3, 'crit', 'craft');
   select public.modchip_make('<CHAR>', 'salvaged_modchip', 2, 'gold', 'salvaged');
   select public.add_stack('<CHAR>', 'socket_drill', 'item', 1, null);
   select public.add_stack('<CHAR>', 'chip_extractor_epic', 'item', 1, null);
   select public.add_stack('<CHAR>', 'design_modchip_mythic_crit_gold', 'item', 1, null);
   -- en socket pa en buren pjas
   update public.items set mod_socket = true where character_id = '<CHAR>' and location = 'equipped' and slot_idx = 0;
   ```
3. I spelet: oppna kortet pa hjalmen -> "Mod Chip" -> valj chipet. Stats ska visa raden Mod Chips och Crit Chance ska ha okat med chipets tal. Forsok salja hjalmen: sparren ska synas. "Remove chip" -> extraktorn forbrukas, chipet ligger i vaskan (bundet).
4. Borren: hogerklick pa en Rare+ pjas utan socket -> "Drill a socket". Pjasen ska bli bunden (kan inte laggas pa auktion).
5. World Boss-butiken: Socket Drill for 15 marks. Handlaren: fliken Chip Fusion (tre Salvaged behovs; ge tre med `modchip_make ... 'salvaged'`).
6. Pappret: tryck pa det i vaskan -> valj sort -> receptet syns i Jewelcrafter-boken (kraver Jewelcrafter 16).
7. Droppar: `select public.modchip_world_drops('<CHAR>', 'dungeon', 4, 0, true);` nagra ganger ger forr eller senare ett Salvaged-chip/papper (3 % resp. 4,4 %).
8. Att kolla i databasen: `select item_key, rarity, mod_socket, mod_chip, bound from public.items where character_id = '<CHAR>';`

## Testat i molnet

- Klienten i Playwright pa 1920x1080, 1440x900, 1280x800, 820x1180, 390x844, 360x740: inga JS-fel, inget spill i sidled, i demo-laget med alla rutor oppna. Insattning, uttag, borrning och fusion provkorda lokalt (demo). Skarmbilder i `docs-sockets/*.jpg` (desktop = 1440, phone = 390).
- SQL: syntaxkontroll med pglast (alla 74 satser och PL/pgSQL-kroppar). Dessutom provkordes de HANDSKRIVNA delarna (kolumner, tabeller, inserts, de nya funktionerna) mot den riktiga databasen i en transaktion som alltid rullas tillbaka (`begin; ... raise exception; rollback`) pa den dolda testkaraktaren Pinguu: chip-skapande (+1.78 % pa ett Epic Crit-chip, Salvaged 2.66 = 2.8 x 0.95, bundet), taket (3.0 + 16.5 -> 18), otursskyddet (149 -> traff, nollstalls), inget pa craftat/transport, 300 dungeon-rullningar, Mythic-papper med chattrad, pick_item_key_r ger aldrig chips. Ingenting blev kvar i databasen. Det hittade ett riktigt fel (round() pa random() - rattat). De STORA andrade funktionerna (pve_fight m.fl.) ar bara syntaxkontrollerade - Claude lokalt kor hela filen.

## Vad som saknas / att tanka pa

- **Bilder**: chip, socket, borr, extraktor och papper ritas som CSS-sexkant/emoji. Klasser: `.mc-hex` (sexkanten), `.mc-badge` (vaskans horn), `.mc-art` (fonstrets bild). WB-knappen for borren har ingen bild.
- Utrustningsdockan (karaktarsbladet) visar INTE socketmarket pa burna pjaser – bara vaskan (specen). Latt att lagga till i `renderEquip` om Chris vill.
- Loot-filtret i chatten doljer/visar "with a socket"-raden med samma regler som ovriga Legendary/Mythic-fynd.
- World Boss: papper kraver minst 20 slag men INTE att bossen dog (specen sa bara "minst 20 slag"). Vill Chris ha "bara vid kill": lagg till `v_dead and` i wb_reward-ankaret.
- Extraktorn tar den lagsta som racker (Rare-extraktor pa Rare-chip, Epic-extraktor duger ocksa). Vill Chris ha exakt raritet: andra loopen i `modchip_extract`.
- Chipens saljvarde hos handlaren: Rare 2 g, Epic 6 g, Legendary 18 g, Mythic 45 g, Salvaged 80 s (`modchip_gold`). Papper och extraktorer: `stack_item_config.sell`.
- Otursskyddet raknar bara pjaser som gar genom `roll_item` (alla drops gor det).
- `skill_slot_pct` kanner inte plats 15, sa Jewelcrafterns plats-noder paverkar inte chipens tillverkningstid (0 %). Ovriga fart-noder galler.
- Lokalt kvar for Claude: kora SQL:en (garna forst i `begin; ... rollback;`), kolla att `pick_item_key` aldrig ger ett chip (tom drop_rarities), och Discord-posten nar Chris sagt ja (discord: hold).
