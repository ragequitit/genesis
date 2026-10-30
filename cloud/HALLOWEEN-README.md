# Sasongsevent (v1) + Halloween 2026 — GENESIS v5.1362.0 — HALLOWEEN

Gren: `halloween` (fran `origin/main` = v5.1359.0). Main ar ororad. Inget ar live forran Chris sett bilderna i `docs-halloween/` och kort SQL:en. Grenarna `sockets` (v5.1360) och `telefonsvep` (v5.1361) ar oberoende; SQL:en har fungerar bade med och utan sockets inlagt.

## Vad som ar byggt

**Grunden ar ATERANVANDBAR**: ett event = rader i tre tabeller + bilder. Klienten laser allt fran servern (`event_state`) och ritar: eventknappen i sidlisten, avdelningen i Events-rutan, eventbutiken, nedrakningen, marken i vaskan och den stora klassbilden. Nasta event (vinter, pask, sommar, nyar) = nya rader + nya bilder, ingen ny kod. Se "Sa lagger man till nasta event" nedan.

**Servern** (`cloud/halloween-server.sql`):

- `season_events` — eventet: nyckel, namn, tagline, `starts_at`/`ends_at` (UTC), `enabled`, markens stapelnyckel/namn/plural/bild, utseende-setets namn/forled/filsuffix/antal delar, accentfarg, flavor.
- `season_event_shop` — butikens varor: `kind` (`appearance`, `gear`, `gold`, `stack`, `title`), pris i marks, `payload`, bild, text, `per_char` (max kop per karaktar), ordning.
- `season_event_drops` — droppchanser per kalla (`encounter`, `expedition`, `dungeon`, `worldboss`): chans, antal min/max, lagsta regionsniva, expeditionens fulla langd, bonus fran hogre regionsniva.
- `season_event_purchases` — kopbok (granser + statistik).
- Nya funktioner: `event_now_key` (intern), `event_state(p_character)` (klienten), `event_mark_drop(p_character, src, tier, mins, deliver)` (intern, en rullning per kalla), `event_shop_buy(p_character, p_event, p_key)` (klienten: drar marks, levererar, bokfor, svarar med nytt lage), `event_patch_fn` (intern, bara vid installation).
- Droppkrokar i `pve_fight`, `claim_expedition`, `pve_dungeon_claim`, `wb_reward` — patchas in i serverns NUVARANDE kod med `event_patch_fn` (laser `pg_get_functiondef`, byter ut ett ankare som finns exakt en gang, skriver tillbaka). Samma anslutningspunkter som sockets-grenen; sockets-raderna rors inte. Kors filen tva ganger hoppas redan patchade krokar over. Ankarna star i `cloud/halloween-anchors.md`.
- `stack_item_config` far `halloween_mark` (sell 0, vendor_sells false, bop true). `item_config` far `jack_head/chest/legs/gloves/boots` (plats 0-4, tom `drop_rarities` = faller aldrig, rullas aldrig).
- Revokes: interna hjalpare `from public, anon, authenticated`; spelarfunktioner `from public, anon` + `grant to authenticated`; tabellerna laser klienten aldrig direkt.
- Testblock sist i filen (kommenterat): spelaranrop under `set_config('request.jwt.claims'...)`, `set_config('request.headers'...)` med `x-genesis-session` och `set_config('role','authenticated')` BARA runt spelaranropen; allt i `begin; ... rollback;`.

**Klienten** (`index.html`):

- Eventknapp i sidlisten (`#nav-event`): syns bara under ett aktivt event, ikon = eventets markbild, raden under namnet = nedrakning ("ends in 6d 13h"). Pa telefon ligger den i hemrutans knappnat som de andra.
- Events-rutan (World Boss-fonstret) far avdelningen **Seasonal event** overst: namn, tagline, nedrakning, antal marks och knappen "Open the Halloween shop". Mellan event visas nasta event med "starts in" (om nagon rad finns).
- Eventbutiken (`#ev-overlay`, egen ruta): hjalte med nedrakning, marks du har, setet med "4 / 5 owned" och "x / 5 worn now", korten (bild, namn, text, pris; "Owned" nar kopt; slackt nar marks inte racker), ovriga varor, "How to earn" (dropptalen ur serverns rader, i klartext), flavor.
- Kop: `event_shop_buy` -> klienten spelar upp svaret (rad i chatten, flytande text, nytt lage, vaskan hamtas om).
- Utseende: kopta delar hamnar i `character_appearances` -> syns i Appearance-valjaren pa alla pjaser av samma plats (alla klasser), kallan star som "Event · Jack-o'-Lantern". `transmog_apply` som forut.
- Stor klassbild: bar man ALLA fem delar som utseende (eller pjas) visas `assets/character/set/<figur>_halloween.webp` i karaktarsrutan och sidlisten (samma `applyClassFigure` som setbilderna v5.1312.0; `EVENT_SETS` kopplar forledet `jack` till filen `halloween` och kraver 5 delar). Saknas filen provladdas den och den vanliga figuren star kvar (reservmonstret).
- Marks i vaskan: `ITEM_DEFS.halloween_mark` (noSell, bop) — "A reward. It cannot be sold or traded." pa kortet, inga saljknappar. Servern (`sell 0`, `can_be_traded`) stoppar auktion/post/handel/forsaljning.
- Beloningskort: "+1 Jack-o'-Marks" efter vunnen strid, i expeditionens kvitto, i dungeonkvittot och i World Boss-rapporten (serverns `event_marks`).
- Felkoder i `SRV_ERRORS`: `event_closed`, `event_item_bad`, `event_item_owned`, `event_marks_short`, `event_kind_unknown`.
- How to play: nytt kapitel **Seasonal events**. Patchnotes-post overst (`discord: "hold"`, fun_en/fun_sv om Nixie som pumpa). Versionen `GENESIS v5.1362.0 — HALLOWEEN` pa de tre stallena. Katalogen (`genesis-catalog`) har de fem setdelarna.
- **Demo-lage** utan server: `index.html?demo=halloween` — butiken, 37 marks i vaskan, nedrakningen, eventknappen, Events-rutan, fyra delar kopta och burna (kop stovlarna for 30, valj utseendet -> klassbilden byts). Rors inte i vanligt spel. `window.HWDEMO` ar Playwright-krokarna.

