class_name Player
extends CharacterBody3D
## One shared character for humans and bots. Modes may override movement
## (for example Luksong Baka auto-runs) by reading `input` themselves.

@export var move_speed: float = 6.0

var player_id: int = -1
var display_name: String = ""
var team_id: int = -1
var is_bot: bool = false
var alive: bool = true
var input: InputProvider


func _physics_process(delta: float) -> void:
    if input == null or not alive:
        return
    input.poll(delta)
    velocity.x = input.move.x * move_speed
    velocity.z = input.move.y * move_speed
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    move_and_slide()
