# MVP Design Specs and Team Plan

## 1. Decisions at a Glance

| Topic | Decision |
| --- | --- |
| MVP modes | Luksong Baka, Agawan Base, Tumbang Preso (1 map each) |
| MVP play | Single player (human) plus bots, 8-10 players per match, 3 modes per match, random order |
| Round length | 3 minutes per mode, 10 s intermission, 5 s intro |
| Build target | **Native PC build** (organizers accepted it; submission is a video). Web export is post-MVP |
| Engine | **Godot 4.7.2-stable** (pinned 2026-10-14; everyone installs this exact version), 3D, **Compatibility renderer** (keeps the later web port cheap) |
| Art | Free CC0 low-poly packs plus a few hand-made Filipino props, all tracked for the disclosure form |
| Win condition | Most total points after 3 modes. Top 3 shown on the podium |

### Correction on assets

Rule 6 does **not** ban royalty-free assets. It allows outside art if the team has the rights to use it. CC0 packs are the safest, and you list every asset in the organizers' disclosure form. So you do **not** need to model everything yourselves. Hand-make only what is uniquely Filipino and simple: the baka, the can, the tsinelas, base markers, and signage. Code is different: Rule 7 requires that game logic and core mechanics are your own.

## 2. Art Pack Decision

| Need | Recommended source | Notes |
| --- | --- | --- |
| Characters (Muck / Fall Guys feel) | Kenney animated character packs (CC0), or the animated character in Quaternius' Ultimate Platformer Pack (CC0, 18 animations) | One shared rig for all 10 players, recolored per player or team |
| Maps and props | Quaternius Ultimate Platformer Pack (modular platforms, nature, mechanics), plus Kenney kits for city or nature pieces | Same low-poly look keeps all three maps consistent |
| Filipino props | Hand-made in Blender or from Godot primitives (CSG, boxes, cylinders) | Baka cutout, can, tsinelas, base flags, sipa |
| Sound and music | Kenney audio, plus Freesound items marked CC0 | Check each license, log it |

**Pick one style (Kenney or Quaternius) as the primary and fill gaps from the other.** Mixed styles are the fastest way to look amateur. Before use, open each pack page, confirm the license, and add a row to the asset sheet (name, author, link, license, where used). Some Quaternius packs use their own license wording, so read it on the page rather than assuming CC0.

*Recommendation:* use the Quaternius Ultimate Platformer Pack as the base, since it covers a character, modular platforms, and nature in one consistent style, and add Kenney characters only if you need more player variety.

## 3. Mode Spec: Luksong Baka

**Type:** free-for-all elimination. **Players:** 8-10. **Map:** 1 (a flat field with start lines on both ends and the baka in the center).

**Setup**

- Players line up in lanes at one end, one lane per player. A single long **baka** (cardboard-style cow cutout) spans all lanes across the center like a shared hurdle. **Decided 2026-10-14:** multi-lane simultaneous waves, not single-file sequential — every alive player jumps in the same wave, so nobody waits for a turn.
- Each player auto-runs forward toward the baka. The only input is **Jump**.

**Core loop (waves)**

1. A wave starts: all alive players run toward the baka at the same time.
2. Each player must press Jump inside the **timing window** (a distance range before the baka).
3. Success: the player clears the baka and lands on the far side. Failure (too early or too late): stumble animation, the player is **eliminated** and becomes a spectator.
4. Next wave: the baka gets taller and the window shrinks. Survivors run back the other way.
5. Repeat until one player is left, or the 3-minute timer ends, or the maximum wave count is reached.

**Scoring (confirmed 2026-10-14)**

- Last player standing: **10 points**.
- If several players are alive when time runs out, the 10-point pool is split among them. If the number of survivors is odd, the pool drops to 9 first, and each survivor gets the whole-number share (leftover points are discarded). Eliminated players get 0.

| Survivors | 1 | 2 | 3 | 4 | 5 | 6+ |
| --- | --- | --- | --- | --- | --- | --- |
| Points each | 10 | 5 | 3 | 2 | 1 | 1 |

**Rules for implementation**