## Talen (forslag — Chris bestammer)

**Eventfonster**: 2026-10-31 00:00 UTC — 2026-11-09 23:59:59 UTC (10 dagar). `season_events.starts_at/ends_at`.

**Droppar** (`season_event_drops`, Loot Luck paverkar inte):

| Kalla | Chans | Marks | Not |
|---|---|---|---|
| Vunnen strid (encounter) | 25 % | 1 | alla regioner |
| Expedition | 100 % fran 4 h | 1–2 | kortare skalar linjart: 2 h = 50 % chans, 1 mark; 8 h = 1–2 |
| Dungeon (klarat lopp) | 100 % | 2 | +1 fran regionsniva 3 (Cutlass Bay+) |
| World Boss (dodad) | 100 % | 5 | i brevet; flykt ger inget |

Rakneexempel aktiv spelare per dag: ~80 strider = 20, 4–5 hjalpare x 2–3 expeditioner = 15–25, 4 dungeons = 8–12, 2 bossar = 10 -> **ca 55–65 marks/dag**. Hela setet (175) pa **3 dagar**; en vanlig spelare pa 5–7 dagar; eventet ar 10 dagar.

**Butiken** (`season_event_shop`):

| Vara | Sort | Pris | Innehall |
|---|---|---|---|
| Jack-o'-Lantern Head | appearance | 40 | utseende plats 0, en gang |
| Jack-o'-Lantern Chest | appearance | 40 | utseende plats 1, en gang |
| Jack-o'-Lantern Legs | appearance | 35 | utseende plats 2, en gang |
| Jack-o'-Lantern Gloves | appearance | 30 | utseende plats 3, en gang |
| Jack-o'-Lantern Boots | appearance | 30 | utseende plats 4, en gang |
| Legendary Cache | gear | 25 | en Legendary-pjas for din niva, 10 % Mythic (aldrig en vaska) |
| Rare Cache | gear | 8 | en Rare-pjas, 25 % Epic |
| Pile of gold | gold | 10 | 25 guld (250000 koppar) via `apply_currency` med skalet `sell` |

Hela setet = 175 marks. "Caches" levererar pjasen direkt (som `wb_marks_redeem`), inte en lada att oppna — enklare och ingen ny lada pa servern.

## Sa slar man pa/av eventet

- **Pa**: det gar igang av sig sjalvt nar `now()` ar inom `starts_at..ends_at` och `enabled = true`. Klienten fragar `event_state` vid inloggning och var femte minut; eventknappen dyker upp utan omladdning.
- **Av i fortid**: `update public.season_events set enabled = false where key = 'halloween_2026';` (eller flytta `ends_at`). `enabled` skrivs inte over om filen kors igen.
- **Forlanga**: `update public.season_events set ends_at = '2026-11-16 23:59:59+00' where key = 'halloween_2026';`
- **Andra tal**: uppdatera raderna i `season_event_drops` / `season_event_shop`; klienten laser dem vid nasta `event_state` (ingen omladdning).
- Efter eventet ligger marks kvar i vaskan (bundna, osaljbara); samma nyckel fungerar nar eventet kommer igen (ny rad med samma `mark_key`).

## Sa lagger man till nasta event (vinter, pask, sommar, nyar)

Ingen ny kod. Tre insert-satser + bilder:

1. **Bilder** (WebP 256 px, filnamn = nyckel):
   - marken: `assets/items/event/<mark_key>.webp` (t ex `winter_mark.webp`)
   - setets fem delar: `assets/gear/<mapp>/<prefix>_head.webp`, `_chest`, `_legs`, `_gloves`, `_boots` (sokvagen star i butiksraden, mappen ar fri)
   - stora klassbilden: `assets/character/set/<figur>_<figure_suffix>.webp` for elf, cyborg, monkey-pirate, blockman, hoodie-man (hojd 768 som `31.webp`)
