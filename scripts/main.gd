extends Node2D

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_ESCAPE and event.is_released():
			get_tree().quit()
