extends Sprite2D

@export var sfx: AudioStream

func _ready() -> void:
	hide()

func _on_rule_board_trigger_mouse_entered() -> void:
	Sfx.play(sfx, 0.0, 0.3)
	show()

func _on_rule_board_trigger_mouse_exited() -> void:
	Sfx.play(sfx, 0.0, 0.3)
	hide()
