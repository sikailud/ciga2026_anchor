extends Area2D

@export var max_speed: float = 30
@export var pickup_sfx: AudioStream

@onready var view: Area2D = $View
@onready var ani: AnimationPlayer = $AnimationPlayer
var rest: bool = false
var rest_timer: float = 0

func get_shits_in_view() -> Array[Shit]:
	var shits: Array[Shit] = []
	var overlapping_areas: Array[Area2D] = view.get_overlapping_areas()
	for area: Area2D in overlapping_areas:
		if area is Shit:
			shits.append(area)
	return shits

func get_nearest_shit(shits: Array[Shit]) -> Shit:
	if shits.is_empty():
		return null
	var nearest: Shit = shits[0]
	var min_dist: float = global_position.distance_to(nearest.global_position)
	for i: int in range(1, shits.size()):
		var dist: float = global_position.distance_to(shits[i].global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = shits[i]
	return nearest

func _physics_process(delta: float) -> void:
	rest_timer -= delta
	if rest_timer > 0:
		return
	var visible_shits: Array[Shit] = get_shits_in_view()
	var target: Shit = get_nearest_shit(visible_shits)
	if not is_instance_valid(target):
		return
	var direction: Vector2 = (target.global_position - global_position).normalized()
	var distance: float = global_position.distance_to(target.global_position)
	if distance <= 3:
		pick_up_shit(target)
	else:
		global_position += direction * max_speed * delta

	global_position.y = clamp(global_position.y, 220, 300)

func pick_up_shit(target: Shit) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	ani.current_animation = "Wow"
	ani.play()
	Sfx.play(pickup_sfx, 0.2, 0.6)
	target.queue_free()
	rest = true
	rest_timer = 0.5
	Score.increase(1)
