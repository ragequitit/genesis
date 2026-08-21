# GENESIS — THE CHARACTER, AS BUILT (and what a class system would land on)

> Measured out of the running game file and the live server on 2026-08-21, at
> version **v4.68.0**.
>
> **Part 1 describes what exists today.** Part 2 is a map of the empty space —
> what a class system, a skill tree, PvE, quests and events would attach to, and
> what already stands in the way. Part 2 contains no decisions, only the shape
> of the problem as it is measurable today.

---
---

# PART 1 — WHAT THE CHARACTER IS TODAY

## 1 · THE LEVEL CURVE

```
XP to next level = 607 × 1.0845 ^ (level − 1)
Level cap        = 50
Total to 50      = 375 275 XP  ≈ 36 hours of active play
```

One exponential formula, not a polynomial. It replaced `100 × level^1.5`, which
got **faster** the higher you climbed — measured, level 11–20 took eleven hours
and level 41–50 took forty minutes. The current curve rises the whole way:

| Band | XP | Share of the whole climb |
|---|---|---|
| 1–10 | 8 985 | 2 % |
| 11–20 | 20 219 | 5 % |
| 21–30 | 45 502 | 12 % |
| 31–40 | 102 409 | 27 % |
| 41–50 | **198 160** | **53 %** |

**Half the journey to 50 is the last ten levels.** Client and server compute this
identically, band for band.

### Where XP comes from
| Source | Formula |
|---|---|
| Idle production | `0.06 × visible seconds × ring multiplier` |
| Expeditions | `48 × 1.8^ring × minutes^0.55` |
| Arriving in a new region | `100 × ring multiplier` (first visit only) |
| Completing a survey | `50 × ring multiplier` |
| Gear affix `Experience` | +3.46–4.54 % per roll |
| Learning Flask | +20/30/45/70 % while active |

The **ring multiplier is 1.8 per ring**, so the outer ring pays 1.8⁴ ≈ **10.5×**
what home pays for the same act.

## 2 · PARAGON

```
cost of paragon step n = 1890 × 1.03 ^ (n − 1)
reward per step        = 10 Tokens
```

The first step costs about what level 15→16 costs. **Paragon gives no power —
only Tokens.** The reasoning is written in the code and is worth keeping in view
for any PvE plan: *if paragon gives power, all PvE must be balanced against
paragon 800 instead of against level 50.*

## 3 · WHAT A CHARACTER ACTUALLY HAS

### Stats — there are only four, and three are visible
```
HP     = 100 + Σ(gear hp)
Power  = Σ(gear power)
Damage = Σ(gear damage)          — weapons and off-hands only
Hit    = Damage × Power / 100    — computed, hidden, waiting for PvE
```
**`Hit` already exists in the code and is deliberately not shown.** It is the one
stat built for combat that has never had combat to be used in.

There is **no strength/agility/intellect layer**, no resistances, no armour
value, no attack speed, no cooldowns. A character is: a level, four numbers, and
fourteen equipment slots.

### The fourteen slots
| Slot | Slot | Slot | Slot |
|---|---|---|---|
| Head | Chest | Legs | Gloves |
| Feet | Weapon | Neck | Waist |
| Ring | Ring (2nd finger) | Off Hand | Bag |
| Transport | Relic | | |

### The rarity ladder — one ladder, used everywhere
| | Common | Uncommon | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|---|
| Stat multiplier | 1 | 1.35 | 1.8 | 2.4 | 3.2 | 4.2 |
| Affixes rolled | 1 | 1 | 2 | 2 | 3 | 3 |

The **same** ladder governs gear stats, helper ability strength and crafting kit
cost. Gear scales with the level it dropped at (`+10 % per level above 1`,
locked at 50) and **never grows afterwards**.

### The thirteen affixes — the entire power vocabulary

| Affix | Band per roll | What it feeds |
|---|---|---|
| Idle Data | 1.73 – 2.27 % | production rate |
| Tap Power | 2.03 – 2.67 % | the manual tap |
| Crit Chance | 1.3 – 1.7 % | tap crits |
| Crit Damage | 2.58 – 3.42 % | tap crit multiplier |
| Fragment Find | 1.9 – 2.5 % | fragment drops |
| Loot Luck | 1.64 – 2.16 % | all drop chances |
| Experience | 3.46 – 4.54 % | player XP |
| Offline Earnings | 2.38 – 3.12 % | offline rate |
| Pet XP | 4.3 – 5.7 % | helper XP |
| Expedition Speed | 2.58 – 3.42 % | expedition length |
| Boost Strength | 3.44 – 4.56 % | boost strength |
| Boost Duration | 3.44 – 4.56 % | boost duration |
| Travel Speed | 7 – 9 % | — |

