class_name WanderBrain
extends BotBase
## Simplest possible bot: walk to random points and jump now and then.
## Use it to test the Player and camera, and as a template for real mode bots.
## Bot movement is in world space: out_move.x = +X, out_move.y = +Z.

var area_half_size: float = 15.0

var _target: Vector3 = Vector3.ZERO
var _retarget_in: float = 0.0
var _jump_in: float = 1.0


func think(delta: float) -> void:
    out_action_a_pressed = false
    if bot_player == null or not bot_player.is_inside_tree():
        return

    _retarget_in -= delta
    var pos := bot_player.global_position
    if _retarget_in <= 0.0 or pos.distance_to(_target) < 1.0:
        _target = Vector3(randf_range(-area_half_size, area_half_size), 0.0, randf_range(-area_half_size, area_half_size))
        _retarget_in = randf_range(2.0, 5.0)

    var to_target := Vector2(_target.x - pos.x, _target.z - pos.z)
    out_move = to_target.normalized() if to_target.length() > 1.0 else to_target

    _jump_in -= delta
    if _jump_in <= 0.0:
        out_action_a_pressed = true
        _jump_in = randf_range(1.5, 4.0)
