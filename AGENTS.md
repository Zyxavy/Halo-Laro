# Instructions for AI coding agents 

This is a Godot 4.7.2 (GDScript, 3D, Compatibility renderer) project for a competition with strict rules.

## Hard rules
1. **Originality (competition Rule 7):** game logic, mechanics and source code must be the team's own.
   Do not paste code from tutorials, templates or open-source projects that implement core mechanics
   (movement, scoring, bots, mode rules). Explain your approach instead of copying known implementations.
2. **Disclosure (Rule 8):** every AI-assisted change must be logged. After finishing a task, append a row to
   `docs/AI_USAGE_LOG.md` (date, tool/model, what it was used for, files touched) and put
   `AI-assisted:` in the commit message.
3. **Assets (Rule 6):** never add art/audio without a row in `assets/LICENSES.md`
   (name, author, link, license, used in). No unlicensed or unknown-source assets.

## Architecture rules
- Modes are plugins: each mode lives only in `modes/<mode>/` and extends `GameMode`.
  Do not edit `core/` or `autoload/` unless the task says so; ask the team lead instead.
- A mode returns a `ModeResult` (`placement`, `points` or `team`). It never touches the UI or ScoreManager directly.
- Humans and bots use the same `InputProvider` struct. One movement input and at most two actions.
- No magic numbers: tunables go in `data/config.json` or the mode's config dictionary.
- Keep it web-ready: Compatibility renderer only, low-poly assets, no GDExtensions or thread-dependent code.

## Style
- Typed GDScript, `snake_case` functions/variables, `PascalCase` classes, `UPPER_SNAKE` constants.
- One scene, one owner: avoid editing `.tscn` files owned by someone else.
- Small commits; `main` must always launch.
