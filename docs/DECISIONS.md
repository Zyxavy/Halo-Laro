# Decision log

| Date | Decision | Why | Who |
|---|---|---|---|
| (fill) | Godot 4.7.2-stable, Compatibility renderer, native Windows build for MVP | Fastest path; organizers accept native; web port stays cheap | Team lead |
| 2026-10-17 | Entry name: **Halo-Laro**; UI palette: charcoal-brown, dust-grey, silver, soft-periwinkle, raspberry, single source in `ui/UIKit.gd` | Name chosen for the entry; one file to restyle the whole UI | Team (AI-assisted) |
| 2026-10-17 | Menu/HUD layer is code-built Control screens in `ui/`; `ui/App.tscn` is the main scene and owns `MatchManager` | Text-only scenes stay merge-friendly; all styling lives in `UIKit` | Team (AI-assisted) |
| 2026-10-17 | `modes.json` `scene` fields temporarily point at `modes/_placeholder/PlaceholderMode.tscn` | The real mode scenes do not implement `start()`/`finished` yet; the placeholder keeps the full menu-to-podium flow playable. Flip each `scene` back when the mode lands | Team (AI-assisted) |
| 2026-10-17 | Third-person Fall Guys-style camera: one shared `CameraRig` (`core/camera/`, three presets) owned by `MatchManager`. One `Player` controller for humans and bots (acceleration, coyote time, jump buffering) with mode flags (`frozen`, `move_enabled`, `jump_enabled`, `speed_scale`) | Modes need the character visible (jump timing, field awareness, the Taya behind you); the demo video reads better; camera-relative movement ports to mobile later | Team (AI-assisted) |
