class_name HumanInput
extends InputProvider
## Keyboard now. Touch (virtual joystick + two buttons) comes after the MVP.


func poll(_delta: float) -> void:
    move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    action_a = Input.is_action_pressed("action_a")
    action_b = Input.is_action_pressed("action_b")
    action_a_pressed = Input.is_action_just_pressed("action_a")
    action_b_pressed = Input.is_action_just_pressed("action_b")
