# Balansförslag inför release – 2026-11-03

> **Status 2026-11-03 (Chris):** Inget görs nu – spelet släpps inte än. Detta ligger på att-göra inför release.
> Preliminärt håller Chris med om: nivåkurvan får stå (fråga 4), idle ska vara en trygg botten, inte en motor (fråga 5), strider ska ge lite mindre (fråga 6), och mycket av pengadelen (fråga 7–8). Resten är obesvarat. Frågorna 1–18 längst ner tas upp när release närmar sig.

**Läst, inte ändrat.** Allt nedan kommer från klienten (index.html, v5.1445.0). Servern (Supabase) går inte att nå från molnet, så där klienten säger "samma som servern" har jag använt klientens kopia och skrivit **(klientkopia)**. Där servern räknar ensam och klienten inte har något tal alls står det **(bara servern vet)**.

De tidigare balansdokumenten (`docs/BALANS-*.md`, `docs/STATUS.md`) finns **inte** i det här repot på GitHub – varken på main eller i historiken. Jag har därför utgått från besluten som står i uppgiften och i kodens egna kommentarer (många är märkta "Chris" med datum). Om dokumenten ligger lokalt hos Chris bör de läggas in i repot, annars kan ingen i molnet jämföra mot dem.

Beslut jag utgår från:
- Nivå 1–50 ska ta ungefär en vecka med vanligt spelande, 2–3 dagar för de mest aktiva.
- Credits har inget dygnstak (Chris 2026-11-03). Fragments och credits är per karaktär.

Pengar skrivs i guld (1 guld = 100 silver = 10 000 koppar).

---

## 1. XP per timme – var det sticker ut

### Så fungerar XP i dag (klientkopia)

- **Nivåkurvan:** nivå 1 kostar 607 XP, sedan +8,45 % per nivå, och från nivå 41 dessutom +20 % extra per nivå ("dyrare 41–50", Chris v5.933).
  Nivå 10: 1 260 · nivå 20: 2 835 · nivå 30: 6 380 · nivå 40: 14 360 · nivå 45: 53 600 · nivå 49: 153 800.
  **Hela vägen 1–50: 779 000 XP, varav 616 000 (79 %) ligger på nivå 41–50.**
- **Alla belöningar räknas som en andel av KÄLLANS nivåsteg:** källans nivåkostnad × vikt × 4,69 % × nivåskillnadsfaktor (0,10 vid fem nivåer under dig … 1,40 vid fyra över). Det betyder att **en strid eller expedition på din egen nivå alltid ger samma procent av nivån, oavsett vilken nivå du är på.** Kurvans brant påverkar alltså inte tiden per nivå för sådant innehåll – den påverkar bara fasta källor (idle) och gammalt innehåll under din nivå.

### Vad varje aktivitet ger (per timme, på din egen nivå)

| Aktivitet | Per gång | Per timme och plats | Källa |
|---|---|---|---|
| Expedition 5 min | 8,4 % av en nivå | **~100 % av en nivå** | klientkopia |
| Expedition 15 min | 24,8 % (tak 25 %) | **~99 % av en nivå** | klientkopia |
| Expedition 45 min | 25 % (taket slår in) | 33 % | klientkopia |
| Expedition 2 h | 25 % (taket) | 12,5 % | klientkopia |
| Expedition 4 h | 25 % (taket) | 6 % | klientkopia |
| Expedition 8 h | 25 % (taket) | 3 % | klientkopia |
| Strid, vanlig fiende | 4,7 % av en nivå (om vikten är 1) | beror på hur många strider man hinner; vilan är 30 s på nivå 1–10 upp till 4 min på 41–50 | bara servern vet vikten |
| Strid, elit | 3 × vanlig = 14 % | – | klienttext |
| Idle (bara vara där) | 0,18 XP/s × 1,8 per region-ring, +15 % med Core Sync | Voxholm ~745 XP/h, Quarantine ~7 800 XP/h | klientkopia |
| Dungeons | – | – | bara servern vet |
| Quests | – | – | bara servern vet |
| Yrken (ger yrkes-XP, inte spelar-XP) | 10 + 0,6 per material + rankbonus 0/20/50/100/175/275; pappersrecept 12/100/350/800/1 500 per rank | nivå 20 i ett yrke kostar 31 200 XP = 21 st rank 5-tillverkningar | klientkopia |

