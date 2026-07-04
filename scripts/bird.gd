extends CharacterBody2D
class_name Bird

enum BirdState { BOID, LANDING, RESTING }
var state: BirdState = BirdState.BOID
var rest_cable: Cable
var state_timer: float = 0

@export var max_speed: float = 120.0
@export var max_force: float = 5.0
@export var perception_radius: float = 30.0
@export var separation_radius: float = 5.0
@export var separation_weight: float = 0.93
@export var alignment_weight: float = 0.8
@export var cohesion_weight: float = 0.4
@export var ceiling_y: float = 0.0      # Y coordinate they shouldn't cross going up
@export var ground_y: float = 220.0       # Y coordinate they shouldn't cross going down
@export var avoidance_buffer: float = 50.0 # Distance from boundary where they start to turn

@onready var sprite: Sprite2D = $Sprite2D
@onready var view: Area2D = $View

var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport_rect().size
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * max_speed

func get_flockmates() -> Array[Bird]:
	var mates: Array[Bird] = []
	var overlapping_bodies: Array[Node2D] = view.get_overlapping_bodies()
	for body: Node2D in overlapping_bodies:
		if body != self and body.is_in_group("birds"):
			mates.append(body as Bird)
	return mates

func calculate_separation(flockmates: Array[Bird]) -> Vector2:
	var steering: Vector2 = Vector2.ZERO
	var total: int = 0
	for boid: Bird in flockmates:
		var dist: float = global_position.distance_to(boid.global_position)
		if dist < separation_radius and dist > 0:
			# Push away stronger if closer
			var diff: Vector2 = (global_position - boid.global_position).normalized() / dist
			steering += diff
			total += 1
	if total > 0:
		steering /= total
		steering = steering.normalized() * max_speed - velocity
		steering = steering.limit_length(max_force)
	return steering

func calculate_alignment(flockmates: Array[Bird]) -> Vector2:
		var avg_velocity: Vector2 = Vector2.ZERO
		var total: int = 0
		for boid: Bird in flockmates:
			avg_velocity += boid.velocity
			total += 1
		if total > 0:
			avg_velocity /= total
			var steering: Vector2 = avg_velocity.normalized() * max_speed - velocity
			return steering.limit_length(max_force)
		return Vector2.ZERO

func calculate_cohesion(flockmates: Array[Bird]) -> Vector2:
		var center_of_mass: Vector2 = Vector2.ZERO
		var total: int = 0
		for boid: Bird in flockmates:
			center_of_mass += boid.global_position
			total += 1
		if total > 0:
			center_of_mass /= total
			# Seek target position
			var desired_velocity: Vector2 = (center_of_mass - global_position).normalized() * max_speed
			var steering: Vector2 = desired_velocity - velocity
			return steering.limit_length(max_force)
		return Vector2.ZERO

func calculate_boundary_avoidance() -> Vector2:
	var steering: Vector2 = Vector2.ZERO
	if global_position.y < ceiling_y + avoidance_buffer * 0.05:
		var desired_y: float = max_speed
		steering.y = desired_y - velocity.y
	elif global_position.y > ground_y - avoidance_buffer:
		var desired_y: float = -max_speed
		steering.y = desired_y - velocity.y
	if steering != Vector2.ZERO:
		return steering.limit_length(max_force)
	return Vector2.ZERO

func wrap_around_screen() -> void:
	# Only loop on the X axis
	position.x = fposmod(position.x, screen_size.x)
	# Hard clamp Y just in case high forces briefly push a boid past the lines
	position.y = clamp(position.y, -avoidance_buffer, ground_y * 1.5)

func process_boid(delta: float) -> void:
	var mates: Array[Bird] = get_flockmates()
	var separation: Vector2 = calculate_separation(mates)
	var alignment: Vector2 = calculate_alignment(mates)
	var cohesion: Vector2 = calculate_cohesion(mates)

	var acceleration: Vector2 = Vector2.ZERO
	acceleration += separation * separation_weight
	acceleration += alignment * alignment_weight
	acceleration += cohesion * cohesion_weight
	acceleration += calculate_boundary_avoidance() * 2
	velocity += acceleration
	velocity = velocity.limit_length(max_speed)

func process_landing(delta: float) -> void:
	pass

func process_resting(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	state_timer += delta
	match state:
		BirdState.BOID:
			process_boid(delta)
		BirdState.LANDING:
			process_landing(delta)
		BirdState.RESTING:
			process_landing(delta)

	if state != BirdState.RESTING:
		move_and_slide()

	wrap_around_screen()
