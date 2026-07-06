extends Node

@export var base_wind_direction: Vector2 = Vector2.RIGHT
@export var base_wind_speed: float = 100.0
@export var gust_frequency: float = 0.5
@export var gust_strength: float = 50.0

var noise: FastNoiseLite
var directional_noise: FastNoiseLite
var time: float = 0.0

func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = gust_frequency

func _physics_process(delta: float) -> void:
	time += delta

## Returns the wind velocity vector at a specific global position
func at(global_pos: Vector2) -> Vector2:
	var noise_val: float = noise.get_noise_2d(global_pos.x * 0.005 + time, global_pos.y * 0.005)
	var current_speed: float = base_wind_speed + (noise_val * gust_strength)
	return base_wind_direction.normalized() * current_speed