Expeditionsplatser = antal aktiva hjälpare (max 3) + 1 från Voxholm-gemmen = **upp till 4 platser**.

### Var det sticker ut

**Uppåt – korta expeditioner.** 5- och 15-minutersexpeditioner ger nära **en hel nivå per timme och plats** på alla nivåer, eftersom taket på 25 % per hämtning inte slår in på dem. Med tre hjälpare och gemmen blir det ungefär **4 nivåer i timmen** så länge man sitter och trycker, från nivå 1 till nivå 49. En aktiv spelare kan nå 50 på 12–15 timmar. Det är det som gör att "en vecka" inte håller i dag.

**Uppåt – de långa expeditionerna i passivt läge.** En 2-timmare ger 25 % av en nivå. Tre platser som bara kör 2-timmare dygnet runt ger **9 nivåer per dygn utan att man spelar.** 8-timmare ger 2,25 nivåer per dygn.

**Nedåt – idle.** Idle-XP är ett fast tal och följer inte kurvan: på nivå 1 i Voxholm är det 120 % av en nivå i timmen, på nivå 49 i Quarantine är det 5 %. Det är rätt riktning (idle ska inte bära 41–50), men hoppet är hårt.

**Nedåt – gammalt innehåll.** Fem nivåer under dig ger 10 %. Det är bra och ska stå kvar.

**"Dyrare 41–50" gör inte det den var tänkt att göra.** Eftersom expeditioner och strider betalar i procent av nivån tar nivå 45 lika lång tid som nivå 15 om man kör innehåll på sin nivå. De 20 % extra per nivå bromsar bara idle-XP och gammalt innehåll. Om tanken var att 41–50 ska ta längre tid måste det göras i källorna (nedan), inte i kurvan.

### Förslag: kurva för nivå 1–50 på ungefär en vecka

Målbild "vanligt spelande" = ungefär 2–3 timmar aktivt per dag plus expeditioner som går när man inte är där. "Mest aktiv" = 10–12 timmar per dag.

| Nivåer | Tid per nivå (vanligt) | Summa |
|---|---|---|
| 1–10 | ~5 min | ~1 h |
| 11–20 | ~15 min | ~2,5 h |
| 21–30 | ~30 min | ~5 h |
| 31–40 | ~50 min | ~8 h |
| 41–50 | ~80 min | ~13 h |
| **Totalt** | | **~30 timmar aktivt spel**, vilket är 7 dagar à 3–4 h eller 3 dagar à 10 h |

Tal att ändra för att landa där (alla i level_config / expedition_weight_config på servern, klienten läser dem därifrån):

1. **Expeditionstaket per hämtning: 25 % → 15 % av din nivå** (expedition_cap). Varför: det är taket som styr de passiva nivåerna. Effekt: tre platser med 2-timmare ger 5,4 nivåer per dygn i stället för 9; 8-timmare ger 1,35 per dygn.
2. **Vikten för 5 min: 2,7 → 1,4 och för 15 min: 8 → 4.** Varför: de korta ska vara "jag sitter här och spelar", inte en nivå i timmen per plats. Effekt: 5 min ger 4,4 % per hämtning (52 % per timme och plats), 15 min 12,4 % (50 % per timme). Med tre platser blir det ~1,5 nivå i timmen aktivt – alltså 2,5–3 timmar om dagen ger 4–5 nivåer plus 1–2 passivt = **~6 nivåer per dygn, 50 på 8 dagar**. Tolv timmar om dagen ger 18–20 nivåer per dygn = **50 på 2,5–3 dagar.**
3. **Vikterna 45 min: 24 → 16, 2 h: 54 → 40.** Varför: med nytt tak 15 % slår taket in redan på 45 min; sänks vikten blir skillnaden mellan längderna synlig igen (45 min ≈ 13 %, 2 h = 15 %).
4. **Rör inte 607 / 1,0845 / 1,20.** Kurvan gör som sagt ingen skillnad för innehåll på egen nivå. Att ändra den flyttar bara idle och gammalt innehåll, och det kostar ommätning av allt annat (paragon börjar på 32 000).
5. **Idle: behåll 0,18/s men överväg +15 % per region-ring i stället för +80 %** (1,8 per ring). Varför: i Quarantine ger idle 7 800 XP/h, vilket på nivå 41 är nästan en halv nivå i timmen av att bara ha fliken öppen. Lägre prioritet – idle ska vara trygg botten, inte motor.
6. **Strider: be servern visa vikten.** Om en vanlig vinst är 4,7 % av en nivå och man kan slåss var 30:e sekund på låg nivå är det 5–6 nivåer i timmen på nivå 1–10, vilket är okej där (nivå 1–10 ska gå fort) men inte om samma vikt gäller på 41–50 med 4 minuters vila. Förslaget är: **vanlig strid 3 % av en nivå, elit 9 %** om vikten i dag är 1.

