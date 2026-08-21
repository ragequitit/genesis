# GENESIS — THE PROFESSION & CRAFTING ECONOMY, AS BUILT

> Measured out of the running game file and the live server on 2026-08-21, at
> version **v4.68.0**. Client and server were compared with a checksum over all
> 143 recipes including every ingredient: **identical**.
>
> **This file describes what exists today. Nothing here is a proposal.**

---

## 1 · THE EIGHT PROFESSIONS

Four **gathering** professions produce raw material. Four **crafting**
professions turn it into finished goods. Each costs gold to learn, and the price
multiplies by five for each profession you already know.

| Profession | Kind | What it does |
|---|---|---|
| **Outfitter** 🧥 | crafting | Crafts armour: head, chest, hands, waist, legs and boots. |
| **Weaponsmith** ⚔️ | crafting | Forges weapons, off-hands and — uniquely — transports. |
| **Jewelcrafter** 💍 | crafting | Cuts gems and crafts neck, rings and relics. |
| **Chemist** ⚗️ | crafting | Brews flasks, serums and tonics — consumable boosts. |
| **Extractor** ⛏️ | gathering | Mines ore, minerals and the gems jewelcrafters need. |
| **Fabricator** 🧵 | gathering | Harvests fibers, polymer and weaves for outfitters. |
| **Bioharvester** 🌿 | gathering | Gathers digital blooms, roots and fungi for chemists. |
| **Mechanic** 🔧 | gathering | Salvages wire, circuits, cells, lenses and cogs — the parts everything else needs. |

Each crafter also owns **one bound component** it alone can make, which its own
higher recipes then consume:

| Crafter | Component |
|---|---|
| Outfitter | Masterweave Thread |
| Weaponsmith | Forge Core |
| Jewelcrafter | Resonance Dust |
| Chemist | Catalyst Essence |

---

## 2 · GATHERING — HOW MATERIAL ENTERS THE WORLD

Each gathering profession runs its own idle loop. **A shift is one hour.** Every
**5 seconds** a roll happens. **65 % of rolls give nothing.** So a shift is
720 rolls, of which about 252 hit — **252 materials per hour per profession**.

What a hit gives depends on **where you are standing** — the region's ring, 0
(home) to 4 (frontier). It is a weight, never a lock: any base material can be
found anywhere.

| Ring | Chance the hit is a RARE material | Extractor's extra GEM chance |
|---|---|---|
| 0 | 3 % | 1 % |
| 1 | 5 % | 1.5 % |
| 2 | 9 % | 2.5 % |
| 3 | 15 % | 4 % |
| 4 | 24 % | 6 % |

The gem roll happens **beside** the normal outcome, not instead of it, and only
for the Extractor.

### The four pools — five base + two rare each

**Extractor**
- base: Tin · Iron · Platinum · Quartz · Cobalt
- rare: Voidsteel · Genesis Crystal
- gems (side roll): Diamond · Ruby · Sapphire · Amethyst

**Fabricator**
- base: Fiber · Mesh · Weave · Silk · Cord
- rare: Phase Thread · Memory Weave

**Bioharvester**
- base: Bloom · Root · Mushroom · Moss · Sap
- rare: Null Orchid · Genesis Spore

**Mechanic**
- base: Wire · Circuit · Battery · Lens · Cog
- rare: Power Core · Data Chip

Perks that touch gathering: **Keen Eye** (+2 % hit chance per level, 5 levels)
and **Quick Hands** (−0.5 s per roll per level, 3 levels, floor 2 s).

---

## 3 · WHAT EVERYTHING IS WORTH

One price per **kind** of material, not per material. This is the spine of the
whole economy.

| Kind | Vendor price |
|---|---|
| Scrap | 1s |
| Base material | 3s |
| Gemstone | 8s |
| Rare material | 15s |
| Crafting component | 15s |
| Refined material | 75s |
| Filament Spool (crafted base) | 9s |
| Crafting Kit — sells back for | 4s |

**Five conversions are exactly value-neutral, and that is the point:**
- 3 scrap (3 s) → 1 base material (3 s)
- 5 rare (75 s) → 1 refined (75 s)
- the Spool likewise

If any of those numbers drift, refining either destroys value or prints money.

### The Crafting Kit — the only ingredient you cannot find
Bought from the vendor for **20 silver**, sells back for **4**, account-bound.
Required amount by rarity: **1 / 2 / 4 / 7 / 11 / 16**.

The rule for which recipes need kits is one sentence and needs no exception list:
**if the recipe outputs a MATERIAL it needs no kit; if it outputs a finished
product it needs them.** That covers scrap refining, the three refined materials
and the four crafter components — all of which are materials.

**This is where crafting's real cost sits.** Everything else can be gathered for
free; the kit costs gold every single time.

### The money printer is closed
**A crafted item is worth 20 % of what the recipe ate, and that number never
moves** — not with level, reputation, later price changes or a change of owner.
Before this rule: 60 silver of material in, 11.5 gold out — nineteen times, up
to thirty-two. **Zero of 143 recipes now return more than they consume**,
checked on both sides.

Value is stored two ways, and it is not a choice: a **gear piece is unique** and
carries the number itself; a **flask stacks** and has no room for a number per
copy, so it is computed per RECIPE and looked up on (key, rarity). A guard warns
if two recipes give the same flask a different value.

---

## 4 · THE RECIPE REGISTER — 143 RECIPES

**143 recipes total: 12 conversions (material → material) and 131 finished products.**

| Profession | Recipes | of which conversions | finished products |
|---|---|---|---|
| Outfitter | 27 | 1 | 26 |
| Weaponsmith | 27 | 1 | 26 |
| Jewelcrafter | 27 | 1 | 26 |
| Chemist | 28 | 1 | 27 |
| Extractor | 2 | 2 | 0 |
| Fabricator | 2 | 2 | 0 |
| Bioharvester | 2 | 2 | 0 |
| Mechanic | 28 | 2 | 26 |

