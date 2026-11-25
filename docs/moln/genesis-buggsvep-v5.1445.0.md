# Genesis – buggsvep v5.1445.0 (molnet, 2026-11-03)

Granskad fil: `index.html` på grenen (HEAD = v5.1446.0, dvs v5.1445.0 plus nya posten). Ren läsning, ingenting ändrat i spelet.
Fokus: allt som byggts sedan v5.1312 – uppdragstavlan, delade valvet, lådbiljetter med nivåkrav, lådlistan, sökrutan i väskan, World Boss-rutan, Reroll Gem, auktionens myntrutor, Reset tree, brevet, dra-och-släpp och telefonreglerna.

Varje fynd är kontrollerat mot koden. **CONFIRMED** = hela vägen är spårad i klienten. **PLAUSIBLE** = felet kräver något jag inte kan se härifrån (serverns svar, exakt tajming).

Allvarlighetsgrad: **Hög** = spelaren kan förlora något eller fastna. **Medel** = fel som syns och förvirrar men rättar sig. **Låg** = skönhetsfel eller sällsynt.

Inga Hög-fynd denna gång. Det som byggts sedan v5.1312 är överlag stabilt: all text från servern går genom esc(), nästan alla knappar har spärr mot dubbeltryck, hover-effekterna är avstängda på pekskärm och de nya rutorna använder dvh i stället för 100vh.

---

## Del 1 – Sammanfattning för Chris (vad spelaren märker)

### Medel – värt att laga snart

1. **Uppdragstavlan kan visa gammalt läge direkt efter Pay eller Hand in.** Tavlan hämtar framsteget från servern var 30:e sekund i bakgrunden. Trycker man Pay/Hand in precis när en sådan hämtning pågår kan det gamla svaret komma in sist och skriva över det nya. Kortet står då kvar som "Available"/"Ready" med gamla krediter, och trycker man igen får man "already bought/finished". Rättar sig själv inom 30 sekunder.

2. **Reroll Gem kan skickas två gånger med dubbeltryck.** Knappen Reroll (och de tre valknapparna efteråt) stängs inte av medan servern jobbar. Två snabba tryck ger två anrop och, om servern godkänner båda, två förbrukade stenar och dubbel avgift. God roll-varningen i sig är rätt och säker.

3. **Auktionens styckpris: skriver man mer än 99 i silver- eller kopparrutan används 99 utan att det syns.** Skriver man 150 silver står 150 kvar i rutan, men priset blir 99 silver och varan läggs ut så. Texten i koden säger att 150 silver ska bli 1 guld 50 silver, men det görs inte.

4. **Lådlistan: Sell all och Recycle all kan startas två gånger.** Knapparna är aktiva medan försäljningen pågår. Ett andra tryck (eller tryck på den andra knappen) kör en ny runda mot en väska som inte hunnit uppdateras, servern säger nej, och man får ett "stopped"-besked fast allt redan sålts.

5. **Delade valvet: en pjäs kan synas på två ställen en stund.** När valvet öppnas med Shared-fliken på startas en hämtning av det delade valvet. Flyttar man en pjäs därifrån direkt gör flytten en egen hämtning. Det svar som kommer sist vinner, och är det det gamla syns pjäsen både i Shared och i väskan tills nästa uppdatering.

6. **Sökrutan i väskan: lösa väskfönster tappar markeringen.** Söker man och sedan får loot, flyttar eller säljer något, dimmas huvudväskan fortfarande rätt, men de utbrutna väskfönstren visar alla rutor odimmade tills man skriver i sökrutan igen.

### Låg – skönhetsfel och sällsynta fall

