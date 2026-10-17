# Halo-Laro

DOST Game Dev Competition entry. A low-poly 3D party game: 3 random Filipino traditional-game
modes per match (Luksong Baka, Agawan Base, Tumbang Preso), single player vs bots for the MVP.

- Engine: **Godot 4.7.2-stable** (standard build, GDScript). Everyone uses this exact version.
- Renderer: Compatibility (keeps the later web port cheap).
- Target: native Windows build for the MVP.

## Run
1. Install Godot 4.7.2-stable and its export templates.
2. Open this folder (`project.godot`) in Godot and press F5.
3. Until each mode implements its round logic, matches run with the shared placeholder mode
   (`modes/_placeholder/`) — see `docs/DECISIONS.md` for when to flip each mode back in `data/modes.json`.

## Docs
- Design specs and team plan, and Technical Architecture: shared docs from the team lead.
- Workflow and rules: `docs/WORKFLOW.md`
- AI usage log (required for the disclosure form): `docs/AI_USAGE_LOG.md`
- Asset licenses (required for the disclosure form): `assets/LICENSES.md`
- Decisions: `docs/DECISIONS.md`

## Layout
```
autoload/    global singletons (Game, Config, Events)
core/        match, scoring, input, bots  (team lead edits only)
characters/  shared Player
modes/       one folder per mode, one owner per mode
ui/          menus and HUD
data/        config.json, modes.json, bot_names.json
assets/      models, textures, audio, LICENSES.md
tools/       debug helpers
docs/        workflow, decisions, AI usage log
```