### The four balance rules
All four are machine-checkable and all four are green on both sides:
1. the profession's **main pool supplies at least 50 %** of the material in every recipe
2. **no pool contributes less than 25 %** of a recipe
3. forbidden materials never appear
4. the single-pool ladder holds

The lesson that produced them, worth repeating: *do not ask for balance numbers,
ask for rules that can be measured.*

### Recipe shape by rarity (measured, and remarkably regular)

| Rarity | Level gate | Source | Base material units | Crafting kits | Component |
|---|---|---|---|---|---|
| Common | 1 | known | ~5 | 1 | — |
| Uncommon | 5 | known | ~9 | 2 | — |
| Rare | **10** | drop | ~12 | 4 | 1 |
| Epic | **16** | drop | 12–20 | 7 | 1–2 |

Rare and epic recipes are **found, not given** — they drop as schematics and must
be learned. The level gates were lowered from 12→10 and 20→16; measured in
gathering hours that took rare from 9 h to **5.5 h** and epic from 31 h to
**17.8 h**, against a player ceiling of about 36 h.

---

## 5 · PROFESSION XP

```
XP to next level = 60 × level ^ 1.4
craft XP         = 20 + 8 × units consumed + [0/20/50/100/175/275] by rarity
```

**Craft XP is paid for what the recipe ATE, not for how fine the result is.** A
recipe on 23 materials is 23 gathered finds regardless of rarity. Nullweave
Mantle went from 70 to **304 XP** when this rule landed.

**Crafting kits do not count toward XP.** They are bought with gold; if they
granted XP it would be buying profession levels with money — exactly the
shortcut Tokens and Fragments are already protected from.

---

## 6 · WHAT THE CRAFTERS ACTUALLY MAKE

| Crafter | Makes |
|---|---|
| **Outfitter** | head, chest, hands, waist, legs, boots |
| **Weaponsmith** | weapons, off-hands, transports |
| **Jewelcrafter** | necks, rings, relics, gems |
| **Chemist** | flasks, serums, tonics — stackable consumable boosts |
| **Mechanic** | the fourth gatherer, and the only source of Tech Parts |

### The Chemist is the odd one out
Every other crafter makes **gear**. The Chemist makes **consumables** — nine
flask types, each a temporary boost, each with a full Common→Uncommon→Rare
ladder (three also reach Epic).

| Flask | Boost | Strength by rarity | Duration by rarity |
|---|---|---|---|
| Data Flask | Data per second | 60% / 90% / 140% / 240% | 10m / 15m / 25m / 60m |
| Focus Flask | Crit Chance | 20% / 30% / 45% / 70% | 10m / 15m / 20m / 40m |
| Impact Flask | Crit Damage | 25% / 40% / 60% / 90% | 10m / 15m / 20m / 40m |
| Trail Flask | shorter travel | 15% / 20% / 30% / 45% | 15m / 20m / 30m / 60m |
| Learning Flask | Player XP | 20% / 30% / 45% / 70% | 15m / 20m / 30m / 60m |
| Echo Serum | Pet XP | 25% / 40% / 60% / 90% | 15m / 20m / 30m / 60m |
| Expedition Catalyst | shorter expeditions | 20% / 30% / 45% / 70% | 20m / 30m / 45m / 90m |
| Genesis Compound | Data per second | 60% / 90% / 140% / 240% | 10m / 15m / 25m / 60m |
| Fortune Flask | more Loot Luck | 20% / 30% / 45% / 70% | 15m / 20m / 30m / 60m |

---

## 7 · EVERY RECIPE, IN FULL

Cost is what the recipe consumes. **Value** is what the finished item is worth
(20 % of input). **Input** is what the ingredients were worth.

### Outfitter — 27 recipes