7. **Auktionen, BUY:** dubbeltryck ger två frågerutor ovanpå varandra; svarar man ja på båda går ett andra köp till servern och man får ett felmeddelande.
8. **Auktionen, efter köp:** om uppdateringen av väska/post misslyckas efter ett lyckat köp sägs det som om köpet misslyckats, och knappen tänds igen.
9. **Auktionen, frågerutan vid köp:** varans namn sätts in i rutan utan escapning. Namnen kommer från servern. Ofarligt så länge servern bara skickar riktiga föremålsnamn, men det är det enda ställe i det nya som bryter mot regeln "serverns text skrivs aldrig rakt in".
10. **Brevet på iPhone:** myntrutorna (Gold/Silver/Copper) har 14 px text, så Safari zoomar in sidan när man trycker i dem. Auktionshuset fick exakt den här fixen tidigare (16 px), brevet fick den inte.
11. **Brevet, Attach items:** stänger man brevfönstret mitt i "Attach items"-läget ligger läget kvar: väskan har kvar de blå ringarna och knappen säger "Done attaching" när man öppnar brevet igen. Esc rättar det.
12. **Brevet, dra-och-släpp:** den streckade rutan i brevet lyser aldrig upp när man drar en pjäs över den, fast släppet fungerar.
13. **Delade valvet, dra-och-släpp:** rutorna i Shared lyser aldrig upp när man drar över dem, och ett drag som börjar i Shared lyser inte upp något mål alls. Släppet fungerar ändå.
14. **Delade valvet:** efter en flytt kan spalten visa "Could not load the Shared tab" fast det delade valvet laddades fint; det var väskans hämtning som föll.
15. **Delade valvet:** ett andra släpp eller "To backpack" medan en flytt pågår gör ingenting, utan besked.
16. **Delade valvet:** släpper man en valvpjäs på fliken Shared när spalten är stängd flyttas pjäsen in i en spalt man inte ser.
17. **Delade valvet:** släpper man en buren pjäs (från kroppen) på Shared-rutnätet händer ingenting, utan besked.
18. **Reset tree:** under tiden servern jobbar står knappen redan som "Reset tree · X gold" och kan tryckas igen; två tryck ger ett andra anrop. Dessutom visas "10 gold" tills priset hämtats, om trädet ritas före svaret.
19. **Uppdragstavlan:** om uppdateringen av väska/profil misslyckas efter ett lyckat Hand in får spelaren ett felmeddelande i stället för "Mission complete!", fast uppdraget är inlämnat.
20. **Uppdragstavlan:** ett uppdrag utan region i serverns svar skulle ritas utan Hand in-knapp när belöningen är Gear Focus (kan inte verifieras utan servern).
21. **Uppdragstavlan:** om en bakgrundshämtning misslyckas visas inget; tavlan står kvar med gammalt innehåll.
22. **Uppdragstavlan:** sekundklockan för tavlan stoppas aldrig när tavlan stängs. Ofarligt.
23. **Auktionen:** ett guldbelopp över ca 2,1 miljarder i rutan blir pris 0 ("Enter a price of at least 1 copper").
24. **Brevet:** har en bifogad pjäs hunnit lämna väskan (sålts, lagts i valvet) säger servern nej, men ingen chip pekas ut, så spelaren måste gissa vilken som ska bort.
25. **Brevet:** rester från den gamla brevrutan ligger kvar i koden (letar efter rutor som inte finns). Gör ingenting, bara skräp.

### Kontrollerat och i sin ordning

- Alla namn, rubriker, brevtexter, uppdragsnamn, regionnamn, affixnamn och felmeddelanden från servern går genom esc() (utom punkt 9).
- Lådbiljetter: nivåkravet 25/50 (Rare/Legendary) är samma på alla sju ställen; Open one/Open all kan inte dubbelköras eftersom kastet avbryter ett pågående; Open all stannar vid första felet och visar det som öppnats.
- Lådlistan: hovra-för-kort är avstängt på pekskärm (tryck visar kortet), listan rullar, knapparna är 44 px på telefon, summorna räknas rätt.
- Brevet: Send kan inte dubbeltryckas, namnförslag ignorerar gamla svar, bilagor stoppar dubbletter och för stora högar, krediter stoppas.
- World Boss-rutan: wbFit nollställer alla klasser och mått före varje mätning, hanterar sidans egen zoom rätt, rutan använder dvh. Enda skönhetsfelet: rutan växer inte tillbaka när statusrader försvinner förrän nästa resize.
- Reroll Gem: god roll-varningen ligger ovanpå allt annat så materialet kan inte bytas medan frågan är öppen; hover-regler bara på mus.
- Reset tree: stigande priset tas från servern när det finns.
- Telefonreglerna: de sista @media-blocken (rad 13401, 13421, 13425) är verkligen sist, inga datorregler kommer efter. Uppdragstavlans hover ligger bakom (hover:hover) med klick som alternativ; valvet staplar spalterna; inga nya 100vh.
- Delade valvet: busy-flaggan nollas alltid; sidan vet vilken karaktär listan hör till; guld kan inte läggas där (avsiktligt).

