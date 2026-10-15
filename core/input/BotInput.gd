class_name BotInput
extends InputProvider
## Drives a Player through the same input struct as a human.

var brain: BotBase


func poll(delta: float) -> void:
    if brain == null:
        return
    brain.think(delta)
    move = brain.out_move
    action_a = brain.out_action_a
    action_b = brain.out_action_b
    action_a_pressed = brain.out_action_a_pressed
    action_b_pressed = brain.out_action_b_pressed