| id | Recipe | Makes | Rarity | Lvl | Source | Consumes | Input value | Item value |
|---|---|---|---|---|---|---|---|---|
| `of_c1` | Courier's Gloves | Runner's Gloves | Common | 1 | known | 2× Mesh · 3× Weave · 1× Crafting Kit | 35s | 7s |
| `of_c2` | Padded Workboots | Runner's Boots | Common | 1 | known | 2× Mesh · 3× Cord · 1× Crafting Kit | 35s | 7s |
| `of_c3` | Utility Trousers | Runner's Trousers | Common | 1 | known | 2× Weave · 3× Silk · 1× Crafting Kit | 35s | 7s |
| `of_c4` | Field Vest | Runner's Vest | Common | 1 | known | 3× Fiber · 2× Silk · 1× Crafting Kit | 35s | 7s |
| `of_c5` | Utility Belt | Utility Rig | Common | 1 | known | 1× Mesh · 2× Cord · 1× Bloom · 1× Mushroom · 1× Crafting Kit | 35s | 7s |
| `of_c6` | Survey Cap | Runner's Cap | Common | 1 | known | 1× Weave · 2× Silk · 1× Moss · 1× Sap · 1× Crafting Kit | 35s | 7s |
| `of_u1` | Staticweave Gloves | Runner's Gloves | Uncommon | 5 | known | 4× Weave · 5× Silk · 2× Crafting Kit | 67s | 13s 40c |
| `of_u2` | Reinforced Trailboots | Runner's Boots | Uncommon | 5 | known | 4× Mesh · 5× Cord · 2× Crafting Kit | 67s | 13s 40c |
| `of_u3` | Signalweave Trousers | Runner's Trousers | Uncommon | 5 | known | 4× Weave · 5× Silk · 2× Crafting Kit | 67s | 13s 40c |
| `of_u4` | Woven Courier Vest | Runner's Vest | Uncommon | 5 | known | 4× Fiber · 5× Weave · 2× Crafting Kit | 67s | 13s 40c |
| `of_u5` | Phasebound Belt | Signal Belt | Uncommon | 5 | known | 2× Mesh · 3× Cord · 2× Mushroom · 2× Sap · 2× Crafting Kit | 67s | 13s 40c |
| `of_u6` | Polymer Pants | Circuit Trousers | Uncommon | 5 | known | 3× Mesh · 2× Silk · 2× Bloom · 2× Root · 2× Crafting Kit | 67s | 13s 40c |
| `of_u7` | Signal Hood | Circuit Cap | Uncommon | 5 | known | 2× Silk · 3× Cord · 2× Lens · 2× Cog · 2× Crafting Kit | 67s | 13s 40c |
| `of_k1` | Spin Masterweave | Masterweave Thread | Rare | 10 | known | 1× Refined Phaseweave · 4× Silk | 87s | 17s 40c |
| `of_r1` | Runner Boots | Runner's Boots | Rare | 10 | drop | 2× Weave · 4× Cord · 3× Mushroom · 3× Sap · 1× Refined Phaseweave · 1× Masterweave Thread · 4× Crafting Kit | 2g 6s | 41s 20c |
| `of_r2` | Staticrunner Gloves | Runner's Gloves | Rare | 10 | drop | 3× Mesh · 3× Silk · 3× Root · 3× Moss · 1× Masterweave Thread · 4× Crafting Kit | 1g 31s | 26s 20c |
| `of_r3` | Deep Network Vest | Runner's Vest | Rare | 10 | drop | 3× Fiber · 3× Silk · 4× Battery · 2× Cog · 1× Masterweave Thread · 4× Crafting Kit | 1g 31s | 26s 20c |
| `of_r4` | Memoryweave Trousers | Runner's Trousers | Rare | 10 | drop | 7× Mesh · 5× Weave · 1× Refined Phaseweave · 1× Masterweave Thread · 4× Crafting Kit | 2g 6s | 41s 20c |
| `of_r5` | Signalkeeper Belt | Plated Sash | Rare | 10 | drop | 2× Weave · 4× Cord · 2× Bloom · 4× Mushroom · 1× Refined Phaseweave · 1× Masterweave Thread · 4× Crafting Kit | 2g 6s | 41s 20c |
| `of_r6` | Phase Visor | Phase Cap | Rare | 10 | drop | 2× Silk · 4× Cord · 4× Lens · 2× Cog · 1× Masterweave Thread · 4× Crafting Kit | 1g 31s | 26s 20c |
| `of_r7` | Phasewalker Boots | Phase Boots | Rare | 10 | drop | 4× Mesh · 2× Weave · 3× Bloom · 3× Moss · 1× Masterweave Thread · 4× Crafting Kit | 1g 31s | 26s 20c |
| `of_r8` | Sealed Gloves | Phase Gloves | Rare | 10 | drop | 6× Silk · 3× Root · 3× Sap · 1× Refined Phaseweave · 1× Masterweave Thread · 4× Crafting Kit | 2g 6s | 41s 20c |
| `of_e1` | Nullweave Mantle | Runner's Vest | Epic | 16 | drop | 5× Fiber · 5× Weave · 4× Moss · 6× Sap · 2× Refined Phaseweave · 2× Masterweave Thread · 7× Crafting Kit | 3g 80s | 76s |
| `of_e2` | Courier Armor | Genesis Vest | Epic | 16 | drop | 1× Weave · 9× Silk · 3× Mushroom · 7× Sap · 2× Refined Phaseweave · 2× Masterweave Thread · 7× Crafting Kit | 3g 80s | 76s |
| `of_e3` | Genesis Pants | Genesis Trousers | Epic | 16 | drop | 5× Mesh · 5× Silk · 5× Bloom · 5× Moss · 2× Refined Phaseweave · 2× Masterweave Thread · 7× Crafting Kit | 3g 80s | 76s |
| `of_e4` | Null Hood | Genesis Cap | Epic | 16 | drop | 5× Fiber · 5× Weave · 6× Root · 4× Mushroom · 2× Refined Phaseweave · 2× Masterweave Thread · 7× Crafting Kit | 3g 80s | 76s |
| `of_e5` | Vinestep Boots | Genesis Boots | Epic | 16 | drop | 3× Mesh · 7× Cord · 7× Wire · 3× Cog · 2× Refined Phaseweave · 2× Masterweave Thread · 7× Crafting Kit | 3g 80s | 76s |

### Weaponsmith — 27 recipes

