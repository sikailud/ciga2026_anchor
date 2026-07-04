extends CharacterBody2D
class_name ElectricBird

enum BirdState { FLYING, LANDING, RESTING }
var current_state: BirdState = BirdState.FLYING

# Movement Settings
@export var fly_speed: float = 120.0
@export var land_speed: float = 80.0
@export var change_target_time: Vector2 = Vector2(1.5, 4.0) # Min/Max time to pick a new wander point
@export var rest_duration: Vector2 = Vector2(3.0, 8.0)     # Min/Max time to stay on a cable

# # Internal State Variables
# var target_position: Vector2 = Vector2.ZERO
# var state_timer: float = 0.0
# var target_cable: Cable = null

# func _ready() -> void:
# 	randomize()
# 	_pick_random_wander_target()

# func _physics_process(delta: float) -> void:
# 	state_timer -= delta

# 	match current_state:
# 		BirdState.FLYING:
# 			_process_flying(delta)
# 		BirdState.LANDING:
# 			_process_landing(delta)
# 		BirdState.RESTING:
# 			_process_resting(delta)

# 	# Apply movement if we aren't completely resting
# 	if current_state != BirdState.RESTING:
# 		move_and_slide()

# # --- STATE LOGIC ---

# func _process_flying(delta: float) -> void:
# 	_move_towards(target_position, fly_speed)
# 	_face_direction(target_position - global_position)

# 	# Condition 1: Time to pick a new random direction to fly
# 	if state_timer <= 0:
# 		# 30% chance to look for a cable to rest on, otherwise keep wandering
# 		if randf() < 0.3 and _try_find_cable():
# 			_transition_to(BirdState.LANDING)
# 		else:
# 			_pick_random_wander_target()

# 	# Condition 2: Arrived close to the wander target early
# 	if global_position.distance_to(target_position) < 10.0:
# 		_pick_random_wander_target()

# func _process_landing(delta: float) -> void:
# 	# Make sure the cable still exists
# 	if not is_instance_valid(target_cable):
# 		_transition_to(BirdState.FLYING)
# 		return

# 	_move_towards(target_position, land_speed)
# 	_face_direction(target_position - global_position)

# 	# Condition: Arrived safely on the cable perch
# 	if global_position.distance_to(target_position) < 4.0:
# 		global_position = target_position # Snap perfectly to wire
# 		velocity = Vector2.ZERO
# 		_transition_to(BirdState.RESTING)

# func _process_resting(_delta: float) -> void:
# 	# Keep snapped to cable if it's moving, or abort if the cable breaks/disappears
# 	if is_instance_valid(target_cable):
# 		# Optional: Play idle/perched animation here
# 		pass
# 	else:
# 		_transition_to(BirdState.FLYING)
# 		return

# 	# Condition: Rest time is over, fly away
# 	if state_timer <= 0:
# 		_transition_to(BirdState.FLYING)

# # --- HELPER FUNCTIONS ---

# func _transition_to(new_state: BirdState) -> void:
# 	current_state = new_state

# 	match current_state:
# 		BirdState.FLYING:
# 			target_cable =  null
# 			_pick_random_wander_target()
# 			# Play flying animation here

# 		BirdState.LANDING:
# 			# Target position was already set inside _try_find_cable()
# 			state_timer = 5.0 # Timeout safety: if it takes >5s to land, give up
# 			# Play descending/gliding animation here

# 		BirdState.RESTING:
# 			state_timer = randf_range(rest_duration.x, rest_duration.y)
# 			# Play sitting/pecking animation here

# func _move_towards(target: Vector2, speed: float) -> void:
# 	var direction = global_position.direction_to(target)
# 	velocity = direction * speed

# func _face_direction(dir: Vector2) -> void:
# 	if dir.x > 1.0:
# 		$Sprite2D.flip_h = false # Facing Right
# 	elif dir.x < -1.0:
# 		$Sprite2D.flip_h = true  # Facing Left

# func _pick_random_wander_target() -> void:
# 	state_timer = randf_range(change_target_time.x, change_target_time.y)

# 	# Pick a random spot around the bird's current position to fly towards
# 	var random_radius = randf_range(100.0, 300.0)
# 	var random_angle = randf_range(0, TWO_PI)
# 	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_radius

# 	target_position = global_position + offset

# func _try_find_cable() -> bool:
# 	# Find all active cables in the scene
# 	# This grabs them from the Scene Tree. Make sure cables are added as regular children in your world.
# 	var all_cables = get_tree().get_nodes_in_group("cables")

# 	# If you aren't using groups, you could use a fallback search:
# 	if all_cables.is_empty():
# 		all_cables = get_parent().get_children().filter(func(node): return node is Cable)

# 	if all_cables.is_empty():
# 		return false # No cables available to rest on

# 	# Pick a random cable and get a perch spot on it
# 	target_cable = all_cables.pick_random() as Cable
# 	target_position = target_cable.get_random_perch_position()
# 	return true