**Read that list carefully: not one affix touches combat.** Every single one
feeds an economy or an idle rate. There is no damage %, no crit for anything but
the tap, no defence, no healing, no resource. The affix pool is a *rate card*,
not a combat kit.

Three affixes are **jewellery-exclusive** (Crit Damage, Expedition Speed, Boost
Duration) and cannot appear on body pieces. That exclusivity is what makes
those slots worth hunting.

### Gear Tuning
Opens at **level 25**. Rerolls the *strength* of one affix; the type never moves
and the sell value never moves. **Max 5 attempts per piece**, price **+75 % per
attempt**, first attempt 5/10/25/60/140/300 gold by rarity. Five attempts on a
mythic costs **6 165 gold** — nearly a day's income. The choice between the old
and new roll is final.

## 4 · EVERY LEVEL GATE IN THE GAME TODAY

| Level | What opens |
|---|---|
| 1 | first helper team slot |
| 5 | uncommon profession recipes |
| 7 | second helper team slot |
| 10 | rare profession recipes |
| 12 | third helper team slot |
| 16 | epic profession recipes |
| **25** | **Gear Tuning** |
| 50 | level cap; paragon begins |

**Eight gates across fifty levels, and five of them are in the first twelve.**
Between level 25 and level 50 — which is 78 % of the total XP — **nothing opens
at all.** The back half of the curve is currently a number that grows and
nothing else.

## 5 · THE OTHER CHARACTER-SHAPED SYSTEMS

### Helpers (pets)
Three team slots at levels 1, 7 and 12. 47 species. Max level 10, 5 348 XP.
A seated helper earns 15 % of your XP. Ten abilities, one per production —
**all ten are economy modifiers, none is combat.**

### Reputation
Per region, earned by **time spent standing there**: 1 h · 6 h · 24 h · 72 h ·
168 h = five stars. Each star is **+2 % production**, and only where you stand.
Reputation also lowers vendor prices.

### Achievements — 40, in seven groups
| Group | Count |
|---|---|
| Expeditions | 6 |
| First steps | 5 |
| Gear | 8 |
| Machines | 6 |
| Money | 5 |
| Standing | 4 |
| The world | 6 |

Rewards: **14 pay gold (36 g total), 13 pay silver (8 g total), and 13 grant
permanent idle %** — 23 percentage points in total. Those thirteen are the only
permanent character power in the game that is not gear.

### Fuel, travel and boosts
Fuel is the travel resource: 100 max, regenerating every tick. A trip costs the
sum of the ring steps (15/20/25/35), so crossing the whole world is 95 —
almost a full tank. Boosts are the flask effects; the number that can run at
once is raised by three perks.

---
---

# PART 2 — THE EMPTY SPACE

*What classes, a skill tree, PvE, quests and events would land on. No decisions
here — only what is measurably true today.*

## 6 · A SKILL TREE FOR LEVELS 1–50

The plan is that all fifty levels feed a tree and that the player cannot have
everything. Four things about the ground it would be built on:

**The curve is back-loaded, and a tree would fix a real problem.** 53 % of the XP
to 50 sits in the last ten levels, and today those ten levels open **nothing**.
A tree is the natural thing to hang there.

**But points-per-level and the curve fight each other.** One point per level means
the first ten levels (2 % of the XP) hand out 20 % of the tree, and the last ten
(53 % of the XP) hand out another 20 %. Either the points are weighted, or the
early tree has to be deliberately weak.

**There is already a tree, and it is a good model.** The reboot perk tree is 15
nodes in 6 rows with a one-level-per-row unlock rule, served entirely from the
database with no client copy. If the reboot goes away, that tree's *shape* is
reusable even though its contents are not.

**The vocabulary problem is the real one.** A skill tree needs things to modify.
Today the only modifiable quantities are the thirteen affixes, and every one of
them is an economy rate. A tree built on today's vocabulary would be fifty
levels of *+2 % gathering speed*. **Classes and combat are what would give a
tree something to say.**

## 7 · FOUR TO SIX CLASSES AT CHARACTER CREATION

### What already supports it
- The account/character split is built. An account holds many characters under
  one unique handle; character names may collide, handles never do. A class
  chosen at creation fits that shape with no structural change.
- `Hit = Damage × Power / 100` exists and is unused — a combat stat waiting.
- Six gear sets from five different fictional worlds already exist, deliberately
  in five clashing art styles. If classes want visual identity, it is drawn.

