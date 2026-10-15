class_name InputProvider
extends RefCounted
## One movement input and at most two actions, so touch controls stay feasible later.

var move: Vector2 = Vector2.ZERO
var action_a: bool = false
var action_b: bool = false
var action_a_pressed: bool = false
var action_b_pressed: bool = false


func poll(_delta: float) -> void:
    pass
