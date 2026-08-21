# GENESIS — THE PRODUCTION SYSTEM ("the Node"), AS BUILT

> Measured out of the running game file and the live server on 2026-08-21, at
> version **v4.68.0**. Every number below was read from code or from the
> database, not from documentation. Where a rule exists on both sides, both were
> checked and they agree.
>
> **This file describes what exists today, so it can be replaced. Nothing here
> is a proposal.**

---

## 1 · WHAT THE NODE IS

The player owns **machines**. Machines produce **Data** per second. Data buys
more machines and four core upgrades. When the node is big enough the player can
**reboot**: the node is wiped and the player is paid in **Tokens**, which buy
permanent perks in a tree. That is the entire loop.

Each machine is also **one seat for one helper**. Ten machines, ten seats, ten
distinct helper abilities — one per machine, no overlap.

**Data buys exactly two things:** machines and the four core upgrades. Nothing
else in the game costs Data — not gear, not materials, not professions, not
expeditions, fuel, auction listings or travel. Data's only other output is the
reboot payout.

---

## 2 · THE TEN MACHINES

Cost grows **×1.15 per unit owned**. `prod` is Data per second per unit before
any multiplier.

| # | Machine | Base cost (Data) | Base prod/s | Helper ability it hosts |
|---|---|---|---|---|
| 1 | 🤖 **Data Scrapyard** | 15 | 0.1 | Scrap Sense — more scrap found |
| 2 | 🧲 **Expedition Beacon** | 100 | 1 | Trailblazer — expeditions finish faster |
| 3 | 🚜 **Profession Grounds** | 1 100 | 8 | Apprentice — faster profession XP |
| 4 | ⛏️ **Trade Post** | 12 000 | 47 | Haggler — everything sells for more |
| 5 | 🐝 **Fragment Collector** | 130 000 | 260 | Fragment Nose — more fragments |
| 6 | 🛸 **Companion Trainer** | 1 400 000 | 1 400 | Mentor — faster helper XP |
| 7 | ⚡ **Fuel Reclaimer** | 20 000 000 | 7 800 | Coolant Flow — fuel regenerates faster |
| 8 | 🛰️ **Cache Foundry** | 330 000 000 | 44 000 | Cache Instinct — better cache odds |
| 9 | 🌀 **Gear Forge** | 5 100 000 000 | 260 000 | Prospector — dropped gear rolls rarer |
| 10 | 🌌 **Genesis Core** | 75 000 000 000 | 1 600 000 | Echo Reader — more Tokens on a reboot |

**The shape of the ladder:** machine 1 costs 15 and makes 0.1/s; machine 10
costs 75 billion and makes 1.6 million/s. A span of **5 × 10⁹ in cost** and
**1.6 × 10⁷ in output** across ten steps.

### Milestones
At **10, 25, 50, 100, 200, 400** units owned of one machine, a one-off purchase
appears that **doubles that machine's production**. They stack multiplicatively:
400 owned with all six bought = **64×** base rate for that machine.

---

## 3 · THE FOUR CORE UPGRADES

| Upgrade | Max lvl | Per level | Level 1 cost | Cost curve |
|---|---|---|---|---|
| **Tap Power** | 50 | +2 % Data per tap tick | 50 Data | ×1.75 |
| **Hold Rate** | 100 | +5 % tick rate while holding | 500 Data | ×1.6 |
| **Network Efficiency** | 40 | **+5 % ALL machine production** | 2 000 Data | ×2.2 |
| **Offline Efficiency** | 5 | +10 % offline rate (50 % base) | 25 000 Data | fixed: 25k · 75k · 375k · 3.75M · 75M |

- Tap Power and Hold Rate only affect the **manual tap**. Since v0.76.0 a tap is
  worth a *share of your own production* (+2 % per level), floored at 1 Data for
  the first minutes. Holding actively is worth roughly a doubling of income.
- **Network Efficiency is the only upgrade that touches passive production:**
  +5 %/level × 40 = **+200 % maximum**.

### The hold mechanic (the only active verb in the game)
Base **4 ticks/second**, a **30-second** meter. Crit chance climbs from **5 %** to
**25 %** along the meter at **×5**; the income multiplier climbs to **×2**. The meter
**stops at full** — release and press again to restart. That stop is the anti-AFK rule.