---

## Del 2 – Teknisk lista (radnummer i index.html på HEAD)

| # | Rad | Område | Grad | Status | Fel | Föreslagen fix |
|---|-----|--------|------|--------|-----|----------------|
| 1 | 58085, 58102, 58240–58263 | Uppdragstavlan | Medel | CONFIRMED | `mbTick` startar `mbPull()` när `!MB.busy`; `mbAct` sätter sedan `MB.st = r` och väntar på `netPull`/`netPullItems`. Landar tickens `mission_state`-svar efter det skriver `MB.st = await srvRpc(...)` (58085) över resultatet utan sekvenskontroll; `redrawAll()` ritar det gamla. | Sekvensnummer: `const n = ++MB.seq` i `mbPull`, släng svaret om `n !== MB.seq` eller om `MB.busy` hunnit bli sant. |
| 2 | 24981–25003, 25004–25038, 25039–25047 | Reroll Gem | Medel | CONFIRMED | `gemrrGo`/`gemrrPick` saknar busy-flagga; knapparna `[data-gemrr-go]`/`[data-gemrr-pick]` är aktiva under `askConfirm` och under `reroll_gem`/`reroll_gem_pick`. Dubbeltryck = två staplade frågerutor och två anrop. | `GEMRR.busy`-vakt först i båda, `disabled` på knapparna i `renderGemReroll`, nollställ i `finally`. |
| 3 | 54389–54392, 53844–53846 | Auktionens styckpris | Medel | CONFIRMED | `las()` gör `Math.min(99, n('ah-ps'))` och `Math.min(99, n('ah-pc'))` men skriver aldrig tillbaka till fälten eller för över till guld. Kommentaren på 54387 lovar att 150 silver blir 1g 50s. | Räkna om: `g += Math.floor(s/100); s %= 100` (samma för koppar) och skriv de normaliserade värdena till de tre inputs vid `blur`/`change`. |
| 4 | 56257–56285 | Lådlistan Sell all / Recycle all | Medel | CONFIRMED | `korAlla` har ingen busy-flagga; `.cm-sell`/`.cm-rec` är aktiva under RPC-loopen. Andra körningen använder `kvar()` mot ett `S.inv` som inte hunnit uppdateras; `fore`-baslinjen delas. | Lokal `busy`-flagga; `disabled` på `.cm-btns button` tills loop + `netPullItems` är klara. |
| 5 | 28826–28828, 28842–28850, 28956 | Delade valvet | Medel | PLAUSIBLE | `openVault` → `sharedRefresh()`; `sharedMove` → egen `sharedLoad()`. Båda går via `sharedApply` utan sekvenskontroll; sist svarande vinner. Samma vid flikbytet 28956. | `SHV.seq++` per anrop, skicka in i `sharedLoad`, ignorera svar med lägre seq. |
| 6 | 33070–33071 | Sökrutan i väskan | Medel | CONFIRMED | `renderInventory()` kör `invSearchApply()` och **därefter** `renderMiniBags()`, som bygger om alla `.bagwin:not(.vaultbagwin)` med ny `invCellHTML` utan dimning. | Flytta `if (INV_Q) invSearchApply();` till efter `renderMiniBags()` (eller sist i `renderMiniBags`). |
| 7 | 54153–54171 | Auktionen BUY | Låg | CONFIRMED | `AH.busy` sätts först i `ahBuy`, efter `askConfirm`. Varje klick skapar en ny `.ask-back` (23541–23560). | Flagga/`btn.disabled = true` före `askConfirm` i `ahBuyAsk`, nollställ vid avbrott. |
| 8 | 54176–54191 | Auktionen efter köp | Låg | CONFIRMED | `netPull`/`netPullItems`/`netPullMailbox`/`netAhCounts` ligger i samma `try` som `netAhBuy`; ett fel där visar `ahErrText(e)` som om köpet föll och tänder knappen. | Egen `try/catch` runt uppdateringarna med neutralt besked ("Bought, but the refresh failed"). |
| 9 | 54154, 54162 (data-namn 54042, askConfirm 23545–23549) | Auktionen frågeruta | Låg | CONFIRMED | `data-namn` skrivs escapat men `el.dataset.namn` ger den avkodade strängen; `ahBuyAsk` sätter `namn` rakt in i `body` som `askConfirm` lägger i `innerHTML`. `ahRowName` faller tillbaka på `row.name` från servern. | `esc(namn)` i `ahBuyAsk`. |
| 10 | 10746, 13197 (viewport rad 17) | Brevet på iPhone | Låg | CONFIRMED | `.ms-money .ah-pu input{font-size:14px}`; telefonblocket sätter bara bredd 70px. `user-scalable=yes` → Safari zoomar. Auktionen har `16px !important` på 12630–12634. | `#ms-g,#ms-s,#ms-c{font-size:16px !important}` i ett telefonblock. |
| 11 | 48362–48371, 48386 (msPickOn 29419) | Brevet Attach items | Låg | CONFIRMED | `nav-inbox`, `qa-inbox` och `mail-close` tar bara bort `open`; ingen kallar `msPickOff()`. `MS.pick` och `body.ms-picking` (CSS 10747) ligger kvar. | Kalla `msPickOff()` i alla tre stängningarna. |
| 12 | 10734, 48818, 49548–49560 | Brevet släppzon | Låg | CONFIRMED | CSS `.ms-attach.over` finns men ingen JS togglar `over` på `#ms-drop` under drag (enda `.over`-hanteringen gäller ett annat fönster). | Lägg till/ta bort `over` på `#ms-drop` i pointermove när `under.closest('#mail-send')` och `MS.tab==='send'`. |
| 13 | 48541–48617, 48960, 48811 | Delade valvet drag | Låg | CONFIRMED | Pointermove-selektorn (`#inv-grid [data-inv], #vault-grid [data-vault], #pet-grid [data-pet], #pet-team-grid [data-teamslot]`) saknar `#svault-grid [data-svault]`; `dragTargetsFor` har ingen `d.from === 'shared'`-gren (faller till `[]`) och inv/vault-grenarna tar inte med svault-celler. | Lägg till `#svault-grid [data-svault]` i selektorn; `shared`-gren som returnerar svault-celler + invCells + valvceller; lägg till svault-celler i inv/vault när `sharedActive()`. |
| 14 | 28847 | Delade valvet | Låg | CONFIRMED | `Promise.all([netPullItems(), sharedLoad()])` med en gemensam catch → `SHV.err = true` även när bara väskan föll. | Fånga var för sig; `SHV.err` bara när `sharedLoad` faller. |
| 15 | 28843 | Delade valvet | Låg | CONFIRMED | `if (SHV.busy) return;` utan besked. | `say('One move at a time.')` eller kö. |
| 16 | 48824–48826 | Delade valvet drop på fliken | Låg | CONFIRMED | Valvpjäs släppt på `[data-vtab="shared"]` flyttas även när spalten är stängd; två snabba släpp startar två `sharedLoad()`. | Sätt `SHV.tab='shared'` + rendera före `put`, eller kräv öppen spalt. |
| 17 | 48936–48948 | Delade valvet drop från kroppen | Låg | CONFIRMED | `from 'equip'` (och väska från fack) på `#svault-grid` faller igenom till `cell`/`inInvArea` som är null → tyst. | `say('Unequip first.')` eller unequip + `sharedPut`. |
| 18 | 42046–42056, 41347 | Reset tree | Låg | CONFIRMED | `PPT.resetArmed = false` sätts före `await srvRpc('skill_reset')` och inget blockerar ett andra `skillReset`. `netPullSkillResetCost()` på 41347 är fire-and-forget utan omritning; `skillResetGold` faller då till lokal formel = 10 gold i NET-läge (`S.skillResets` ökas aldrig online). | `PPT.resetBusy`-flagga; `netPullSkillResetCost().then(ppForceRender)`. |
| 19 | 58240–58263 | Uppdragstavlan efter claim | Låg | CONFIRMED | `netPull()`/`netPullItems()` ligger i samma `try` som `mission_claim`; faller de visas `srvErrText(e)` och "Mission complete!" har redan sagts men efterföljs av felet; tavlan hämtas om. | Egna try/catch runt de två pull-anropen. |
| 20 | 58182 (jfr 58159, 58166) | Uppdragstavlan | Låg | PLAUSIBLE | `mbLeanOptions(st, m.region)` saknar `\|\| st.region`-fallback som 58159/58166 har; saknar posten `region` blir `val = []` → ingen Hand in-knapp. | `mbLeanOptions(st, m.region \|\| st.region)`. |
| 21 | 58196 | Uppdragstavlan | Låg | CONFIRMED | `MB.err` visas bara när `!MB.st`; senare fel i `mbPull` syns inte. | Visa en liten "Could not refresh"-rad när `MB.err && MB.st`. |
| 22 | 58076, 58089 | Uppdragstavlan | Låg | CONFIRMED | `mbTimer` (1 s) rensas aldrig; `mbTick` returnerar tidigt när tavlan är stängd. Ofarligt. | `clearInterval` när nodfönstret stängs. |
| 23 | 53845 | Auktionen | Låg | PLAUSIBLE | `ahSetPrice` använder `(g \| 0)`; `ahP` (53830) fick samma 2^31-fix tidigare. | `Math.floor(+g \|\| 0)`. |
| 24 | 29480–29484 | Brevet | Låg | PLAUSIBLE | `MS.att` lever kvar när väskan ändras; `item_must_be_in_bag` mappas till text men chipen pekas inte ut. | Vid det felet: validera chips mot `S.inv` (sid / key+qty), markera eller ta bort saknade. |
| 25 | 29355–29393 | Brevet | Låg | CONFIRMED | `msFillItems`/`msQtyShow` letar efter `#ms-item`, `#ms-qtyf`, `#ms-qty`, `#ms-cg`, `#ms-ch` som inte finns i HTML (14432–14451); `change`-lyssnaren på 29393 gör inget. | Ta bort. |