**Om vi inte ändrar:** de mest aktiva är på 50 första kvällen, och de passiva når 50 på under en vecka utan att spela. Då finns inget kvar att göra vid release förutom paragon, och allt innehåll på väg upp hoppas över.

---

## 2. Säljvärden på hittad gear

### I dag (klientkopia)

Säljvärdet rullas när pjäsen faller: ett band per sällsynthet, gånger pjäsens nivå (1 + 0,1 per nivå över 1, delat med 5,9, så att nivå 50 = 1,0).

| Sällsynthet | Nivå 1 | Nivå 10 | Nivå 25 | Nivå 50 |
|---|---|---|---|---|
| Common | 1,5–2,4 g | 2,9–4,5 g | 5,2–8,1 g | 9–14 g |
| Uncommon | 2,5–4 g | 4,9–7,7 g | 8,8–14 g | 15–24 g |
| Rare | 5,8–8,3 g | 11–16 g | 20–28 g | 34–49 g |
| Epic | 10–14 g | 19–27 g | 35–48 g | 60–83 g |
| Legendary | 16–20 g | 30–37 g | 54–67 g | 94–116 g |
| Mythic | 23–28 g | 44–53 g | 78–95 g | 135–165 g |

Hjälparen Haggler lägger på upp till ca 10 % (1,5–2,0 % per nivå; säljvärdet är inte takat i klienten).

Att jämföra med vad en expeditionsplats ger i guld per timme: Voxholm 7 g, Drakemark 12 g, Cutlass Bay 19 g, Last Armada 28 g, Quarantine 40 g (2-timmare; 5-minutare ger ungefär hälften). Alltså: **en Mythic som faller på nivå 50 säljs för 4 timmars expeditionsguld, en Legendary för 2,5 timmar, och till och med en Common är en kvart.**

Gear faller ofta: varje vunnen strid ger 20 % chans (upp till 60 % med Loot Luck), och i Quarantine är fördelningen 15/22/26/23/10/4 % (Common → Mythic). **Snittvärdet på en pjäs från en strid i Quarantine är ~50 g, alltså ~10 g per vunnen strid utan tur och ~30 g med maxad tur.** Hinner man en strid i minuten är det 600–1 800 g i timmen från att sälja skräp, mot 40 g i timmen från en expeditionsplats. Det här är den största obalansen i pengaflödet.

Material och annat (klientkopia, för jämförelse): skrot 1 silver, vanligt material 3 silver, gem-material 8 silver, sällsynt 15 silver, förädlat 75 silver, kit 4 silver. Reinforced/Charged/Phase scrap 1,8/3,2/5,8 silver. Skräp (junk) 3 koppar. Flaskor 15 silver–1,2 g. Ritningar 1–32 g. Gems 15 g. Charms 5–50 g. Dessa är i rimlig skala; det är pjäserna som sticker ut.

### Förslag: sänk pjäsernas säljvärde med ~75 % före release