---

## 4 · THE PRODUCTION RATE FORMULA (server-authoritative)

One rate. The node, the tap and the reboot gate all read it.

```
rate = Σ( units × base_prod × 2^(milestones bought for that machine) )
       × (1 + 0.05 × NetworkEfficiency)
       × (1 + 0.02 × reputation_stars_in_the_region_you_are_standing_in)
       × (1 + gear_idle% + boost_idle% + achievement_idle%)
```

Reputation counts **only where you stand** — travel away and the bonus stays
behind. Measured: 16 313/s clean → 16 640/s with one star.

**Offline:** time away is capped by the purchased offline cap and paid at the
offline rate (50 %, +10 % per Offline Efficiency level).

**Side effect:** the tick also grants player XP at `0.06 × visible seconds ×
ring multiplier`, and rolls idle drops (junk, scrap, gear). Those two hang off
the node's clock, not off production.

---

## 5 · HELPERS — THE OTHER HALF OF WHAT A MACHINE IS

| Machine | Ability | Effect |
|---|---|---|
| Data Scrapyard | **Scrap Sense** | more scrap found |
| Expedition Beacon | **Trailblazer** | expeditions finish faster |
| Profession Grounds | **Apprentice** | faster profession XP |
| Trade Post | **Haggler** | everything sells for more |
| Fragment Collector | **Fragment Nose** | more fragments |
| Companion Trainer | **Mentor** | faster helper XP |
| Fuel Reclaimer | **Coolant Flow** | fuel regenerates faster |
| Cache Foundry | **Cache Instinct** | better cache odds |
| Gear Forge | **Prospector** | dropped gear rolls rarer |
| Genesis Core | **Echo Reader** | more Tokens on a reboot |

### The seat rarity gate
How many of a machine you must own before its seat accepts a helper of that rarity:

| Common | Uncommon | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|
| 1 | 5 | 15 | 30 | 60 | 100 |

This is the **only** reason to own more than a handful of a late machine. The
100th Genesis Core exists so that a mythic helper has somewhere to sit.

### Ability strength
Rolled once at creation from a band, times a rarity ladder **identical to gear's**:
**1 / 1.35 / 1.8 / 2.4 / 3.2 / 4.2**.

| Ability | Base band |
|---|---|
| Scrap Sense | 5 – 7 % |
| Fragment Nose | 5 – 7 % |
| Apprentice | 5 – 7 % |
| Mentor | 5 – 7 % |
| Trailblazer | 5 – 7 % |
| Haggler | 5 – 7 % |
| Coolant Flow | 5 – 7 % |
| Cache Instinct | 5 – 7 % |
| Prospector | 1.5 – 2 % |
| Echo Reader | 1 – 1.5 % |

Measured over 10 000 rolls per ability: every one lands inside its band. A mythic
Scrap Sense lands 21.00–29.38 against a computed 21.0–29.4.

### Levelling
- Max level **10**, **5 348 XP** total to reach it.
- A **seated** helper earns **15 % of your own XP**. One sitting in the list earns nothing.
- Helpers can also be fed (server-side).
- **47 species** exist, grouped in families.

---

## 6 · THE REBOOT

### Gate (both server-checked)
1. production rate **≥ 10 000 Data/s**
2. **every region in the world discovered**

### Payout
```
token_base_total = floor( (lifetime_Data / 10 000) ^ (1/3) )
payout           = (token_base_total − tokens_already_awarded)
                   × (1 + Echo Reader helper bonus %)
```
A **cube root of lifetime Data**, minus what has already been paid, so the same
Data is never paid for twice.

### What a reboot destroys
- every machine
- every core upgrade except the purchased offline cap
- every milestone except the highest `Etched Milestone` levels
- every seated helper whose rarity ≥ `Standing Orders` level
- Data, reset to `Warm Boot level × 250`

### What it keeps
Everything outside the node: gear, professions, materials, gold, regions,
reputation, auction listings, achievements, character level and paragon.

---

## 7 · THE PERK TREE — WHAT TOKENS ACTUALLY BUY

**15 perks, 6 rows, 11 563 Tokens for every level of everything.**
A row opens when **at least one level** has been bought in the row above.
Served entirely from the database; the client holds no copy, so there is no
second truth to drift.

