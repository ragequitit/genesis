# Telefonsvep – GENESIS v5.1358.0 — TELEFONSVEP

Gren: `telefonsvep`. Inget är live. Titta först på **docs-ux/OVERSIKT.jpg** (alla efter-bilder i ett rutnät), sedan på paren `docs-ux/NN-…-fore.jpg` / `-efter.jpg`.

## Sammanfattning (i spelets ord)

Hela spelet öppnades ruta för ruta i en iPhone-storlek (390 px), en smal Android (360 px) och en dator (1440 px), och varje vy mättes automatiskt: knappar som är för små för ett finger, text som klipps med "…", saker som ligger över varandra, rutor som är högre än skärmen utan att kunna rullas, och hover-effekter som fastnar på pekskärm.

Det stora hittades i fyra högar:

1. **För små knappar.** Lär-knappen i yrkesvalet var 18 px hög (ett finger är ca 40). Flikar i karaktärsrutan, Settings, topplistan, auktionshuset och Quick Access låg på 26–33 px. Pilarna vid kistorna i Fragments var 22 px, kryssen i rutorna 28 px, sökfälten 30 px, antalsrutan i butiken 26 px, kryssrutan "Yes, email me" 13 px. Allt detta är nu minst ~40 px på telefon (och lite större på dator också).
2. **Klippt text.** Settings-flikarna ("ACCO… GAMEP… INTERF…" på 360 px, "Accoun…" även på dator), topplistans "Expediti…", chattens "TR…"-flik, hjälpens "Chat, friends & gu…", sökfältens platshållare ("Search th") och Stats-rutans "Crit C…"/"Cri…" på dator. Allt visas nu helt.
3. **Överlapp och billigt utseende.** Yrkessidans bild (hackan, spolen, rustningen) låg över beskrivningstexten. Knapparna Work/Methods/Skill tree/Unlearn låg som tre ojämna rader. Mötesrutans "Begin encounter" bröts på två rader i en smal knapp bredvid två breda. Achievements på telefon hade ett tomt hål ovanför listan. Fixat.
4. **Hover som "äter" trycket.** 189 hover-regler låg utanför `(hover:hover)`, så en knapp kunde fastna i sitt hover-läge efter ett tryck på pekskärm. Alla är nu inslagna – samma regler, bara att de inte gäller på pekskärm.

Inga spelregler, tal eller serveranrop är rörda. Bara utseende, layout och tryckytor. Inga texter är ändrade.

## Fixar med bildnummer (docs-ux/)

| Nr | Vy | Bredd | Fel | Orsak | Åtgärd |
|---|---|---|---|---|---|
| 01 | Settings | 390/360 | Sex flikar klipptes till "ACCO… GAMEP…"; flikarna 27 px höga; kryss 28 px; knapparna Switch/Sign out/Read 29 px; kryssrutan 13 px | Sex flikar tvingade på en rad med "…" | Två rader om tre hela ord, 40 px höga; kryss 40 px; knappar 40 px; kryssruta 22 px. På dator: tätare bokstäver så alla sex ord ryms, ingen "…" |
| 02 | Leaderboard | 360 | "Expeditions" klipptes; flikarna 28 px; All time/This week 22 px på dator | Nio flikar i fyra spalter | Tre spalter under 400 px, 38 px höga; periodknappar 30/40 px |
| 03 | Fragments (tre lådor med pilar) | 390 | Pilarna 22×22 px, den vänstra halvt under regionsetiketten | Pilarna krympta för att få plats bredvid kistan | 36 px pilar, bildspalten 140 px (126 px på 360 så "Any rarity" inte klipps) |
| 04 | Yrkessidan (Mining m.fl.) | 390 | Bilden låg över beskrivningstexten; Work/Methods/Skill tree/Unlearn i tre ojämna rader; "ALL"-filtret 26 px | Bilden absolut placerad utan att texten lämnar plats | Texten får egen plats till vänster om bilden; knapparna i ett rutnät om två, 42 px höga; ALL 40 px |
| 05 | Yrkesvalet | 390 | Lär-knappen "◉ 1g" 18 px hög; "← Back" 19 px; "Other professions" 30 px | Tätt läge gjort för korta datorskärmar | Minst 40 px på telefon, 32 på dator |
| 06 | Achievements | 390 | Tomt hål mellan ämnesremsan och listan; ämneskorten 36 px | Rutnätet gav remsan halva höjden | Remsan en rad hög, listan tar resten (samma som How to play fick i v5.838); kort 40 px |
| 07 | Mötesrutan (Encounter) | 390 | "Begin encounter" bröts på två rader i smal knapp bredvid två breda | Tre lika breda knappar | Begin på egen hel rad, Give up och Leave delar nästa; alla 40 px |
| 08 | Chatten (öppen på telefon) | 390/360 | Trade-fliken klipptes till "TR…"; verktygsknappar 30 px, emoji 32 px | Bokstavsluft + sidoluft i 37 px breda flikar | Ingen bokstavsluft, 2 px sidoluft: alla sex ord ryms; knappar 38–40 px |
| 09 | Shop | 390 | Antalsrutan 26 px, +/− 28 px breda | Kompakt antalsväljare | 36 px höga fält, 36 px breda +/−, köpknappar 40 px (30 på dator) |
| 10 | How to play | 390 | Sökfältet 30 px och 118 px brett ("Search th"); ämnen klipptes vid 120 px; ämneskort 36 px | Fast bredd 170 px som trycktes ihop | Fältet fyller raden, 40 px högt; ämnesnamn upp till 170 px; kort 40 px |
| 11 | Helpers | 390 | Sökfältet 30 px ("Search na"); Rarity/Recycle 34 px | Samma som 10 | Fältet fyller raden; knappar 40 px (28 på dator, var 24) |
| 12 | Regionrutan | 390 | "You are here" 29 px; zonraderna 37 px | – | 40 resp. 44 px |
| 13 | Inbox | 390 | Take all / Send 34 px | – | 40 px |
| 14 | Auction House | 390 | Buy/Sell/Active 33 px | – | 44 px |
| 15 | Startsidan | 390 | Character/Skill Tree/Paragon/Loadout 28 px; Quick Access-flikarna 26 px; hjälparlagets Loadout 24 px; menyetiketter 7,6–8,6 px (för litet att läsa) | – | Flikar 38–40 px; etiketter 9–9,2 px |
| 16 | Stats-rutan | 1440 | "Crit Chance" → "Crit C…", "Crit Damage" → "Cri…" | Spalten är bara 88 px; namn + värde ryms inte på en rad | Namnet får gå ner på en andra rad för de två raderna; inget klipps |
| 17 | Bugs & ideas | 390 | Krysset 21×22 px; "Privacy"-länken 39×14 px | – | Kryss 40 px; länken får luft runt sig |
| 18 | Before you play (integritet) | 390 | Kryssrutan 13 px; "Read the full text" 29 px | – | 22 px resp. 40 px |
| 19 | Player skill tree | 390 | "Reset tree" 22 px | – | 40 px (32 på dator) |
| 20 | Inventory | 390 | Sort/Sell/Recycle 34 px (20 på dator) | – | 40 px (28 på dator) |
| 21 | Welcome back (offline) | 390 | Krysset 28 px | – | 40 px via den gemensamma kryssregeln |
| 22 | Profile | 390 | Edit profile / Achievements 36 px | – | 40 px |
| – | Hela spelet | alla | 189 hover-regler utanför `(hover:hover)` | Historik | Alla inslagna mekaniskt (samma regler, bara i ett hover-block) |

