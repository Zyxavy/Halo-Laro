# AGENTS.md: Halo-Laro (Philippine Games Randomizer)

> Greenfield repo: `README.md` + `docs/` only, no code yet. `docs/Technical-Architecture.md` is the build blueprint; `docs/Design-Spec.md` defines the 3 MVP modes; `docs/PRD.md` is older and partly superseded (see scope note).

## Scope (MVP: Design-Spec wins over PRD)
- 3 modes, 1 map each: `luksong_baka` (FFA elimination), `agawan_base` (team, priority-rule tag), `tumbang_preso` (FFA + rotating Taya). PRD's Patintero/Sipa/4-modes/2-maps are post-MVP.
- Match: Quick Match only (Browse Server = disabled "Coming Soon"), fake 2–3 s finding screen, human + bots to 8–10 players, 3 distinct modes drawn once per match, 5 s intro / 180 s round / 10 s intermission / podium top 3.
- Target: Godot 4.x native Windows build recorded for video submission. Web/mobile is post-MVP but code must stay web-ready (Compatibility renderer, Sec. 12 of arch doc).
- No verified build/test/lint commands exist yet. Run/verify in the Godot editor with the team's pinned version; exported-build check on a non-dev machine before recording.

## Scaffold per arch doc §3 (when creating code)
- `res://autoload/` (Game, Config, Events, AudioBus), `core/match|scoring|input|bots`, `characters/`, `modes/<mode>/`, `ui/`, `data/config.json|modes.json|bot_names.json`, `assets/.../LICENSES.md`, `tools/`.
- Godot **4.7.2-stable** for everyone (pinned 2026-10-14; latest stable 4.x — 4.8 is still in dev).

## Invariants (do not break)
- Modes are plugins: new mode = new folder under `modes/` + one `modes.json` entry. Never import across mode folders; shared changes go through `core/`/`autoload/` (team-lead owned).
- `GameMode` contract: `setup(players, map, config)`, `start()`, `tick(delta)`, `get_hud_data()`, `force_end()`, `teardown()`, `finished(ModeResult)` signal. Scoring reads only `ModeResult` (`placement`/`points`/`team`); mode code never touches totals.
- Same `InputProvider` struct (`move: Vector2`, `action_a/b`) for human and bot; one movement + max two actions per mode (touch feasibility).
- Deterministic rules over physics (distance windows, zones, timers); physics for feel only. One RNG owned by MatchManager, seeded per match and shown in debug overlay.
- Modes never call UI directly — expose `get_hud_data()` + signals; global `Events` autoload only for cross-cutting events.
- No tunables in scripts: lobby size, timers, points tables, bot skill, per-mode difficulty live in `data/config.json` / mode config dicts.
- Scoring is final (`data/config.json`): `placement_points [10,7,5,4,3,2,1]`, team `win 6 / MVP 8 / loss 2`, `round 180s / intermission 10s / intro 5s`. Locked 2026-10-14: Luksong runs multi-lane simultaneous waves with odd-survivor pool dropping to 9; Agawan base-reach resets the field and teams split evenly. Agawan Base `exit_time` priority rule and Tumbang Preso anti-stall (45 s Taya rotation) are spec'd in Design-Spec §§4–5 — implement as written.

## Conventions
- GDScript, typed signatures; `PascalCase.gd` classes, `snake_case` vars/funcs, `UPPER_SNAKE` consts. Compatibility renderer, low-poly, one directional light, no GDExtension/thread-dependent code, audio only after first input.
- Git: `main` always runnable, `feature/<area>-<name>`, merge daily, one owner per scene. Commits state what changed + mark `AI-assisted` where true (organizer disclosure requirement).
- Every asset row logged in `assets/LICENSES.md` (name, author, link, license, used-in); CC0 preferred, hand-make only Filipino-specific props. Core mechanics must be team-written (no copied tutorials/templates).
- Dev tools to build alongside: debug overlay (FPS/seed/state/points), bot-only autoplay full match, per-mode debug launcher, config hot-reload.

## Open / undecided (check before assuming)
- Design-Spec §9 + PRD §11: title, team split, disclosure-form format, Agawan Base team sizes / base-reach reset, Tumbang Preso FFA-vs-teams, Luksong Baka survivor-split + baka prop shape.
- Cut order if behind: polish → map dressing → bot sophistication. Never cut menu-to-podium flow or mobile-ready input abstraction.
