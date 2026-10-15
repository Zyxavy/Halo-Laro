# PRD: Halo-Laro

> Partly superseded: for MVP scope, `docs/Design-Spec.md` (3 modes, native PC build) and `docs/Technical-Architecture.md` win over this doc (4 modes, web build).

*DOST Game Dev Competition entry. Theme: Philippine Games and Sports. Timeline: 10 days. Status: Draft v0.1*

## 1. Overview

A fast-paced party game where players are dropped into a lobby of 8-10 players and play **3 randomly chosen Filipino traditional-game modes** back to back, each on a random map. Points accumulate across modes, and the top 3 players are crowned at the end.

**Pitch:** *Fall Guys-style random minigames, powered by laro ng lahi.*

## 2. Goals and Non-Goals

**Goals (MVP)**

- A complete, playable loop from main menu to podium and back, with no dead ends.
- 4 polished 3D modes, 1-2 maps each, playable on phone and PC from a browser link (the game must be 3D).
- 8-10 player lobbies filled with bots (PVE) so the demo works anytime.
- Architecture that lets us add modes, maps, and real multiplayer later without rewrites.

**Non-goals (MVP)**

- Real-time online multiplayer, accounts, friends, chat, cosmetics, or monetization.
- Browse Server (shown as *Coming Soon*).
- More than 4 modes or 2 maps per mode.

## 3. Platform and Constraints

| Item | Decision |
| --- | --- |
| Targets | Mobile browser and PC/laptop browser |
| Engine (proposed) | Godot 4 (3D, low-poly), Web export, hosted on itch.io as a prototype |
| Cost | Free tools only (competition rule) |
| Art/audio | Original or engine-bundled only |
| Code | Written by the team; no tutorial or template for core mechanics |
| AI use | Allowed, but must be disclosed and logged |

## 4. Core Game Flow

1. **Main Menu** with *Quick Match*, *Browse Server* (disabled, "Coming Soon" tag), and Settings/How to Play.
2. **Quick Match:** short "finding server" screen (2-3 s), then the lobby is filled to 8-10 players with the human player plus bots.
3. **Match start:** the game draws **3 distinct modes** from the pool of 4, and a **random map** for each.
4. **Per mode:** 5 s intro (mode name and one-line rules), then the round (default 3 min, configurable up to 5), then a results card.
5. **Intermission:** 10 s scoreboard between modes, with a preview of the next mode.
6. **Final results:** podium for 1st, 2nd, and 3rd, plus full standings.
7. **Return to Main Menu** via button, with auto-redirect after 15 s.

## 5. Functional Requirements

### 5.1 Menu and Matchmaking

- FR-1: Quick Match is the only enabled option. Browse Server is visible but non-interactive, with a *Coming Soon* tag.
- FR-2: Matchmaking is simulated locally for the MVP. It hides behind a `MatchService` interface so a real backend can replace it later.
- FR-3: Lobby size is configurable (default 8, range 8-12). Empty slots are filled with bots with Filipino-style names.

### 5.2 Match Manager

- FR-4: A state machine runs the match: `Lobby > ModeIntro > Playing > RoundResults > Intermission > ... > FinalResults > Menu`.
- FR-5: Modes are drawn randomly without repeats within a match. Each mode picks a random map from its map list.
- FR-6: A 10 s intermission runs between modes, and the timer is visible.

### 5.3 Scoring

- FR-7: Every mode must return a **ranked result list** (individual placement or team win/loss).
- FR-8: Placement points per round (tunable): 1st = 10, 2nd = 7, 3rd = 5, 4th = 4, 5th = 3, 6th = 2, others = 1.
- FR-9: In team modes, every member of the winning team gets 10 points and the losing team gets 3.
- FR-10: Match winner is the highest total. Tiebreak: best single-round placement, then random.

### 5.4 Controls

- FR-11: Desktop uses keyboard (WASD/arrows plus 1-2 action keys). Mobile uses a virtual joystick and 1-2 on-screen buttons.
- FR-12: Every mode must be playable with a maximum of one movement input and two actions.

### 5.5 Bots

- FR-13: Bots use simple state-based AI per mode (chase, dodge, jump on timing, kick).
- FR-14: Bot difficulty is exposed as one tunable value (reaction time and accuracy) so the demo is winnable but not trivial.