### Kontrollerat utan anmärkning (teknisk)

- `esc()` (49970) används på `m.name`, `blurb`, `region_name`, `lean.name`, affixnamn, `from`/subject/body i inkorgen, lådlistans namn/sub/fel, gemnamn i `askConfirm`. `say()` skriver via `textContent`.
- `cacheLevelNeed` (55888) och `cacheLevelOk` är konsekventa på 46396–46402, 46689–46693, 56099, 56187, 56144. `castThen` avbryter pågående kast så Open one/Open all kan inte dubbelköras. `useCacheTicketSome` klämmer 1..qty; `useCacheTicketAll` stoppar vid första felet.
- `showCacheMulti` (56201): `isTouchInput()`-vakt på hover (56236–56244), global mouseover-säkring 45828–45833, `.cm-list` 52vh, fönsterbredd `100vw-16px`, 44 px knappar på telefon.
- `msSend` (29462): `btn.disabled` + `finally`; Enter skickar inte; `msSuggest` kontrollerar inputvärdet mot svaret; `msAttachIdx` stoppar dubblett-sid, överbifogning och krediter. `openSendAlt` stänger knappen under RPC.
- `wbFit` (51269–51306): nollar `wbfx/wbfp/wbfs`, inline zoom/maxHeight/width, delar bort body-zoom från `fitApp`; `wbFitCheck` (51308) triggar bara när rutan inte får plats; resize-lyssnaren körs efter `fitApp` via `setTimeout(0)`. WB-modalen använder `100dvh` (3987, 4879); bara 4878/4905 har kvar `100vh`, ofarligt.
- `moneyIcoHTML` (26505) och alla 11 anrop: numerisk indata, HTML endast via `uiIco`. `ahDoList` vaktar `AH.busy` och `price < 1`; inputs `inputmode=numeric`, icke-siffror strippas.
- `sharedMove`: `SHV.busy` nollas alltid; `SHV.forChar === SRV.charId`; kortet för Shared-pjäs har bara "To backpack" (46071); fönsterdrag ignorerar `[data-svault]` (47235); `moveInShared` är lokal ordning.
- Telefon: sista `@media (max-width:760px)` är 13401/13421/13425, inget efter före `</style>` 13436. `.mb-`-hover bakom `(hover:hover)` (13393) + klick-toggle; `.mb-guide` fungerar statiskt i `.mb-focus{position:relative}`; gem-reroll-hover bakom `(hover:hover)`; `.vault-two` staplas (13431); `#svault-grid .inv-slot` aspect-ratio 1 (13429). `askConfirm` z 600/1950 ligger över `.modal-overlay` 400/1500 och `bringToFront` stannar på 490.
