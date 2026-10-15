extends Node
## Global signals for cross-cutting events only. Modes never call the UI directly.

signal match_started
signal match_ended
signal round_started(mode_id: String)
signal round_ended(mode_id: String)
signal player_eliminated(player_id: int)
signal score_changed(player_id: int, total: int)