2. **Marken**: `insert into stack_item_config (key, name, sell, vendor_sells, bop) values ('winter_mark', 'Snowflake Mark', 0, false, true)`.
3. **Setdelarna** (bara om eventet har ett set): fem `item_config`-rader med nycklar `<prefix>_<del>`, `slot_idx` 0–4, `rarities '{3}'`, `drop_rarities '{}'`. Forledet (`frost` i `frost_head`) ar setets `set_prefix` och far inte krocka med ett befintligt set (`genesis, voidsteel, salvage, phase, circuit, runners, sig*, craft, proto, jack`).
4. **Eventet**: en rad i `season_events`:
   ```sql
   insert into public.season_events (key, name, tagline, starts_at, ends_at, enabled, mark_key, mark_name, mark_plural, mark_art,
     set_name, set_prefix, figure_suffix, set_min, accent, flavor, sort)
   values ('winter_2026', 'Winter', 'The grid freezes over.', '2026-12-18 00:00:00+00', '2027-01-03 23:59:59+00', true,
     'winter_mark', 'Snowflake Mark', 'Snowflake Marks', 'assets/items/event/winter_mark.webp',
     'Frostbound', 'frost', 'winter', 5, '#7ad7ff', 'Every node hums a little slower in the cold.', 20);
   ```
5. **Butiken**: rader i `season_event_shop` med `event_key = 'winter_2026'`. `kind`/`payload`:
   - `appearance` `{"item_key":"frost_head","slot":0}` (+ `per_char 1`)
   - `gear` `{"rarity":4,"up_chance":0.10}`
   - `gold` `{"copper":250000}`
   - `stack` `{"stack_key":"<stack_item_config-nyckel>","qty":1}` (t ex en bunden forbrukningsvara)
6. **Dropparna**: fyra rader i `season_event_drops` (`encounter`, `expedition`, `dungeon`, `worldboss`) — kopiera Halloweens och andra talen.
7. Klienten: ingenting. (Vill man ha en statisk reserv for marken innan servern svarat, som `ITEM_DEFS.halloween_mark`, ar det en rad — men `evRegister` skapar den annars ur serverns svar.)

Tva event samtidigt: det med lagst `sort` vinner; bara ett visas.

## Vad som INTE ar byggt (och varfor)

- **Titeln "Pumpkin King/Queen"**: det finns inget titelsystem i spelet (ingen kolumn, ingen visning). `kind = 'title'` finns i tabellen for framtiden men `event_shop_buy` svarar `event_kind_unknown`. Bygg titlar forst, sedan ar det en rad.
- **Pumpa-charm**: `charm_apply` kanner bara `charm_epic/legendary/mythic/apex_charm` (hardkodat), sa en ny charm kraver andring dar + klientens charmlogik. Hoppat over; `kind = 'stack'` finns sa en bunden vara kan saljas i butiken nar charmen finns.
- **Bilderna** finns inte i repot (Chris har dem lokalt): `assets/items/event/halloween_mark.webp`, `assets/gear/halloween/jack_*.webp`, `assets/character/set/*_halloween.webp`. Sokvagarna ar som i briefen; i skarmbilderna syns darfor reservtecknet (pumpa) och den vanliga klassfiguren. Lagg in filerna pa `halloween`-grenen fore merge.
- Guldets ledgerskal ar `sell` (finns garanterat). Vill Chris ha ett eget skal (`event_shop`): lagg till det i ledgerns lista och byt i `event_shop_buy`.
- Ingen `bump_stat` for marks (ingen statnyckel finns); latt att lagga till i `event_mark_drop`.
- Chatten annonserar inte marks (de ar vanliga).

## Testat i molnet

- Klienten i Playwright: 1920x1080, 1440x900, 1280x800, 820x1180, 390x844, 360x740 — inga JS-fel, inget spill i sidled, med butiken, Events-rutan, vaskan och How to play oppna. Demo-flodet: kop stovlarna (37 -> 7 marks), valj utseendet, `classFigureSrc()` = `assets/character/set/elf_halloween.webp`. Skarmbilder i `docs-halloween/*.jpg` (desktop = 1440, phone = 390).
- SQL: syntaxkontroll med pglast (48 satser, alla PL/pgSQL-kroppar). Patcharna provkordes mot sockets-grenens fullstandiga `pve_fight`/`claim_expedition`/`pve_dungeon_claim`/`wb_reward` (byggda ur serverns kod 2026-10-29): alla 13 ankare finns exakt en gang, och de patchade funktionerna parsar. INGET har korts mot databasen (molnsessionen har inte tillgang). Chris kor filen lokalt, garna forst i `begin; ... rollback;`, och sedan testblocket.

## Chris maste besluta

1. Priserna (175 for setet, 25/8/10 for resten) och dropptalen ovan.
2. Eventets langd (10 dagar) och om det ska ga igang exakt 2026-10-31 00:00 UTC (01:00 svensk tid).
3. Om "Legendary Cache"/"Rare Cache" ska vara pjaser direkt (som nu) eller riktiga lador.
4. Vad som ska in i nasta event (set, marknamn, farg, datum) — se mallen ovan.
5. Discord-posten (patchnotes har `discord: "hold"`).