Nytt band på nivå 50 (nivåskalan som i dag):

| Sällsynthet | I dag (nivå 50) | Förslag (nivå 50) | På nivå 1 blir det |
|---|---|---|---|
| Common | 9–14 g | **2–3 g** | 35–50 silver |
| Uncommon | 15–24 g | **4–6 g** | 70 silver–1 g |
| Rare | 34–49 g | **8–12 g** | 1,4–2 g |
| Epic | 60–83 g | **15–20 g** | 2,5–3,4 g |
| Legendary | 94–116 g | **25–30 g** | 4,2–5 g |
| Mythic | 135–165 g | **35–45 g** | 6–7,6 g |

Varför: då blir snittpjäsen från en strid i Quarantine ~12 g och en vunnen strid 2–7 g, vilket ligger i samma härad som en expeditionsplats (40 g/h). En Mythic blir fortfarande "en timmes expedition" – värd att plocka upp, inte värd att farma.

Två saker måste följa med:
- **Handlarens prisgolv** (lägsta säljvärde + 1 guld, plus påslaget 8/12/20/32/40/55 g) räknas i dag från samma band. Sänks säljbandet kan påslaget också sänkas, annars blir handlarens pjäser orimligt dyra jämfört med vad de är värda att sälja. Förslag: påslag 4/6/10/16/20/28 g.
- **Auktionshuset** påverkas inte (spelare sätter priset själva, 8 % skatt, golv 5 %), så handel mellan spelare blir relativt sett viktigare. Det är bra.

**Om vi inte ändrar:** strider blir den dominerande guldkällan med en faktor 10–40 över allt annat, expeditionsguldet blir meningslöst, och Gold Find-egenskapen (som bara gäller expeditioner, quests och strider, inte försäljning) blir sämre än att bara sälja mer.

---

## 3. Droppchanser och Loot Luck

### Var tur kommer ifrån (klientkopia)

- **Gear:** Loot Luck-egenskapen rullar 1,64–2,16 % gånger sällsynthetens faktor (Common 1 … Mythic 4,2). En Mythic-egenskap ger alltså upp till 9,1 %, och en Mythic-pjäs kan ha tre. Egenskapen kan hamna på 13 av 14 platser (allt utom väska; ring/halsband får den som andra eller tredje egenskap). Realistiskt fullt Mythic-set med en luck-rad på varje pjäs ≈ **115 %**; teoretiskt max flera hundra procent.
- **Mod Chips:** 0,5/1/1,5/2 % per chip, **tak 20 %** från chip.
- **Fortune-flaska:** 20/30/45/70 % i 15–60 minuter.
- **Skilltrad:** Loot Luck-noder (talen laddas från servern).
- **Hjälpare:** Cache Instinct och Rarer Gear läggs **ovanpå** turen (Chris v5.1114).

Alltså kan en seriös spelare på nivå 50 ligga på **150–250 % Loot Luck med flaska**, och det finns inget tak på summan.

### Vad turen gör (klientkopia)

| Var | Hur turen räknas | Tak |
|---|---|---|
| Gear från strid | 20 % × (1 + halva turen + Gear Drops) | 60 % per vinst |
| Gear från expedition | grundchans (0,62 % per minut, dämpat över 45 min) × (1 + halva turen + Gear Drops) | inget tak – över 100 % = en säker pjäs plus chans på en till |
| Sällsynthet på gear (strid/expedition) | servern flyttar vikt från Common/Uncommon till de fyra översta | bara servern vet |
| Gear Cache / Helper Cache | hela turen flyttar vikt från Common+Uncommon till resten; **över 100 % multipliceras Legendary och Mythic med hela turen** | **inget tak** (kommentaren om 70 % är gammal; koden från 2026-10-23 tar bort taket) |
| Recept på expedition | grundchans × (1 + turen) | 30 % |

Cachens grundodds (koppar/sällsynthet 0–5, per nivåband):

