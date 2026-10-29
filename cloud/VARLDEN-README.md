# Världen i 3D – inbyggd i spelet (v5.1353.0 — VARLDEN)

Gren: `genesis-world-live`. Inget är live. Main är orörd.

## Vad som byggts

**3D-kartan är nu en vy i spelet.** Uppe till vänster på kartan sitter en växel **2D | 3D**. 2D är kartan precis som i dag (`genesis-map.html`), 3D är den nya filen `genesis-3d.html` som laddas i samma ram. Valet sparas i webbläsaren (`genesis.map3d`), så den som valt 3D får 3D nästa gång också. Saknar webbläsaren WebGL hoppar spelet självt tillbaka till 2D och säger varför.

Chris nio krav, alla med:

1. **Realtid.** Din figurs plats skickas några gånger i sekunden (4 gånger/s när du går, annars varannan sekund) via Supabase Realtime – en öppen "broadcast"-kanal per region (`varld-drakemark` osv.). Andra i samma region får den och ser dig gå; du ser dem. Ingenting sparas i någon tabell. Kanalen byts automatiskt när du reser till en annan region. Spelare i andra regioner syns som förut via `world_view()` (var 20:e sekund), men de går då bara "för syns skull" som i demon.
2. **Pratbubbla.** Det du skriver i **Zone**-kanalen visas som en vit bubbla över din figur i några sekunder, och över andras figurer när de skriver. Bubblan går två vägar: direkt på realtidskanalen (omedelbart) och via zonchattens vanliga hämtning (så den kommer även om kanalen just då låg nere). Samma rad räknas bara en gång. Gamla rader (äldre än 20 s) bubblar aldrig – annars hade historiken poppat upp vid inloggning. Zonchatten hämtas nu också när en annan chattflik är framme, men bara medan 3D visas.
3. **Quest-ikoner som i WoW.** Gult **!** = uppdrag att hämta (grått när uppdragsloggen är full). **?** = aktivt uppdrag i sin zon: gult när det är klart att lämna in, grått medan det pågår. Allt kommer från samma uppdragsdata som Quests-rutan.
4. **Riktiga funktioner.** Varje tryck går genom spelets egen `gmPick` precis som 2D-kartan: möte → Encounter-rutan, uppdrag → Quest-rutan (aktivt uppdrag → uppdragsrutan med framsteg/Claim rewards), handlare → Vendor, valv → Vault, expedition → Expeditions, dungeonporten → svårighetsvalet, dödskallen → World Boss, annan region → regionrutan. Inga simulerade klick.
5. **2D|3D-växel** kvar, valet sparas. 3D tar inte bort något: 2D-kartan och allt den gör är orört.
6. **Hjälpare.** Din aktiva hjälpare (första i laget) går bredvid din figur. Finns `assets/helpers3d/<art>.glb` och arten står i `assets/helpers3d/index.json` visas modellen, annars ett litet lysande klot med namnet. Andras hjälpare följer med i realtidspaketet, så de syns också. Format nedan.
7. **Nod = jobba direkt.** Malmådrorna (veins) ligger på zonens malmstenar. Ett tryck startar spelets vanliga mätare direkt, precis där du tryckte – ingen mellanknapp. (Demons påhittade "Ore node"/"Fiber patch" är borttagna; spelets riktiga noder är veins.)
8. **Spelets egna rutor.** Demons alla egna rutor och hela DEMO-spelet är bortplockade ur filen. Kvar i kartan finns bara det som hör till kartan: resknappen, spelarkortet för spelare i *andra* regioner (de har ingen spelruta), Live feed och Find player. Trycker du på en spelare i din egen zon öppnas spelets vanliga spelarmeny (Inspect, Whisper, Trade …).
9. **Direkt + gå.** Rutan öppnas i samma ögonblick som du trycker, och figuren börjar gå dit samtidigt. Framme gör den en gest (hugg vid möte, plocka vid åder, prata vid uppdrag).

Kvar från demon och nu kopplat till riktig data: regioner som öar, dag/natt (klockan), väder per zon, World Boss (från `world_view`), Find player, nyhetsflödet, båtar, fåglar, draken över Drakemark.

three.js ligger nu **lokalt** i `lib/three-0.170.0/` (MIT, licensfil med) – ingen CDN, sajten fungerar utan tredje part. KayKit-figurerna är samma som i demon (`assets/world3d/`, CC0).

## Vad som kräver serverändring

**Ingenting – kartan fungerar utan serverändring.** Realtidskanalerna är öppna broadcast-kanaler (ingen tabell, ingen policy behövs), `world_view()` finns redan.