| id | Recipe | Makes | Rarity | Lvl | Source | Consumes | Input value | Item value |
|---|---|---|---|---|---|---|---|---|
| `ws_c1` | Ironcut Blade | Runner's Dagger | Common | 1 | known | 3× Iron · 2× Quartz · 1× Crafting Kit | 35s | 7s |
| `ws_c2` | Tinvein Dagger | Runner's Dagger | Common | 1 | known | 3× Tin · 2× Cobalt · 1× Crafting Kit | 35s | 7s |
| `ws_c3` | Field Guard | Wooden Shield | Common | 1 | known | 3× Iron · 2× Cobalt · 1× Crafting Kit | 35s | 7s |
| `ws_c4` | Signal Baton | Runner's Dagger | Common | 1 | known | 3× Quartz · 1× Weave · 1× Cord · 1× Crafting Kit | 35s | 7s |
| `ws_c5` | Courier Board | Streetblade | Common | 1 | known | 3× Iron · 2× Cobalt · 1× Crafting Kit | 35s | 7s |
| `ws_c6` | Copper Pistol | Runner's Dagger | Common | 1 | known | 2× Tin · 1× Iron · 1× Mesh · 1× Cord · 1× Crafting Kit | 35s | 7s |
| `ws_u1` | Coilblade | Runner's Dagger | Uncommon | 5 | known | 4× Tin · 5× Cobalt · 2× Crafting Kit | 67s | 13s 40c |
| `ws_u2` | Signal Guard | Street Buckler | Uncommon | 5 | known | 4× Iron · 1× Cobalt · 2× Mesh · 2× Cord · 2× Crafting Kit | 67s | 13s 40c |
| `ws_u3` | Longwave Rifle | Runner's Dagger | Uncommon | 5 | known | 5× Tin · 4× Cobalt · 2× Crafting Kit | 67s | 13s 40c |
| `ws_u4` | Gavelfall Maul | Runner's Dagger | Uncommon | 5 | known | 4× Iron · 5× Quartz · 2× Crafting Kit | 67s | 13s 40c |
| `ws_u5` | Skyrail Drifter | Hoverdeck | Uncommon | 5 | known | 3× Tin · 2× Iron · 3× Mesh · 1× Weave · 2× Crafting Kit | 67s | 13s 40c |
| `ws_u6` | Cog Hammer | Circuit Beam Rifle | Uncommon | 5 | known | 3× Tin · 2× Cobalt · 2× Circuit · 2× Cog · 2× Crafting Kit | 67s | 13s 40c |
| `ws_u7` | Coil Pistol | Salvage Wrench | Uncommon | 5 | known | 2× Iron · 3× Quartz · 2× Circuit · 2× Battery · 2× Crafting Kit | 67s | 13s 40c |
| `ws_k1` | Cast Forge Core | Forge Core | Rare | 10 | known | 1× Refined Voidsteel · 4× Iron | 87s | 17s 40c |
| `ws_r1` | Quartzcut Blade | Runner's Dagger | Rare | 10 | drop | 6× Tin · 6× Quartz · 1× Refined Voidsteel · 1× Forge Core · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ws_r2` | Arcshield | Arc Torch | Rare | 10 | drop | 3× Iron · 3× Cobalt · 4× Battery · 2× Cog · 1× Refined Voidsteel · 1× Forge Core · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ws_r3` | Fusecoil Staff | Runner's Dagger | Rare | 10 | drop | 3× Iron · 3× Cobalt · 3× Circuit · 3× Battery · 1× Forge Core · 4× Crafting Kit | 1g 31s | 26s 20c |
| `ws_r4` | Longwave Marksman | Runner's Dagger | Rare | 10 | drop | 3× Iron · 3× Cobalt · 3× Mesh · 3× Weave · 1× Forge Core · 4× Crafting Kit | 1g 31s | 26s 20c |
| `ws_r5` | Phase Drifter | Sky Lance | Rare | 10 | drop | 4× Tin · 2× Iron · 2× Mesh · 4× Cord · 1× Refined Voidsteel · 1× Forge Core · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ws_r6` | Dream Wand | Phase Wand | Rare | 10 | drop | 4× Tin · 2× Quartz · 3× Wire · 3× Circuit · 1× Forge Core · 4× Crafting Kit | 1g 31s | 26s 20c |
| `ws_r7` | Cobalt Shield | Coil Battery | Rare | 10 | drop | 3× Iron · 3× Cobalt · 3× Weave · 3× Cord · 1× Refined Voidsteel · 1× Forge Core · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ws_r8` | Power Maul | Phase Wand | Rare | 10 | drop | 4× Quartz · 2× Cobalt · 3× Battery · 3× Cog · 1× Forge Core · 4× Crafting Kit | 1g 31s | 26s 20c |
| `ws_r9` | Signal Blade | Circuit Beam Rifle | Rare | 10 | drop | 3× Tin · 3× Quartz · 3× Weave · 3× Cord · 1× Forge Core · 4× Crafting Kit | 1g 31s | 26s 20c |
| `ws_e1` | Voidrunner Bike | Prowler | Epic | 16 | drop | 6× Tin · 4× Cobalt · 4× Circuit · 6× Battery · 2× Refined Voidsteel · 2× Forge Core · 7× Crafting Kit | 3g 80s | 76s |
| `ws_e2` | Longshot Rifle | Genesis Hammer | Epic | 16 | drop | 3× Tin · 7× Quartz · 6× Circuit · 4× Lens · 2× Refined Voidsteel · 2× Forge Core · 7× Crafting Kit | 3g 80s | 76s |
| `ws_e3` | Shell Rider | Genesis Shellback | Epic | 16 | drop | 5× Iron · 5× Cobalt · 5× Mesh · 5× Cord · 2× Refined Voidsteel · 2× Forge Core · 7× Crafting Kit | 3g 80s | 76s |
| `ws_e4` | Voidsteel Blade | Voidsteel Greatsword | Epic | 16 | drop | 3× Iron · 7× Quartz · 6× Weave · 4× Cord · 2× Refined Voidsteel · 2× Forge Core · 7× Crafting Kit | 3g 80s | 76s |

### Jewelcrafter — 27 recipes

