extends Node2D
class_name Pole

signal pole_clicked(pole: Pole)
@onready var in_m: Marker2D = $AnchorLeft
@onready var out_m: Marker2D = $AnchorRight

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pole_clicked.emit(self)