| Band | Common | Uncommon | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|---|
| 1–10 | 60,5 % | 25 % | 10 % | 4 % | 0,45 % | 0,05 % |
| 21–30 | 44,8 % | 28,5 % | 16,5 % | 8,5 % | 1,35 % | 0,4 % |
| 41–50 | 25,5 % | 24 % | 25 % | 20 % | 4 % | 1,5 % |

Så här blir en cache på nivå 41–50 med tur:

| Loot Luck | Common | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|
| 0 % | 25,5 % | 25 % | 20 % | 4 % | 1,5 % |
| 70 % | 7,7 % | 42 % | 34 % | 6,7 % | 2,5 % |
| 100 % | **0 %** | 49,5 % | 39,6 % | 7,9 % | 3,0 % |
| 150 % | 0 % | 47 % | 37,6 % | 11,3 % | 4,2 % |
| 200 % | 0 % | 44,6 % | 35,7 % | 14,3 % | **5,4 %** |

En cache kostar 25 fragments (ner till 4 med Cache Broker). En expeditionsplats ger ~12 fragments i timmen med 5-minutare, och Fragment Find lägger på. **Med 200 % tur och tre platser är en Mythic ur caches var ~15:e cache, alltså ungefär var tionde speltimme, plus vad strider och expeditioner ger.** Hovringstexten i spelet (luckOdds) visar dessutom en snällare formel (halva flytten, en fjärdedel över 100 %) än den som faktiskt öppnar cachen (cacheWeights) – spelaren ser lägre odds än hen får. Det bör vara samma formel på båda ställen, och servern avgör vilken som gäller.

### Förslag på tak

1. **Totaltak på Loot Luck 100 %** räknat på allt (gear + chip + skill + flaska), och **ingen extra multiplikation över 100 %** i caches. Hjälparnas Cache Instinct / Rarer Gear får ligga ovanpå som i dag, med **totaltak 150 %**. Varför: vid 100 % ger cachen aldrig Common/Uncommon – det är redan "toppen". Allt därutöver är i dag en rak multiplikator på Legendary/Mythic utan slut.
2. **Gear-chans per strid: tak 60 % är bra, behåll.** Men sänk grundchansen 20 % → 15 % om säljvärdena i punkt 2 **inte** sänks. Sänks säljvärdena kan 20 % stå kvar.
3. **Expeditionens gearchans: sätt tak på 150 % (en säker + 50 % chans på en till).** I dag kan en 8-timmare med tur ge 2–3 pjäser; det är den enda platsen utan tak.
4. **Visa samma odds som servern använder.** Rätta hovringstexten så den räknar som cachen, och skriv ut taket.
5. **Vial-styrkan 70 % är hög** när allt annat ger 1–9 % per rad. Förslag 15/25/35/50 %. Varför: en flaska ska vara en knuff, inte lika mycket som sju Mythic-rader.

**Om vi inte ändrar:** Loot Luck blir den enda egenskap som räknas, alla craftar och jagar luck på alla 13 platser (se punkt 4), och Mythic-flödet på nivå 50 blir flera per dag per spelare. Med säljvärdena i punkt 2 är det dessutom en pengamaskin.

---

## 4. Vilka egenskaper kan tillverkas i vilka former

### I dag (klientkopia, 320 pappersrecept)

| Yrke | Form | Egenskaper som kan garanteras | Ranker |
|---|---|---|---|
| Outfitter | Huvud, bröst, ben, händer, fötter, midja (6 former) | Gold Find, Loot Luck, Player XP, Expedition Speed, Fragment Find, Dungeon Speed – **alla sex på alla sex former** | 1–5 |
| Weaponsmith | Enhandsvapen, tvåhandsvapen, offhand (3 former) | **samma sex på alla tre** | 1–5 |
| Jewelcrafter | Ring, halsband | Crit Chance, Crit Damage | 1–5 |
| Jewelcrafter | Relic | **samma sex som ovan** | 1–5 |

Alltså: **Gold Find, Loot Luck, Player XP, Expedition Speed, Fragment Find och Dungeon Speed kan tillverkas garanterat i tio av tretton former.** Bara Crit Chance och Crit Damage är begränsade (ring/halsband). Den garanterade egenskapen hamnar först, och rank 3–5 får dessutom 1–2 slumpade egenskaper ur hela poolen.