- Success is a **distance-window check**, not physics: when Jump is pressed, compare the distance to the baka against `[window_min, window_max]`. This makes it deterministic, easy to test, and easy for bots.
- Difficulty knobs (config file): starting height, height increase per wave, starting window size, window shrink per wave, run speed, max waves.

**Bots:** press Jump at the ideal distance plus a random error. Error grows with wave height. Per-bot skill value so not all bots die together.

**UI:** wave counter, alive counter, jump prompt, timer, big on-screen Jump button for touch later.

**Done when:** a full match of this mode runs with 1 human and 9 bots, produces a correct points table, and the winner screen shows.

## 4. Mode Spec: Agawan Base

**Type:** team vs team, 2 teams split as evenly as possible (5v5 at 10 players, 5v4 at 9, 4v4 at 8). **Map:** 1 (a rectangular field, a base at each end, a neutral middle).

**Objective:** reach the **enemy base** without being tagged.

**Scoring (as specified)**

- Team score: +1 each time a player safely reaches the enemy base.
- **First team to 3 points wins**, or the team with **more points when the 3-minute timer ends**.
- Player points (final normalized scale, see Section 7): every member of the winning team gets **6**, the team's **MVP gets 8**, losing-team members get **2**. MVP = most team points contributed (base reaches, then rescues, then fewest tags, then random via MatchManager RNG).

**Priority rule (the core mechanic)**

- Every player has an `exit_time`, set when they leave their own base zone and cleared when they re-enter it.
- A tag is valid only if the tagger is outside a base and `tagger.exit_time > target.exit_time` (the tagger left **later**).
- The target must also be outside a base. Players inside their base cannot be tagged.
- Re-entering your base and leaving again gives you a **new, later** `exit_time`, which restores your priority over those who left earlier.

**Match state machine**

| State | What happens |
| --- | --- |
| `PLAYING` | Normal movement, tagging, rescuing, base reaching |
| `TAG_PAUSE` | A valid tag freezes the match. The tagged player moves to the **jail spot** (a set distance from the opposing base). All other players run back to their own bases (short countdown) |
| `RESCUE_PAUSE` | A teammate touches a jailed player: **all** jailed teammates are freed, the match pauses, and everyone returns to their bases |
| `SCORE_PAUSE` | A base is reached: +1 team score, everyone returns to bases (**confirmed 2026-10-14**: base reaches reset the field, same as tags and rescues) |
| `ENDED` | A team hits 3, or the timer ends. Higher score wins. If tied: next point wins (sudden death) |

- Jailed players cannot move and cannot be tagged again.
- Choice per team: **go rescue**, or **go for the win** by attacking the enemy base.

**Bots (keep it small):** each bot picks one role each cycle:

- **Attacker:** leaves base when it is safe and heads for the enemy base.
- **Hunter:** leaves *later* than visible enemies and chases whoever has an earlier `exit_time`.
- **Rescuer:** heads for the jail spot when a teammate is jailed and the path is safe. Bots only compare `exit_time` values, so the AI stays simple.

**Camera:** high third-person or near top-down so the whole field is readable.

**Risk:** this is the hardest of the three modes. Start it early (Day 3) and give it a dedicated owner.

**Done when:** a full match runs with 1 human and 9 bots, the priority rule works, jail and rescue work, and either win condition ends the match correctly.

## 5. Mode Spec: Tumbang Preso

**Type:** free-for-all with a rotating **Taya** (the guard). **Confirmed 2026-10-15:** FFA, not teams. **Players:** 8-10. **Map:** 1 (a flat court with a can in a ring at one end and a throw line some distance away).

**Roles**

- **Taya (1 player):** guards the can.
- **Throwers (everyone else):** each holds one **tsinelas** (slipper) and stands behind the throw line (the safe zone).

**Core loop**

1. Throwers throw their tsinelas at the can from the throw line.
2. **Hit:** the can falls. The thrower scores. The Taya must now walk to the can and **set it upright** (hold Action for about 2 seconds).
3. While the Taya resets the can, throwers run out, **retrieve their tsinelas**, and return to the throw line.
4. **After the can is upright**, the Taya can tag any thrower who is still **outside the safe zone**.
5. A tagged thrower **becomes the new Taya**. The old Taya returns to the throw line with a fresh tsinelas.
6. Repeat until the timer ends.

**Throwing**

