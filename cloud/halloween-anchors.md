# Ankarstrangar for cloud/halloween-server.sql

`event_patch_fn` laser serverns nuvarande kod (`pg_get_functiondef`), kraver att ankaret finns EXAKT en gang, byter ut det och skriver tillbaka. Markoren (sista argumentet) gor att en andra korning hoppar over kroken. Ankarna ar valda sa att de finns BADE i serverns kod 2026-10-29 och i sockets-grenens version (sockets-raderna rors inte). Hittar patchen 0 eller fler an 1 traff stannar filen med ett tydligt fel — da har funktionen andrats; byt ankare i SQL-filen.

### pve_fight (uuid, uuid)

| Ankare | Blir |
|---|---|
| `  v_tier integer; v_credits integer := 0; v_em numeric := 1;` | + `v_evm jsonb := null;` |
| `    v_scrap_qty := round(coalesce(public.pve_val('scrap_qty'), 0)` | `event_mark_drop(p_character, 'encounter', v_tier, 0, true)` fore |
| `'schematic', v_sch_got` | `'event_marks', v_evm,` fore |

### claim_expedition (uuid, text)

| Ankare | Blir |
|---|---|
| `  v_shard text; v_shard_got text := null; v_first_clear boolean; v_lap json;` | + `v_evm jsonb := null;` |
| `  if jsonb_array_length(v_mailed) > 0 then` | `event_mark_drop(p_character, 'expedition', v_tier, v_def.mins, true)` fore |
| `'relic', v_relic, 'recipe', v_rec, 'melon', v_melon,` | + `'event_marks', v_evm,` |

### pve_dungeon_claim (uuid)

| Ankare | Blir |
|---|---|
| `  v_klar boolean := false; v_charms jsonb := '[]'::jsonb; v_ck text;` | + `v_evm jsonb := null;` |
| `  update public.pve_dungeon_runs set state = 'claimed', claimed_at = now(),` | `if v_klar then event_mark_drop(p_character, 'dungeon', v_sch_tier, 0, true)` fore |
| `'schematic', v_sch_got,` | + `'event_marks', v_evm,` |

### wb_reward (bigint)

| Ankare | Blir |
|---|---|
| `v_got_charm boolean; v_got_apex boolean;` | + `v_evm jsonb := null;` |
| `    if v_dead then v_items := v_items \|\| jsonb_build_array(jsonb_build_object('stack_key', 'boss_mark', 'kind', 'item', 'qty', 1)); end if;` | + `event_mark_drop(v_h.character_id, 'worldboss', world_tier(...), 0, false)` och marken i `v_items` (brevet) |
| `              \|\| (case when v_paper is not null then ' A schematic is in the box.' else '' end)` | + raden "5 Jack-o'-Marks in the box." |
| `'apex', v_got_apex,` | + `'event_marks', v_evm,` |

Svaren (`event_marks`) ar null eller `{"event","key","qty","name","plural","art","mailed"}`; klienten ritar ett beloningskort av det.
