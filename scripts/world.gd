extends Node2D

const WIDTH: float = 400
const HEIGHT: float = 300

var connecting: bool = false
@export var previous_pole: Pole

const CABLE: PackedScene = preload("res://scenes/cable.tscn")
const BIRD: PackedScene = preload("res://scenes/bird.tscn")
const POLE: PackedScene = preload("res://scenes/pole.tscn")

@export var sfx_connected: AudioStream
@export var sfx_unconnected: AudioStream
@export var sfx_buy: AudioStream
@export var starting_score: int = 25
@export var starting_bird_count: int = 50
@onready var ap: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	ap.play("fadein")
	Score.score = starting_score
	for child: Node in get_children():
		if child is Pole:
			child.pole_clicked.connect(_on_pole_clicked)

	for i: int in range(starting_bird_count):
		var p: Vector2 = Vector2(randi() % 400, randi() % 100 + 100)
		var b: Bird = BIRD.instantiate()
		b.global_position = p
		add_child(b)

func _physics_process(_delta: float) -> void:
	if connecting:
		Global.cables[-1].stretch_to(get_global_mouse_position())

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_ESCAPE and event.is_released():
			get_tree().quit()

func get_random_cable() -> Cable:
	if Global.cables.size() <= 0:
		return null
	return Global.cables.pick_random()

func _on_pole_clicked(pole: Pole) -> void:
	if connecting:
		if pole != previous_pole:
			var distance: float = (pole.in_m.global_position - previous_pole.out_m.global_position).length()
			if distance <= Global.cables[-1].max_length and Score.score >= 9:
				Sfx.play(sfx_connected)
				Global.cables[-1].pole_a = previous_pole
				Global.cables[-1].pole_b = pole
				Global.cables[-1].stretch_to(previous_pole.out_m.global_position)
				Global.cables[-1].stretch_to(pole.in_m.global_position)
				Global.cables[-1].connected = true
				Score.decrease(9)
			else:
				Sfx.play(sfx_unconnected)
				var cable: Cable = Global.cables[-1]
				Global.cables.erase(cable)
				cable.queue_free()
			connecting = false
	else:
		Sfx.play(sfx_buy)
		connecting = true
		Global.cables.append(CABLE.instantiate())
		Global.cables[-1].global_position = pole.out_m.global_position
		add_child(Global.cables[-1])
	previous_pole = pole