| id | Recipe | Makes | Rarity | Lvl | Source | Consumes | Input value | Item value |
|---|---|---|---|---|---|---|---|---|
| `jc_c1` | Tin Signal Ring | Copper Band | Common | 1 | known | 3× Tin · 2× Platinum · 1× Crafting Kit | 35s | 7s |
| `jc_c2` | Iron Loop | Iron Ring | Common | 1 | known | 2× Tin · 3× Iron · 1× Crafting Kit | 35s | 7s |
| `jc_c3` | Quartz Pendant | Signal Tag | Common | 1 | known | 2× Quartz · 1× Cobalt · 1× Bloom · 1× Sap · 1× Crafting Kit | 35s | 7s |
| `jc_c4` | Courier's Charm | Circuit Pendant | Common | 1 | known | 4× Platinum · 1× Quartz · 1× Crafting Kit | 35s | 7s |
| `jc_c5` | Cut Quartz | Signal Ring | Common | 1 | known | 2× Platinum · 3× Quartz · 1× Crafting Kit | 35s | 7s |
| `jc_c6` | Cobalt Ring | Circuit Band | Common | 1 | known | 1× Platinum · 2× Cobalt · 1× Moss · 1× Sap · 1× Crafting Kit | 35s | 7s |
| `jc_u1` | Platinum Signal Ring | Signal Ring | Uncommon | 5 | known | 5× Platinum · 4× Cobalt · 2× Crafting Kit | 67s | 13s 40c |
| `jc_u2` | Static Pendant | Circuit Pendant | Uncommon | 5 | known | 3× Platinum · 2× Quartz · 2× Mesh · 2× Silk · 2× Crafting Kit | 67s | 13s 40c |
| `jc_u3` | Quartz Loop | Crystal Ring | Uncommon | 5 | known | 4× Platinum · 5× Quartz · 2× Crafting Kit | 67s | 13s 40c |
| `jc_u4` | Network Charm | Signal Tag | Uncommon | 5 | known | 4× Tin · 5× Quartz · 2× Crafting Kit | 67s | 13s 40c |
| `jc_u5` | Cut Amethyst | Circuit Band | Uncommon | 5 | known | 9× Platinum · 1× Amethyst · 2× Crafting Kit | 75s | 15s |
| `jc_u6` | Ruby Ring | Circuit Glowband | Uncommon | 5 | known | 3× Iron · 2× Platinum · 2× Moss · 2× Sap · 1× Ruby · 2× Crafting Kit | 75s | 15s |
| `jc_u7` | Signal Pendant | Circuit Emblem | Uncommon | 5 | known | 2× Iron · 3× Cobalt · 1× Silk · 3× Cord · 2× Crafting Kit | 67s | 13s 40c |
| `jc_k1` | Grind Resonance | Resonance Dust | Rare | 10 | known | 1× Refined Voidsteel · 4× Quartz | 87s | 17s 40c |
| `jc_r1` | Resonance Ring | Crystal Ring | Rare | 10 | drop | 6× Platinum · 6× Cobalt · 1× Resonance Dust · 4× Crafting Kit | 1g 31s | 26s 20c |
| `jc_r2` | Glassheart Pendant | Crystal Amulet | Rare | 10 | drop | 4× Iron · 2× Quartz · 3× Moss · 3× Sap · 1× Refined Voidsteel · 1× Resonance Dust · 4× Crafting Kit | 2g 6s | 41s 20c |
| `jc_r3` | Phase Loop | Signal Ring | Rare | 10 | drop | 3× Tin · 3× Iron · 2× Moss · 4× Sap · 1× Resonance Dust · 4× Crafting Kit | 1g 31s | 26s 20c |
| `jc_r4` | Signal Relic | Signal Tag | Rare | 10 | drop | 3× Iron · 3× Quartz · 3× Silk · 3× Cord · 1× Refined Voidsteel · 1× Resonance Dust · 4× Crafting Kit | 2g 6s | 41s 20c |
| `jc_r5` | Perfect Sapphire | Crystal Ring | Rare | 10 | drop | 3× Quartz · 3× Cobalt · 4× Bloom · 2× Moss · 2× Sapphire · 1× Refined Voidsteel · 1× Resonance Dust · 4× Crafting Kit | 2g 22s | 44s 40c |
| `jc_r6` | Facet Relic | Phase Puzzlebox | Rare | 10 | drop | 6× Platinum · 3× Circuit · 3× Lens · 1× Refined Voidsteel · 1× Resonance Dust · 4× Crafting Kit | 2g 6s | 41s 20c |
| `jc_r7` | Data Ring | Phase Ripple | Rare | 10 | drop | 6× Platinum · 3× Wire · 3× Lens · 1× Resonance Dust · 4× Crafting Kit | 1g 31s | 26s 20c |
| `jc_r8` | Lens Relic | Circuit Hexcore | Rare | 10 | drop | 3× Tin · 3× Platinum · 3× Lens · 3× Cog · 1× Resonance Dust · 4× Crafting Kit | 1g 31s | 26s 20c |
| `jc_rel1` | Everfrost Cut | Shard of Everfrost | Rare | 10 | drop | 3× Platinum · 3× Cobalt · 3× Bloom · 3× Sap · 2× Diamond · 1× Refined Voidsteel · 1× Resonance Dust · 4× Crafting Kit | 2g 22s | 44s 40c |
| `jc_e1` | Heart of the Network | Crystal Amulet | Epic | 16 | drop | 6× Tin · 4× Cobalt · 6× Lens · 4× Cog · 2× Refined Voidsteel · 2× Resonance Dust · 7× Crafting Kit | 3g 80s | 76s |
| `jc_e2` | Genesis Relic | Genesis Seed | Epic | 16 | drop | 10× Platinum · 7× Bloom · 3× Sap · 2× Refined Voidsteel · 2× Resonance Dust · 7× Crafting Kit | 3g 80s | 76s |
| `jc_e3` | Glass Relic | Voidsteel Reliquary | Epic | 16 | drop | 6× Platinum · 4× Quartz · 6× Moss · 4× Sap · 2× Refined Voidsteel · 2× Resonance Dust · 7× Crafting Kit | 3g 80s | 76s |
| `jc_e4` | Vine Ring | Genesis Sprout | Epic | 16 | drop | 6× Iron · 4× Platinum · 6× Bloom · 4× Moss · 2× Refined Voidsteel · 2× Resonance Dust · 7× Crafting Kit | 3g 80s | 76s |