Konsekvensen är att en crafter kan bygga tio pjäser med Loot Luck som garanterad rad plus tre jewels och sedan hoppas på luck som slump på resten. Det finns inget val att göra – alla former är lika, bara bilden skiljer. Det är också därför det blev 308 ritningar: 6 egenskaper × 10 former × 5 ranker.

### Förslag: två egenskaper per form (tre på relic)

| Form | Egenskaper som får garanteras |
|---|---|
| Huvud | Player XP, Loot Luck |
| Bröst | Loot Luck, Fragment Find |
| Ben | Expedition Speed, Gold Find |
| Händer | Fragment Find, Gold Find |
| Fötter | Expedition Speed, Dungeon Speed |
| Midja | Gold Find, Player XP |
| Enhandsvapen | Dungeon Speed, Player XP |
| Tvåhandsvapen | Dungeon Speed, Loot Luck |
| Offhand | Fragment Find, Expedition Speed |
| Ring | Crit Chance, Crit Damage (som i dag) |
| Halsband | Crit Chance, Crit Damage (som i dag) |
| Relic | Loot Luck, Gold Find, Player XP |

Då finns varje egenskap i 3–4 former (Loot Luck: huvud, bröst, tvåhand, relic = max ~36 % garanterad luck från craft på Mythic, i stället för ~90 %). Antalet pappersrecept går från 320 till **~125** (25 former-egenskaper × 5 ranker), och varje ritning blir mer värd att hitta.

Varför just så: egenskaperna är spridda så att ingen "bästa" kombination fyller alla platser, rustningsyrket och vapenyrket får varsin profil (Outfitter = ekonomi/expedition, Weaponsmith = dungeon), och relic får vara jokern.

De slumpade egenskaperna på rank 3–5 kan fortsätta dra ur hela poolen – det är lotteriet, inte garantin.

**Om vi inte ändrar:** ritningarna är utbytbara, crafting blir ett sätt att stapla en enda egenskap, och punkt 3:s tur-problem förvärras. Dessutom måste 308 bilder (en per recept och variant) underhållas.

---

## 5. Kryphål jag ser

1. **Sälj-loopen från strider** (punkt 2): 20–60 % gear per vinst × 50 g snittvärde i Quarantine. Störst, och enkel att stänga med nya säljband.
2. **Rank 5-ritningar ger garanterat Legendary.** Papprets sällsynthet är ett golv, så rank 5 (Legendary-papper) ger 99 % Legendary / 1 % Mythic vid yrkesnivå 20. Materialet kostar i säljvärde ~3 g (15 Phase Scrap, 7 Phaseweave, 1 förädlat, 6 Memory Weave, 30 Static Fiber), pjäsen säljs för 94–116 g på nivå 50. **Varje tillverkning är +90 g netto hos handlaren** och 9 fragments om man återvinner i stället. Tillverkningstiden är enda bromsen. Stängs av punkt 2 (säljband) – med förslaget blir det +22 g per craft, vilket är rimligt för en Legendary.
3. **Korta expeditioner som XP-motor** (punkt 1): en nivå i timmen per plats på alla nivåer.
4. **Loot Luck utan tak i caches** (punkt 3), och olika formel i hovringen och i cachen.
5. **Handlarens veckogåva.** Från fyra stjärnor får man en Epic/Legendary i veckan per region, vid fem stjärnor en Mythic. Rykte är 1 per minut bara av att stå i regionen (5 stjärnor = 10 080 rep = 7 dygn), och strider/expeditioner ger mer. Fem regioner = **upp till fem Mythic i veckan utan att göra något**, värda 135–165 g styck i dag. Förslag: gåvan bara i regionen för din nivåband, eller en gåva per konto och vecka, och alltid bunden (går inte att sälja hos handlaren).
6. **Credits-taket står kvar i klienttexten.** Handlarens byte till credits visar fortfarande "today's credit limit – 50 per dygn" om servern svarar credit_cap. Beslutet 2026-11-03 är inget dygnstak – servern måste kollas så att credit_cap faktiskt är borttagen, annars säger spelet ett och Chris ett annat. Hur mycket credits som kommer från strider (elit), expeditioner, dungeons och quests vet bara servern.
7. **Junk i Quarantine = 1 credit styck.** Var fjärde expedition ger 1–3 skräp; med tre platser på 5-minutare är det ~25 skräp i timmen = 25 credits. Mission Board kostar 25 credits. Utan dygnstak blir skräpet den stabila credits-källan. Inte nödvändigtvis fel, men bör vara ett medvetet beslut.
8. **Legendary Cache-biljetter till alts** öppnas bara på nivå 50 (bra), men Rare Cache öppnas på 25 och ger "alltid Rare eller Epic rullat för öppnarens nivå och tur" – en huvudkaraktär med 200 % tur kan skicka dem till en alt som öppnar med sin egen tur, så där är det alt-ens tur som gäller. Ingen läcka så länge turen räknas vid öppning; bör bekräftas på servern.
9. **Expeditionens gearchans över 100 %** på 4- och 8-timmare (104 % och 149 % utan tur). Med tur 2–3 pjäser per hämtning. Se punkt 3.
10. **Idle i Quarantine utan att slåss.** 7 800 XP i timmen för en öppen flik på nivå 41–42 (nästan en halv nivå i timmen). Lägre prioritet.