`cloud/varld-server.sql` innehåller bara något **valfritt**: två policyer om Chris hellre vill ha kanalerna *privata* (bara inloggade får lyssna/sända). Då byts `private: false` mot `private: true` på ett ställe i index.html (`wrldSockOpen`). Utan det har kanalerna samma skyddsnivå som `world_view()` redan har: bara spelnamn och var på kartan man står.

I SQL-filen står också antecknat (inte infört) hur `world_view()` kan skicka med hjälparen per spelare, om hjälpare ska synas även hos spelare i *andra* regioner.

## Vad som saknas / att veta

- **Hjälparnas 3D-modeller** finns inte än – alla visas som platshållare (lysande klot + namn). Format: en fil `assets/helpers3d/<art>.glb` per art, där `<art>` är samma nyckel som bildfilen i `assets/pets/` (t.ex. `bit`, `aeris`). Modellen ska stå med fötterna på y = 0, vara vänd mot +Z, ungefär 1 enhet hög (kartan skalar om till 0,9 enheter = lite lägre än spelarfigurens knän). Har filen en animation som heter något med "idle" spelas den i loop. Lägg arten i listan i `assets/helpers3d/index.json` (`"models": ["bit", "aeris"]`) – bara det som står där hämtas, så inga 404-fel loggas för resten.
- **Ljudlöst.** Inget ljud i 3D-vyn.
- **Zonchattens pratbubblor** kommer snabbast via realtidskanalen (omedelbart). Reservvägen via chattens hämtning följer chattens vanliga takt (direkt när "dörrklockan" ringer, annars var 30:e sekund).
- **Testkonton.** `world_view()` filtrerar bort dolda profiler; realtidskanalen gör det inte – en dold testspelare som står i samma region syns gå på kartan. Vill man dölja även där: skicka inte position när profilen är dold (en rad i `wrldMyPos`), eller gör kanalen privat.
- **Mätningen kördes utan server.** Spelet lyftes förbi inloggningen med ett påhittat läge (mätverktyget `.claude/tools/measure-varld.js`), så realtid mot riktig Supabase och de riktiga RPC-anropen (`vein_start`, `world_view`) är **inte** provkörda i molnet – det görs vid Chris provkörning. Allt annat (växel, laddning, klick → spelets rutor, gång, !/?, bubblor, hjälpare, sex bredder, inga JS-fel, inget vågrätt spill) är uppmätt.
- Publiceringen (`.github/scripts/strip.mjs`) tar bort kommentarer ur `index.html`, `admin.html` och `genesis-map.html`. `genesis-3d.html` står inte i den listan – dess kommentarer följer med ut. Vill man strippa den också läggs namnet till i `FILES`, men dess skript är en ES-modul så det bör provköras först.

## Hur Chris testar

1. Checka ut grenen `genesis-world-live` och öppna spelet som vanligt (lokalt via en webbadress, inte via en mapp).
2. Logga in. Kartan är 2D som förut. Tryck **3D** uppe till vänster på kartan. Första gången tar det några sekunder (figurerna laddas). Ladda om sidan – 3D ska vara kvar.
3. Tryck på marken: figuren går dit. WASD/pilar fungerar när kartan har fokus. På telefon: **Open map** → helskärm, joystick nere till vänster.
4. Tryck på ett **!**: Quest-rutan öppnas direkt och figuren går mot uppdragsgivaren. Tryck på ett möte (röda ringen): Encounter-rutan med fiendebild och "Travel and begin / Give up / Leave". Tryck på handlaren/valvet/dungeonporten/expeditionsskylten: respektive ruta.
5. Tryck på en malmsten med glödande kristaller (en åder): mätaren startar direkt där du tryckte.
6. Logga in med en andra karaktär i en annan webbläsare, res till samma region: ni ser varandra gå. Skriv i **Zone**: pratbubbla hos båda.
7. Tryck **2D**: gamla kartan tillbaka, allt som förut.
8. Valfritt: kör `cloud/varld-server.sql` om kanalerna ska vara privata (se ovan), och byt `private: false` → `true` i `wrldSockOpen`.

Skärmbilder från mätningen: `docs-world/live-*.jpg` (region, realtid, pratbubbla, quest-ikoner, Encounter öppnad från kartan, åder) på 1920, 1440, 1280, 820, 390 och 360 px.

## Patchnotes

Posten för 5.1353.0 ligger överst i `patchnotes.json` med `discord: "hold"` – inte postad.