## 6. Game Modes (MVP)

| Mode | Type | Objective | Win condition | Maps |
| --- | --- | --- | --- | --- |
| **Tumbang Preso** | Team (2 teams) | Throwers knock down the can with a slipper while the Taya guards it and tags slipper-retrievers. | Most can knockdowns by time limit. | 1-2 |
| **Patintero** | Team (2 teams) | Runners cross a grid of lines past taggers without being tagged. | Most successful crossings, with teams swapping roles halfway. | 1-2 |
| **Luksong Baka** | Free-for-all | Time a jump over an obstacle that gets higher each round. | Last player standing, or highest cleared height at the time limit. | 1-2 |
| **Sipa** | Free-for-all | Keep the sipa in the air with timed kicks and build combos. | Highest combo/score at the time limit. | 1-2 |

*Design rule: each mode is a self-contained scene implementing the same interface (see Section 7), so a new mode never touches the match or scoring code.*

## 7. Technical Approach (Scalable by Design)

- **GameMode base interface:** `setup(players, map)`, `start()`, `update(dt)`, `is_finished()`, `get_results()`.
- **MatchManager:** owns the state machine, mode draw, intermissions, and score totals.
- **ScoreManager:** converts mode results to points using the tables above (data-driven).
- **BotController:** per-mode behavior scripts sharing a common base.
- **MapLoader:** maps are scenes registered in a data file (`modes.json` or Godot resources), so adding a map means adding a scene and one entry.
- **NetworkAdapter (future):** a `LocalAdapter` runs the MVP. A later `WebSocketAdapter` (FastAPI or Supabase Realtime) can swap in for real multiplayer and Browse Server without changing game logic.
- **Data-driven config:** lobby size, round length, points tables, and bot difficulty live in one config file for quick iteration.

## 8. Competition Compliance Checklist

- [ ] Fits the *Philippine Games and Sports* theme.
- [ ] Winner is determined at the end of every round and match.
- [ ] Playable in a browser and on mobile with no purchase needed.
- [ ] Not published on commercial stores. Uploaded to itch.io as a prototype only.
- [ ] All art and audio original or engine-bundled. No unlicensed assets.
- [ ] Core mechanics written by the team, with no copied tutorials or templates.
- [ ] AI usage disclosed, with a prompt and commit log kept.
- [ ] No content that is offensive or discriminatory.

## 9. 10-Day Plan

| Day | Focus | Output |
| --- | --- | --- |
| 1 | Finalize PRD, set up repo and engine, art style and control scheme | Project skeleton, shared HUD, input working on PC and phone |
| 2 | Menu, Quick Match flow, MatchManager, ScoreManager, bot base | Full loop running with a placeholder mode |
| 3 | Mode 1 (Luksong Baka) and Mode 2 (Sipa), the simpler solo-style modes | 2 playable modes, 1 map each |
| 4 | Mode 3 (Tumbang Preso) and Mode 4 (Patintero), the team modes | 4 playable modes |
| 5 | Second maps, bot tuning, intermission and results/podium screens | Feature-complete |
| 6 | Mobile testing, balance, bug fixes, sound, polish | Release candidate |
| 7 | Full playthrough testing, disclosure sheets, **feature freeze** | Verified build |
| 8 | Bug fixes only, demo rehearsal, test footage | Demo-ready build |
| 9 | Record and edit the demo video | Draft video |
| 10 | itch.io build, demo script, AI disclosure doc, submission | Submitted |

**Cut order if behind schedule:** second maps, then Patintero, then polish effects. Never cut the full flow or mobile controls.

## 9.1 Risks

| Risk | Mitigation |
| --- | --- |
| Team modes (Tumbang Preso, Patintero) are the hardest to build | Build them after the solo-style modes, with simplified rules and strong bot AI. |
| Mobile controls feel bad | Test on a real phone from Day 1. |
| Web export performance | Keep it low-poly 3D, with small assets, simple lighting, and few particles. |
| Scope creep | Anything not in Section 2 goals goes to the post-MVP backlog. |

## 10. Post-MVP Backlog

Browse Server and real multiplayer, more modes (Agawan Base, Piko, Taguan), more maps, cosmetics, ranked leaderboards (a good fit for a Supabase backend), and a solo score-attack mode.
