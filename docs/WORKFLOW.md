# Team workflow

## Daily rhythm
1. Morning stand-up (15 min): done / doing today / blocked.
2. Work on small branches: `feature/<area>-<name>`. Merge to `main` at least daily. `main` must always launch.
3. Midday integration: merge and fix conflicts while everyone is online.
4. Evening build check: launch, play a full 3-mode match, confirm the podium, run bot-only autoplay.
   Tag the build: `day-N`.

## Rules
- One owner per scene and one folder per mode. Only the team lead edits `core/` and `autoload/`.
- Pull requests reviewed by the team lead; tiny fixes may be self-merged.
- Commit messages say what changed. Add `AI-assisted:` when AI helped.
- Log AI use in `docs/AI_USAGE_LOG.md` and assets in `assets/LICENSES.md` as you go.

## Bug labels
- P0: blocks the demo. P1: should fix. P2: nice to have.

## Milestones
- End of Day 1: interfaces frozen, repo works for everyone, character moves.
- End of Day 2: placeholder mode runs the full flow, menu to podium.
- End of Day 4: all three modes playable with basic bots.
- End of Day 6: first full 3-mode match.
- End of Day 7: FEATURE FREEZE.
- Day 8: P0/P1 bugs only, disclosure sheets complete.
- Day 9: demo-ready build and rehearsal. Day 10: record, edit, submit.