| Row | Perk | Max | 1st cost | Growth | Effect |
|---|---|---|---|---|---|
| 1 | **Salvage Logistics** | 5 | 10 | ×1.8 | Machines cost 6 % less, per level. |
| 1 | **Warm Boot** | 5 | 12 | ×1.8 | Start each reboot with 250 Data per level. |
| 2 | **Expedition Bay** | 2 | 30 | ×3.0 | One more expedition can run at a time. |
| 2 | **Etched Milestone** | 3 | 25 | ×2.5 | Keep one milestone through a reboot. |
| 2 | **Deep Reserves** | 3 | 15 | ×1.8 | Fuel comes back 10 % faster, per level. |
| 3 | **Quick Hands** | 3 | 18 | ×1.8 | Gathering rolls come 0.5 s faster, per level. |
| 3 | **Keen Eye** | 5 | 20 | ×1.8 | Gathering finds something 2 % more often. |
| 3 | **Wreck Diver** | 5 | 15 | ×1.8 | Expeditions turn up scrap 2 % more often, per level. |
| 4 | **Cache Broker** | 4 | 15 | ×1.8 | Caches cost 1 fragment less, per level. |
| 4 | **Market Standing** | 2 | 35 | ×2.2 | Auction **sale tax** 1 point lower, per level (floor 5 %). |
| 4 | **Overflow Valve** | 1 | 25 | ×1.0 | One more boost can run at the same time. |
| 5 | **Signal Filter** | 9 | 12 | ×1.7 | Removes the cheapest remaining junk from the drop pool. |
| 6 | **Pressure Manifold** | 1 | 45 | ×1.0 | One more boost at the same time. |
| 6 | **Cascade Rig** | 1 | 70 | ×1.0 | One more boost at the same time. |
| 6 | **Standing Orders** | 6 | 20 | ×3.0 | Seated helpers survive a reboot — one rarity step per level. |

### The honest read on this tree
**Only 4 of the 15 perks touch the node itself** — Salvage Logistics, Warm Boot,
Etched Milestone, Standing Orders. The other 11 pay out in *other* systems:
gathering, expeditions, the auction house, caches, boosts, fuel. **The node is a
machine for buying upgrades to everything except the node.**

**6 of the 15 are computed only on the server** and are never read by the client:
Warm Boot, Etched Milestone, Keen Eye, Wreck Diver, Signal Filter, Standing
Orders. Verified one by one — correct, they are purely server-side effects.

---

## 8 · WHAT THE NODE IS WORTH, IN CONTEXT

| Ring | Player XP/hour | Share of it from tapping the node |
|---|---|---|
| Home | 4 440 | **81 %** |
| 1 | 4 500 | 80 % |
| 2 | 7 740 | 47 % |
| 3 | 24 960 | 14 % |
| Outer | **411 960** | **1 %** |

The node is a new player's entire game and an experienced player's rounding
error. That gap has never been closed.

### Premium: the offline cap
The only purchase attached to the node, bought with Credits:

| Offline hours | Credits |
|---|---|
| 12 h | 200 |
| 16 h | 350 |
| 20 h | 500 |
| 24 h | 750 |

---

## 9 · EVERY WIRE THAT WOULD HAVE TO BE CUT OR RE-ATTACHED

**Feeds INTO production rate**
- region reputation stars (+2 % each, only where you stand)
- gear affix `Idle Data`
- boost `Data Surge` (Data Flask, Genesis Compound)
- achievement idle % (13 achievements grant permanent idle %)
- Network Efficiency upgrade

**Feeds OUT of the node**
- player XP (0.06/s × ring multiplier)
- Tokens → the 15-perk tree → gathering, expeditions, auction, caches, boosts, fuel
- ten helper abilities, each landing in a different system
- the tap — the only active-play verb in the game
- idle drops (junk, scrap, gear) roll on the node's tick

**References machines by name**
- the seat rarity gate (owning N of a machine)
- the reboot gate (production ≥ 10 000/s)
- `machine_config` on the server and `machines` per character
- achievements that count machines owned

**Does NOT depend on the node at all**
- the whole profession and crafting economy
- gear, drops, the auction house, gold
- expeditions, travel, fuel, regions, zones
- character level 1–50 and paragon