- Aim: auto-aim assist toward the can. The player chooses the moment with a short power or timing bar (tap or hold-release).
- Hit check: the throw is accurate if the timing and aim error is inside a tolerance radius. Everything else is a scripted arc, not real physics, for speed and reliability.
- A thrown tsinelas lands on the ground (a hit or a miss) and **must be picked up** before throwing again.

**Scoring (final, tunable in config)**

| Action | Points |
| --- | --- |
| Knock down the can (can was upright) | +2 |
| Tag a thrower as Taya | +3 |
| Taya rotates by timeout (see below) | 0 |

- Players are ranked by score at the timer. The mode returns **placement results** and the ScoreManager applies the placement table (see Section 7). Tiebreak: less time spent as Taya.

**Anti-stall rules**

- If the Taya tags nobody for **45 seconds**, the role rotates to a random thrower.
- Throwers cannot throw from outside the throw line.

**Bots**

- *Thrower:* waits at the line, throws with a difficulty-based error, retrieves the tsinelas when the Taya is far or the can is down.
- *Taya:* resets the can, then chases the nearest exposed thrower.

**Done when:** a full match runs with 1 human and 9 bots, Taya rotation works, scoring works, and the ranked results are returned to the match manager.

## 6. Team of 5: Roles

You are the team lead. This split is my suggestion. Swap it around based on who is strongest at what.

| # | Role | Owns |
| --- | --- | --- |
| 1 | **Team Lead** | Architecture, MatchManager, ScoreManager, menu and flow, repo and merges, AI-disclosure log, final submission and form. |
| 2 | **Gameplay Dev A** | Player controller, camera, input abstraction, **Luksong Baka** |
| 3 | **Gameplay Dev B** | **Agawan Base** (priority rule, state machine, jail and rescue, bots). The hardest mode, so it gets one dedicated person |
| 4 | **Gameplay Dev C** | **Tumbang Preso** (throwing, can, Taya rotation, bots) and the shared `BotBase` |
| 5 | **Art, UI and Audio** | Asset pipeline and license sheet, character setup and recolors, hand-made Filipino props, three maps, HUD and menus, sound, demo video editing |

**Shared duties:** everyone writes their own mode's bot, logs AI use as they go, and tests a full match on a real build every day from Day 5.

## 7. Scoring Normalization (final — adopted 2026-10-14)

The original specs produced different scales: Luksong Baka awarded up to **10** while Agawan Base awarded **2-3**, so Luksong Baka would have dominated the final standings. Every mode now plays for roughly a 10-point top prize, so no single mode decides the match:

- **Placement modes** (Tumbang Preso): 1st = 10, 2nd = 7, 3rd = 5, 4th = 4, 5th = 3, 6th = 2, others = 1.
- **Direct-points modes** (Luksong Baka): table in Section 3, already on a 10-point scale (elimination scores 0, so it stays high-risk, high-reward by design).
- **Team modes** (Agawan Base): winning-team members **6**, MVP **8**, losing-team members **2**.

Match winner is the highest total across all 3 modes. Tiebreak: best single-round result, then random (MatchManager RNG).

## 8. 10-Day Plan

| Day | Goal |
| --- | --- |
| 1 | Lock specs and the architecture doc, repo, folders, Godot version, input abstraction, character imported and moving |
| 2 | MatchManager state machine, ScoreManager, menu to match flow with a placeholder mode, BotBase |
| 3 | Luksong Baka and Tumbang Preso core loops; Agawan Base field, bases, and priority rule |
| 4 | All three modes playable with basic bots |
| 5 | Maps dressed with art, HUD per mode, scoring wired, intermission and podium screens |
| 6 | Bot tuning, game feel (camera, hit feedback, sounds), first full 3-mode match end to end |
| 7 | Bug-fixing and balance, optional extra polish, **feature freeze at end of day** |
| 8 | Bug fixes only, full playthrough testing, asset and AI disclosure sheets filled in |
| 9 | **Demo-ready build.** Rehearse the flow, record test footage |
| 10 | Final polish, record and edit the demo video, fill in the disclosure form, submit |

**Cut order if behind:** polish effects first, then dressing detail on maps, then a mode's bot sophistication. Never cut the full menu-to-podium flow.