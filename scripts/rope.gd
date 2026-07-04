extends Line2D

class RopeParticle:
	var position: Vector2
	var previous_position: Vector2
	var is_pinned: bool = false

@export var segment_count: int = 30
@export var segment_length: float = 15.0
@export var gravity: Vector2 = Vector2(0, 180)
@export var constraint_iterations: int = 30

var particles: Array[RopeParticle] = []

func _ready() -> void:
	var start_pos = global_position
	for i in range(segment_count):
		var p = RopeParticle.new()
		p.position = start_pos + Vector2(i * segment_length, 0)
		p.previous_position = p.position
		particles.append(p)
	particles[0].is_pinned = true
	particles[-1].is_pinned = true


func _physics_process(delta: float) -> void:
	particles[0].position = global_position
	simulate(delta)
	apply_constraints()
	apply_collisions()
	apply_character_push()
	clear_points()
	for p in particles:
		add_point(to_local(p.position))


func simulate(delta: float) -> void:
	for p in particles:
		if p.is_pinned:
			continue
		var velocity = p.position - p.previous_position
		p.previous_position = p.position
		p.position += velocity + (gravity * delta * delta)


func apply_constraints() -> void:
	for iteration in range(constraint_iterations):
		for i in range(particles.size() - 1):
			var p1 = particles[i]
			var p2 = particles[i + 1]
			var delta_vec = p2.position - p1.position
			var distance = delta_vec.length()
			if distance == 0.0:
				continue

			var error = segment_length - distance
			var percent = (error / distance) / 2.0
			var offset = delta_vec * percent

			if not p1.is_pinned:
				p1.position -= offset
			if not p2.is_pinned:
				p2.position += offset


func apply_collisions() -> void:
	var space_state = get_world_2d().direct_space_state

	for p in particles:
		if p.is_pinned:
			continue

		var query = PhysicsRayQueryParameters2D.create(p.previous_position, p.position)
		query.collision_mask = 1

		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			var collision_point = result.position
			var collision_normal = result.normal

			p.position = collision_point + collision_normal * 2.0

			var velocity = p.position - p.previous_position
			velocity = velocity.slide(collision_normal)
			p.previous_position = p.position - velocity


func apply_character_push() -> void:
	var space_state = get_world_2d().direct_space_state

	for p in particles:
		if p.is_pinned:
			continue

		var query = PhysicsShapeQueryParameters2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 4.0
		query.shape = circle
		query.transform = Transform2D(0, p.position)
		query.collision_mask = 2

		var results = space_state.intersect_shape(query)
		for result in results:
			if result.collider is Area2D:
				var pusher_center = result.collider.global_position
				var push_direction = (p.position - pusher_center).normalized()
				p.position += push_direction * 5.0