### Chemist — 28 recipes

| id | Recipe | Makes | Rarity | Lvl | Source | Consumes | Input value | Item value |
|---|---|---|---|---|---|---|---|---|
| `ch_c1` | Data Flask | Data Flask | Common | 1 | known | 2× Bloom · 3× Mushroom · 1× Crafting Kit | 35s | 7s |
| `ch_c2` | Focus Flask | Focus Flask | Common | 1 | known | 4× Root · 1× Sap · 1× Crafting Kit | 35s | 7s |
| `ch_c3` | Impact Flask | Impact Flask | Common | 1 | known | 3× Mushroom · 2× Sap · 1× Crafting Kit | 35s | 7s |
| `ch_c4` | Trail Flask | Trail Flask | Common | 1 | known | 2× Fiber · 1× Root · 2× Moss · 1× Crafting Kit | 35s | 7s |
| `ch_c5` | Learning Flask | Learning Flask | Common | 1 | known | 3× Bloom · 2× Root · 1× Crafting Kit | 35s | 7s |
| `ch_c6` | Fortune Flask | Fortune Flask | Common | 1 | known | 4× Moss · 1× Sap · 1× Crafting Kit | 35s | 7s |
| `ch_c7` | Echo Flask | Echo Serum | Common | 1 | known | 3× Bloom · 2× Moss · 1× Crafting Kit | 35s | 7s |
| `ch_c8` | Scout Flask | Expedition Catalyst | Common | 1 | known | 3× Root · 2× Mushroom · 1× Crafting Kit | 35s | 7s |
| `ch_r7` | Growth Serum | Echo Serum | Uncommon | 5 | known | 6× Fiber · 3× Bloom · 3× Moss · 1× Catalyst Essence · 2× Crafting Kit | 91s | 18s 20c |
| `ch_u1` | Overclock Serum | Data Flask | Uncommon | 5 | known | 7× Bloom · 2× Mushroom · 2× Crafting Kit | 67s | 13s 40c |
| `ch_u2` | Precision Compound | Focus Flask | Uncommon | 5 | known | 7× Root · 2× Sap · 2× Crafting Kit | 67s | 13s 40c |
| `ch_u3` | Impact Catalyst | Impact Flask | Uncommon | 5 | known | 6× Mushroom · 3× Sap · 2× Crafting Kit | 67s | 13s 40c |
| `ch_u4` | Slipstream Tonic | Trail Flask | Uncommon | 5 | known | 4× Fiber · 1× Root · 4× Moss · 2× Crafting Kit | 67s | 13s 40c |
| `ch_u5` | Learning Compound | Learning Flask | Uncommon | 5 | known | 4× Fiber · 4× Bloom · 1× Root · 2× Crafting Kit | 67s | 13s 40c |
| `ch_u6` | Fortune Compound | Fortune Flask | Uncommon | 5 | known | 3× Moss · 2× Sap · 2× Wire · 2× Battery · 2× Crafting Kit | 67s | 13s 40c |
| `ch_u7` | Expedition Flask | Expedition Catalyst | Uncommon | 5 | known | 3× Root · 2× Mushroom · 2× Wire · 2× Lens · 2× Crafting Kit | 67s | 13s 40c |
| `ch_k1` | Distil Catalyst | Catalyst Essence | Rare | 10 | known | 1× Refined Bioessence · 4× Bloom | 87s | 17s 40c |
| `ch_r1` | Echo Growth Serum | Echo Serum | Rare | 10 | drop | 7× Bloom · 5× Moss · 1× Refined Bioessence · 1× Catalyst Essence · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ch_r2` | Expedition Catalyst | Expedition Catalyst | Rare | 10 | drop | 6× Mushroom · 3× Wire · 3× Circuit · 1× Catalyst Essence · 4× Crafting Kit | 1g 31s | 26s 20c |
| `ch_r3` | Deep Focus Serum | Focus Flask | Rare | 10 | drop | 6× Fiber · 6× Root · 1× Refined Bioessence · 1× Catalyst Essence · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ch_r4` | Network Overclock | Data Flask | Rare | 10 | drop | 3× Bloom · 9× Mushroom · 1× Refined Bioessence · 1× Catalyst Essence · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ch_r5` | Pathfinder Compound | Trail Flask | Rare | 10 | drop | 3× Fiber · 3× Mesh · 3× Root · 3× Moss · 1× Catalyst Essence · 4× Crafting Kit | 1g 31s | 26s 20c |
| `ch_r8` | Learning Serum | Learning Flask | Rare | 10 | drop | 5× Fiber · 1× Mesh · 6× Root · 1× Refined Bioessence · 1× Catalyst Essence · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ch_r9` | Shatterpoint Serum | Impact Flask | Rare | 10 | drop | 8× Mushroom · 4× Sap · 1× Refined Bioessence · 1× Catalyst Essence · 4× Crafting Kit | 2g 6s | 41s 20c |
| `ch_u8` | Lucky Tonic | Fortune Flask | Rare | 10 | drop | 4× Moss · 1× Sap · 2× Circuit · 2× Lens · 4× Crafting Kit | 1g 7s | 21s 40c |
| `ch_e1` | Genesis Compound | Genesis Compound | Epic | 16 | drop | 7× Fiber · 3× Mesh · 10× Mushroom · 2× Refined Bioessence · 2× Catalyst Essence · 7× Crafting Kit | 3g 80s | 76s |
| `ch_e2` | Genesis Serum | Echo Serum | Epic | 16 | drop | 6× Bloom · 4× Moss · 5× Wire · 5× Circuit · 2× Refined Bioessence · 2× Catalyst Essence · 7× Crafting Kit | 3g 80s | 76s |
| `ch_r6` | Deep Expedition Flask | Expedition Catalyst | Epic | 16 | drop | 3× Root · 3× Mushroom · 3× Wire · 3× Battery · 1× Catalyst Essence · 7× Crafting Kit | 1g 91s | 38s 20c |

