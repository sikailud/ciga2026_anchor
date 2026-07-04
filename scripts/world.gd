extends Node2D

const WIDTH: float = 400
const HEIGHT: float = 300

var connecting: bool = false
var previous_pole: Pole

const CABLE: PackedScene = preload("res://scenes/cable.tscn")
var cables: Array[Cable]
const BIRD: PackedScene = preload("res://scenes/bird.tscn")
var birds: Array[Bird]

func _on_pole_clicked(pole: Pole) -> void:
	if !connecting:
		previous_pole = pole
		connecting = true
		cables.append(CABLE.instantiate())
		cables[-1].global_position = pole.out_m.global_position
		add_child(cables[-1])
	elif pole != previous_pole:
		var distance: float = (pole.in_m.global_position - previous_pole.out_m.global_position).length()
		if distance <= cables[-1].max_length:
			cables[-1].pole_a = previous_pole
			cables[-1].pole_b = pole
			cables[-1].stretch_to(previous_pole.out_m.global_position)
			cables[-1].stretch_to(pole.in_m.global_position)
			cables[-1].connected = true
			connecting = false
		else:
			cables[-1].queue_free()
			cables.pop_back()
			connecting = false

func _ready() -> void:
	for child: Node in get_children():
		if child is Pole:
			child.pole_clicked.connect(_on_pole_clicked)

	# Spawn Bird
	for i: int in range(120):
		var p: Vector2 = Vector2(randi() % 400, randi() % 100 + 100)
		var b: Bird = BIRD.instantiate()
		b.global_position = p
		add_child(b)


func _physics_process(_delta: float) -> void:
	if connecting:
		cables[-1].stretch_to(get_global_mouse_position())

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_ESCAPE and event.is_released():
			get_tree().quit()