### What stands in the way
**Nothing in the game is class-shaped yet.** Concretely:
- **No gear is restricted.** Any character can wear any of the 109 items. Six
  weapon types exist (Dagger, Wrench, Beam Rifle, Wand, Greatsword, Hammer) and
  they are cosmetic — a Greatsword and a Wand differ only in art and numbers.
- **No affix is class-flavoured.** All thirteen are universal rates.
- **The drop table picks a slot first, then any item for that slot.** If classes
  restrict gear, that lottery starts handing out unusable drops — the same
  disease that makes loot feel bad in most games. It is a one-line change and a
  large balance consequence.
- **Professions are unrestricted and cost gold to learn.** If classes gate
  professions, the gold ladder (×5 per profession known) has to be rethought.
- **The six weapon types are one per gear set, not one per role.** A set covers
  a rarity band, so a class locked to Greatswords is locked to Voidsteel, which
  is Epic–Mythic only. Weapon type and rarity band are currently the same axis.

### The honest size of it
Classes are cheap to *add* (a column on the character) and expensive to *mean
something*. Meaning requires at minimum: class-restricted or class-weighted
gear, a combat-shaped affix vocabulary, and a drop table that knows who is
playing. None of those three exist.

## 8 · PvE

### What is already built for it and unused
- `Hit` — computed on every character, shown nowhere.
- `Damage` — rolls on weapons and off-hands only, and is displayed, but nothing
  consumes it.
- `HP` — 100 base plus gear, displayed as a full bar that never moves.
- **Zone designations** exist, including PvP-marked zones on the map, with no
  combat behind them.
- The world rebuild plan already has **one dungeon per world at the top of each
  level band** (10, 20, 30, 40, 50) — the encounter slots are designed, not built.

### What is missing
Everything else. No enemies, no combat loop, no threat, no death, no rewards
table, no cooldowns, no abilities. **PvE is not partially built; it is three
stats and a stage direction.**

### The one balance rule already decided
Paragon gives Tokens, never power, **specifically so that PvE can be balanced
against level 50 instead of against an unbounded paragon number.** That decision
is already load-bearing and should not be quietly reversed.

## 9 · QUESTS

### Nearest thing that exists
**Expeditions** are the closest mechanic: pick a duration (2–120 min), send,
wait, claim. They pay gold, XP, fragments, scrap, and roll for gear, relics,
schematics, a fuel cell and a melon. They are **timers, not tasks** — the player
makes one decision (which one, how long) and then waits.

**Achievements** are the closest thing to a goal list: 40 of them, all
retroactive counters (*reach X*, *own Y*), none directed, none narrative.

### What a quest system would need that does not exist
- any notion of a *task with a state* (offered / accepted / in progress / done)
- any giver, anywhere in the world
- any way to require the player to *go somewhere and do something*, since travel
  is instant-on-arrival and zones contain expeditions and nothing else
- a reward channel that is not gold/XP/gear — otherwise quests are expeditions
  with text on them

## 10 · EVENTS

### What exists
A nav button labelled **Events** with a hardcoded countdown (`2d 14h`) and
nothing behind it. That is the entire implementation.

### What the game already has that events could use
- **`SERVER_MODS`** — a deliberately empty hook, `{serverId: {materialKey:
  multiplier}}`, already read by the gathering roll. The day a world wants
  different material odds, only that table needs filling. **This is the one piece
  of event scaffolding that was built on purpose and left empty.**
- Region reputation, which is already time-based and per-region
- The mailbox, which can deliver items and is already server-side
- Boosts, which are already timed, stackable and server-tracked

### What is missing
Any concept of *time-limited* anything. No schedule, no start/end, no
event-scoped currency, no leaderboard. The boost system is the only timed thing
in the game and it is per-player, not global.

---

## 11 · THE FIVE THINGS MOST LIKELY TO BREAK

*Written from the bug families this project keeps producing.*

1. **Anything server-authoritative that the screen does not redraw.** Every
   system that reads server data must go through the shared redraw. This has
   caused more bugs here than every other cause combined.
2. **Two functions with the same name and different arguments.** `create or
   replace` does not replace a function with a different signature — it makes a
   second one, and which answers depends on the call.
3. **A dead number that looks alive.** A column or constant nobody reads but
   which says something false. Found three times in one sweep.
4. **The ledger's allowed-reason list.** Every new gold sink must add its reason
   or the call fails deep inside and the player only sees *The server said no*.
5. **Client and server drifting apart.** Every shared rule should be checksummed
   across both sides. It has caught real bugs three times.

