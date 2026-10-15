extends Node
## Global game state and input-map setup.

var match_seed: int = 0


func _ready() -> void:
    _ensure_input_actions()


func _ensure_input_actions() -> void:
    var actions := {
        "move_left": [KEY_A, KEY_LEFT],
        "move_right": [KEY_D, KEY_RIGHT],
        "move_forward": [KEY_W, KEY_UP],
        "move_back": [KEY_S, KEY_DOWN],
        "action_a": [KEY_SPACE],
        "action_b": [KEY_E],
    }
    for action in actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key in actions[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action, event)
