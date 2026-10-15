class_name ModeResult
extends RefCounted
## What every mode returns. Fill the fields that match `kind`.
##   "placement": placements = player ids, best first
##   "points":    points = {player_id: int}
##   "team":      team_of = {player_id: team_id}, winning_team, mvp

var kind: String = "placement"
var placements: Array[int] = []
var points: Dictionary = {}
var team_of: Dictionary = {}
var winning_team: int = -1
var mvp: int = -1
var stats: Dictionary = {}