---

## Beslut för Chris

Svara ja eller nej. Allt är tal på servern (level_config, expedition_weight_config, rarity_config, affix/recipe-tabellerna); klienten läser dem och behöver bara följa med där den har en reservkopia.

**XP**
1. Expeditionstaket per hämtning 25 % → 15 % av din nivå? **Ja / Nej**
2. Vikt 5 min 2,7 → 1,4 och 15 min 8 → 4? **Ja / Nej**
3. Vikt 45 min 24 → 16 och 2 h 54 → 40? **Ja / Nej**
4. Låta nivåkurvan (607 / 1,0845 / 1,20) stå? **Ja / Nej**
5. Idle: 1,8 per ring → 1,15 per ring? **Ja / Nej**
6. Strid: vanlig 3 % av en nivå, elit 9 % (om servern i dag ger 4,7 / 14)? **Ja / Nej**

**Säljvärden**
7. Nytt säljband på nivå 50: 2–3 / 4–6 / 8–12 / 15–20 / 25–30 / 35–45 g (Common → Mythic), nivåskalan som i dag? **Ja / Nej**
8. Handlarens påslag 8/12/20/32/40/55 → 4/6/10/16/20/28 g? **Ja / Nej**

**Loot Luck**
9. Totaltak 100 % på Loot Luck, ingen multiplikation över 100 % i caches, hjälpare ovanpå upp till 150 %? **Ja / Nej**
10. Expeditionens gearchans takas vid 150 %? **Ja / Nej**
11. Fortune-flaskan 20/30/45/70 → 15/25/35/50 %? **Ja / Nej**
12. Samma odds-formel i hovringen som i cachen? **Ja / Nej**

**Crafting**
13. Två garanterade egenskaper per form enligt tabellen i punkt 4 (tre på relic), ~125 ritningar i stället för 320? **Ja / Nej**
14. Om ja på 13: ska befintliga ritningar/recept som inte längre finns bytas mot en ritning av samma rank i spelarens väska? **Ja / Nej**

**Kryphål**
15. Handlarens veckogåva: en per konto och vecka, och bunden (ej säljbar)? **Ja / Nej**
16. Ska junk i Quarantine fortsätta ge 1 credit styck utan tak? **Ja / Nej**
17. Ska jag få en export av serverns pve_fight, pve_dungeon_claim, quest_config och credit_cap så att punkt 1 och 6 kan räknas färdigt? **Ja / Nej**

**Dokument**
18. Lägga in `docs/BALANS-*.md` och `docs/STATUS.md` i repot så att framtida genomgångar i molnet kan läsa dem? **Ja / Nej**