### Extractor — 2 recipes

| id | Recipe | Makes | Rarity | Lvl | Source | Consumes | Input value | Item value |
|---|---|---|---|---|---|---|---|---|
| `ex_s1` | Smelt Scrap | Tin | Common | 1 | known | 3× Scrap | 3s | 60c |
| `ex_r1` | Refine Voidsteel | Refined Voidsteel | Rare | 10 | known | 3× Voidsteel · 2× Genesis Crystal | 75s | 15s |

### Fabricator — 2 recipes

| id | Recipe | Makes | Rarity | Lvl | Source | Consumes | Input value | Item value |
|---|---|---|---|---|---|---|---|---|
| `fa_s1` | Unravel Scrap | Fiber | Common | 1 | known | 3× Scrap | 3s | 60c |
| `fa_r1` | Refine Phaseweave | Refined Phaseweave | Rare | 10 | known | 3× Phase Thread · 2× Memory Weave | 75s | 15s |

### Bioharvester — 2 recipes

| id | Recipe | Makes | Rarity | Lvl | Source | Consumes | Input value | Item value |
|---|---|---|---|---|---|---|---|---|
| `bh_s1` | Culture Scrap | Moss | Common | 1 | known | 3× Scrap | 3s | 60c |
| `bh_r1` | Refine Bioessence | Refined Bioessence | Rare | 10 | known | 3× Null Orchid · 2× Genesis Spore | 75s | 15s |

### Mechanic — 28 recipes

| id | Recipe | Makes | Rarity | Lvl | Source | Consumes | Input value | Item value |
|---|---|---|---|---|---|---|---|---|
| `me_c1` | Cargo Board | Salvage Chopper | Common | 1 | known | 1× Fiber · 1× Mesh · 2× Battery · 1× Cog · 1× Crafting Kit | 35s | 7s |
| `me_c2` | Pocket Beacon | Ruby of the Depths | Common | 1 | known | 2× Cobalt · 1× Circuit · 2× Lens · 1× Crafting Kit | 35s | 7s |
| `me_c3` | Pocket Drone | Arc Torch | Common | 1 | known | 3× Wire · 2× Circuit · 1× Crafting Kit | 35s | 7s |
| `me_c4` | Street Board | Hoverdeck | Common | 1 | known | 2× Battery · 3× Cog · 1× Crafting Kit | 35s | 7s |
| `me_c5` | Survey Lens | Shard of Everfrost | Common | 1 | known | 2× Circuit · 3× Lens · 1× Crafting Kit | 35s | 7s |
| `me_c6` | Wire Tool | Deck Slate | Common | 1 | known | 3× Wire · 2× Battery · 1× Crafting Kit | 35s | 7s |
| `me_s1` | Reuse Scrap | Wire | Common | 1 | known | 3× Scrap | 3s | 60c |
| `me_u1` | Alloy Board | Circuit Board | Uncommon | 5 | known | 3× Fiber · 1× Weave · 2× Battery · 3× Cog · 2× Crafting Kit | 67s | 13s 40c |
| `me_u2` | Battery Drone | Circuit Deflector | Uncommon | 5 | known | 2× Fiber · 2× Weave · 2× Wire · 3× Battery · 2× Crafting Kit | 67s | 13s 40c |
| `me_u3` | Coil Board | Prowler | Uncommon | 5 | known | 2× Mesh · 2× Cord · 3× Circuit · 2× Cog · 2× Crafting Kit | 67s | 13s 40c |
| `me_u4` | Repair Arm | Drone Cradle | Uncommon | 5 | known | 2× Fiber · 2× Weave · 2× Wire · 3× Lens · 2× Crafting Kit | 67s | 13s 40c |
| `me_u5` | Repair Drone | Street Buckler | Uncommon | 5 | known | 4× Circuit · 5× Cog · 2× Crafting Kit | 67s | 13s 40c |
| `me_u6` | Scout Lens | Salvage Sparkplug | Uncommon | 5 | known | 4× Wire · 5× Lens · 2× Crafting Kit | 67s | 13s 40c |
| `me_u7` | Signal Scope | Circuit Hexcore | Uncommon | 5 | known | 4× Wire · 5× Circuit · 2× Crafting Kit | 67s | 13s 40c |
| `me_r1` | Build Tech Parts | Tech Parts | Rare | 10 | known | 3× Power Core · 2× Data Chip | 75s | 15s |
| `me_r2` | Dream Skiff | Phase Skiff | Rare | 10 | drop | 2× Tin · 1× Iron · 3× Weave · 3× Circuit · 3× Cog · 1× Tech Parts · 4× Crafting Kit | 1g 91s | 38s 20c |
| `me_r3` | Cobalt Bike | Sky Lance | Rare | 10 | drop | 3× Tin · 3× Cobalt · 4× Battery · 2× Cog · 1× Tech Parts · 4× Crafting Kit | 1g 91s | 38s 20c |
| `me_r4` | Data Compass | Phase Puzzlebox | Rare | 10 | drop | 5× Wire · 7× Lens · 1× Tech Parts · 4× Crafting Kit | 1g 91s | 38s 20c |
| `me_r5` | Network Compass | Ruby of the Depths | Rare | 10 | drop | 2× Tin · 4× Iron · 2× Circuit · 4× Cog · 1× Tech Parts · 4× Crafting Kit | 1g 91s | 38s 20c |
| `me_r6` | Power Lens | Shard of Everfrost | Rare | 10 | drop | 6× Wire · 6× Lens · 1× Tech Parts · 4× Crafting Kit | 1g 91s | 38s 20c |
| `me_r7` | Prism Scope | Salvage Sparkplug | Rare | 10 | drop | 6× Sap · 3× Circuit · 3× Cog · 1× Tech Parts · 4× Crafting Kit | 1g 91s | 38s 20c |
| `me_r8` | Relay Drone | Phase Prism | Rare | 10 | drop | 2× Iron · 1× Cobalt · 1× Fiber · 2× Mesh · 6× Battery · 1× Tech Parts · 4× Crafting Kit | 1g 91s | 38s 20c |
| `me_r9` | Signal Drone | Salvage Hubcap | Rare | 10 | drop | 6× Battery · 6× Cog · 1× Tech Parts · 4× Crafting Kit | 1g 91s | 38s 20c |
| `me_e1` | Core Bike | Voidsteel Charger | Epic | 16 | drop | 2× Tin · 3× Cobalt · 3× Weave · 2× Cord · 6× Battery · 4× Cog · 2× Tech Parts · 7× Crafting Kit | 3g 50s | 70s |
| `me_e2` | Genesis Lens | Genesis Seed | Epic | 16 | drop | 10× Root · 4× Wire · 6× Lens · 2× Tech Parts · 7× Crafting Kit | 3g 50s | 70s |
| `me_e3` | Bloom Guard | Genesis Aegis | Epic | 16 | drop | 3× Iron · 2× Cobalt · 2× Fiber · 3× Mesh · 6× Circuit · 4× Cog · 2× Tech Parts · 7× Crafting Kit | 3g 50s | 70s |
| `me_e4` | Phasecycle | Slipstream | Epic | 16 | drop | 5× Fiber · 5× Cord · 4× Wire · 6× Battery · 2× Tech Parts · 7× Crafting Kit | 3g 50s | 70s |
| `me_e5` | Void Drone | Voidsteel Bulwark | Epic | 16 | drop | 3× Tin · 2× Iron · 2× Mesh · 3× Weave · 6× Lens · 4× Cog · 2× Tech Parts · 7× Crafting Kit | 3g 50s | 70s |

