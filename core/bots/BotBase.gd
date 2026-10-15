class_name BotBase
extends RefCounted
## Shared bot helpers. Each mode extends this in its own bots/ folder.
## `skill` is 0..1 and should scale accuracy and reaction time.

var skill: float = 0.6
var bot_player: Player

var out_move: Vector2 = Vector2.ZERO
var out_action_a: bool = false
var out_action_b: bool = false
var out_action_a_pressed: bool = false
var out_action_b_pressed: bool = false


func think(_delta: float) -> void:
    pass


func reaction_delay() -> float:
    return lerpf(0.6, 0.15, skill)


func aim_error() -> float:
    return lerpf(1.0, 0.1, skill)
