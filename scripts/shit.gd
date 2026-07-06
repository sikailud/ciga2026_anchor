extends Area2D
class_name Shit

enum ShitState { Falling, Rest }
var state: ShitState = ShitState.Falling

var target_depth: float = 280
@onready var sprite: Sprite2D = $Sprite2D
var velocity: Vector2 = Vector2.ZERO
var max_speed: float = 600

@export var splat_sfx: AudioStream

func _physics_process(delta: float) -> void:
	match state:
		ShitState.Falling:
			var acc: Vector2 = Vector2(0, 360)
			var wind: Vector2 = Wind.at(global_position)
			acc += wind * 0.1
			velocity.y += acc.y * delta
			global_position += velocity.limit_length(max_speed) * delta
			if global_position.y >= target_depth:
				sprite.frame = 1
				global_position.y = target_depth
				state = ShitState.Rest
				Sfx.play(splat_sfx, 0.2, 0.2)
		ShitState.Rest:
			pass