---

## 8 · EVERY MATERIAL

| Material | Kind | Pool | Vendor price |
|---|---|---|---|
| Battery | base | mechanic | 3s |
| Bent Antenna | base | — | 3s |
| Bloom | base | bioharvester | 3s |
| Bottle Cap | base | — | 3s |
| Broken Keyboard | base | — | 3s |
| Circuit | base | mechanic | 3s |
| Cobalt | base | extractor | 3s |
| Cog | base | mechanic | 3s |
| Cord | base | fabricator | 3s |
| Crafting Kit | vendor-only | — | 20 s to buy, 4 s back |
| Dead Battery | base | — | 3s |
| Empty Boost Soda | base | — | 3s |
| Empty Noodle Cup | base | — | 3s |
| Fiber | base | fabricator | 3s |
| Iron | base | extractor | 3s |
| Lens | base | mechanic | 3s |
| Mesh | base | fabricator | 3s |
| Moss | base | bioharvester | 3s |
| Mushroom | base | bioharvester | 3s |
| Old Food Coupon | base | — | 3s |
| Platinum | base | extractor | 3s |
| Quartz | base | extractor | 3s |
| Root | base | bioharvester | 3s |
| Rusty Sword Hilt | base | — | 3s |
| Sap | base | bioharvester | 3s |
| Silk | base | fabricator | 3s |
| Tin | base | extractor | 3s |
| Waterlogged Manual | base | — | 3s |
| Weave | base | fabricator | 3s |
| Wire | base | mechanic | 3s |
| Catalyst Essence | component | — | 15s |
| Forge Core | component | — | 15s |
| Masterweave Thread | component | — | 15s |
| Resonance Dust | component | — | 15s |
| Spool | crafted base | — | 9s |
| Amethyst | gem | extractor | 8s |
| Diamond | gem | extractor | 8s |
| Ruby | gem | extractor | 8s |
| Sapphire | gem | extractor | 8s |
| Data Chip | rare | mechanic | 15s |
| Genesis Crystal | rare | extractor | 15s |
| Genesis Spore | rare | bioharvester | 15s |
| Memory Weave | rare | fabricator | 15s |
| Null Orchid | rare | bioharvester | 15s |
| Phase Thread | rare | fabricator | 15s |
| Power Core | rare | mechanic | 15s |
| Voidsteel | rare | extractor | 15s |
| Refined Bioessence | refined | — | 75s |
| Refined Phaseweave | refined | — | 75s |
| Refined Voidsteel | refined | — | 75s |
| Tech Parts | refined | — | 75s |
| Scrap | scrap | — | 1s |

---

## 9 · WHERE PROFESSIONS TOUCH THE REST OF THE GAME

**IN — what feeds professions**
- gathering shifts (the only material source that is not a drop)
- expedition loot and idle drops (scrap, schematics)
- the vendor (crafting kits — the only gold cost)
- perks: Keen Eye, Quick Hands, Wreck Diver, Signal Filter
- helper ability **Apprentice** (+profession XP)

**OUT — what professions feed**
- gear, for 63 of the 109 items in the game
- all nine consumable boosts
- the auction house (materials and finished goods are the traded stock)
- gold sinks: kits, and the gold cost of learning each profession

**Professions have NO dependency on the node.** Not one recipe, level, price or
chance reads Data, machines, Tokens or the reboot. The only overlap is two
helper abilities (Apprentice, Haggler) and four perks — all of which could be
re-homed without touching the profession economy itself.

