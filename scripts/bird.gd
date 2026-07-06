extends CharacterBody2D
class_name Bird

const SHIT: PackedScene = preload("res://scenes/shit.tscn")

# Added RESTING state
enum BirdState { BOID, RESTING }
var state: BirdState = BirdState.BOID
var state_timer: float = 0

var target_cable: Cable = null
var target_particle_idx: int = -1
var landing_cooldown: float = 0.0

@export var max_speed: float = 120.0
@export var max_force: float = 5.0
@export var perception_radius: float = 30.0
@export var separation_radius: float = 5.0
@export var separation_weight: float = 0.93
@export var alignment_weight: float = 0.8
@export var cohesion_weight: float = 0.4
@export var ceiling_y: float = 0.0      # Y coordinate they shouldn't cross going up
@export var ground_y: float = 220.0       # Y coordinate they shouldn't cross going down
@export var avoidance_buffer: float = 50.0 # Distance from boundary where they start to

@onready var sprite: Sprite2D = $Sprite2D
@onready var view: Area2D = $View
@export var mass: float = 0.21
var screen_size: Vector2

var shit_timer: float = 10.0

func _ready() -> void:
	screen_size = get_viewport_rect().size
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * max_speed
	shit_timer = randf_range(0.2, 3.0)

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
	position.x = fposmod(position.x, screen_size.x)
	position.y = clamp(position.y, -avoidance_buffer, ground_y * 1.5)

func process_boid(delta: float) -> void:
	var mates: Array[Bird] = get_flockmates()
	var separation: Vector2 = calculate_separation(mates)
	var alignment: Vector2 = calculate_alignment(mates)
	var cohesion: Vector2 = calculate_cohesion(mates)
	var wind: Vector2 = Wind.at(global_position)

	var acceleration: Vector2 = Vector2.ZERO
	acceleration += separation * separation_weight
	acceleration += alignment * alignment_weight
	acceleration += cohesion * cohesion_weight
	acceleration += calculate_boundary_avoidance() * 2
	acceleration += wind * 0.01

	velocity += acceleration
	velocity = velocity.limit_length(max_speed)

	# Check for cables while flying
	try_find_and_land_on_cable()

func try_find_and_land_on_cable() -> void:
	if landing_cooldown > 0:
		return

	if not ("cables" in Global) or Global.cables.is_empty():
		return

	if randf() > 0.02:
		return

	var closest_cable: Cable = null
	var closest_particle_idx: int = -1
	var min_dist: float = 60.0 # Maximum distance a bird will notice a cable to land

	for cable: Cable in Global.cables:
		if not is_instance_valid(cable) or cable.particles.is_empty() or !cable.connected or cable.is_queued_for_deletion():
			continue
		var idx: int = cable.get_random_particle_index()
		if idx != -1:
			var dist: float = global_position.distance_to(cable.particles[idx].position)
			if dist < min_dist:
				min_dist = dist
				closest_cable = cable
				closest_particle_idx = idx

	if closest_cable != null:
		target_cable = closest_cable
		target_particle_idx = closest_particle_idx
		state = BirdState.RESTING
		state_timer = 0.0
		shit_timer = 2.0
		target_cable.pressure += mass
		target_cable.cable_snapped.connect(_on_target_cable_snapped)

func _on_target_cable_snapped(_cable: Cable) -> void:
	state = BirdState.BOID
	state_timer = 0.0
	landing_cooldown = 2.0
	target_cable = null
	target_particle_idx = -1
	velocity = Vector2(randf_range(-1, 1), -1).normalized() * max_speed

func process_resting(delta: float) -> void:
	velocity = Vector2.ZERO

	global_position = target_cable.particles[target_particle_idx].position

	if state_timer > 3.0 and randf() < 0.1:
		fly_away()

	if shit_timer <= 0.0:
		var shit: Shit = SHIT.instantiate()
		shit.global_position = global_position
		shit.target_depth = randf_range(222, 300)
		get_tree().current_scene.add_child(shit)
		shit_timer = randf_range(15, 19.0)

	shit_timer -= delta

func fly_away() -> void:
	target_cable.pressure -= mass
	state = BirdState.BOID
	state_timer = 0.0
	landing_cooldown = 2.0 # Don't immediately re-land on the same cable
	target_cable = null
	target_particle_idx = -1
	# Launch with a slight upward random velocity
	velocity = Vector2(randf_range(-1, 1), -1).normalized() * max_speed

func _physics_process(delta: float) -> void:
	state_timer += delta
	if landing_cooldown > 0:
		landing_cooldown -= delta

	match state:
		BirdState.BOID:
			process_boid(delta)
			move_and_slide()
			wrap_around_screen()
		BirdState.RESTING:
			process_resting(delta)