Övrigt som mättes och var OK: inget horisontellt spill på någon bredd, inga rutor högre än skärmen utan egen rullning, inga JS-fel, inga överlappande syskon i flödet (utöver yrkesbilden ovan).

## Det som INTE kunde provas utan server

- Inloggad data: riktiga listor i Inbox, Achievements med framsteg, Leaderboard, Quests, Guild, Friends, Auction House med riktiga rader, World Boss (visar "Loading…"), Transmissions (claim), Helper loadouts, Dungeon-val, byte av look.
- Chattens serverflöde: många meddelanden, användarkort, viskningar, emoji-panelen med innehåll.
- Nixies guide (startar bara inloggad).
- Riktiga möten: mötesrutan testades med en påhittad fiende (två varianter, en med mycket långt namn) – själva striden (stridsvyn) öppnades inte.
- Kartan (laddas i en egen ram först efter inloggning) och hur rutor ligger över kartan.
- Riktiga iPhone-detaljer: Safaris adressfält som ändrar höjden, nyp-zoom, hur fingret faktiskt träffar.

## Förslag: vad Chris bör prova själv på iPhone

1. **Settings** – sex flikar på två rader; tryck på alla. Krysset uppe till höger.
2. **Fragments** – pilarna vid kistorna (med fler än en kista så de är tända).
3. **Yrkessidan** (Mining/Outfitter) – bilden och texten, de fyra knapparna, sökfältet i boken.
4. **Chatten öppen** – alla sex flikar ska läsas helt; tryck på emoji och verktygen.
5. **Ett riktigt möte** – Begin encounter på egen rad, Give up/Leave under.
6. **Achievements** – ämnesremsan överst, listan direkt under utan hål.
7. **Vilken knapp som helst** – tryck och släpp: ingen glöd ska ligga kvar efteråt (hover-fixen).
8. **Leaderboard på en smal telefon** – tre flikar i bredd.

## Mätning på sex bredder (efter fixarna)

1920×1080, 1440×900, 1280×800, 820×1180, 390×844, 360×740: 54 vyer per bredd.

| Bredd | Vyer | JS-fel | Horisontellt spill |
|---|---|---|---|
| 1920×1080 | 54 | 0 | 0 |
| 1440×900 | 54 | 0 | 0 |
| 1280×800 | 54 | 0 | 0 |
| 820×1180 | 54 | 0 | 0 |
| 390×844 | 54 | 0 | 0 |
| 360×740 | 54 | 0 | 0 |

(Den enda vyn som inte gick att öppna är Nixies guide, som kräver inloggning – det räknas som "kunde inte provas", inte som fel.)
