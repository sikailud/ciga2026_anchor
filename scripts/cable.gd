extends Line2D
class_name Cable

class CableParticle:
	var position: Vector2
	var previous_position: Vector2
	var is_pinned: bool = false


@export var length: float = 70
@onready var max_length: float = length * 2
var particle_spacing: float = 5
var particles: Array[CableParticle] = []
var pole_a: Pole
var pole_b: Pole
var connected: bool = false
var gravity: Vector2 = Vector2(0, 300)
var pressure: float = 1.0

func stretch_to(to: Vector2) -> void:
	var origin: Vector2 = particles[0].position
	var to_origin: Vector2 = to - origin
	particles[-1].position = to if to_origin.length() <= max_length \
		else origin + to_origin.normalized() * max_length

func _ready() -> void:
	# Initialize particles
	var origin: Vector2 = global_position
	var particle_count: int = int(length / particle_spacing)
	for i: int in range(particle_count):
		var p: CableParticle = CableParticle.new()
		p.position = origin + Vector2(i * particle_spacing, 0)
		p.previous_position = p.position
		particles.append(p)
	particles[0].is_pinned = true
	particles[-1].is_pinned = true

func get_resting_point() -> int:
	return randi_range(1, particles.size()-1)

func get_resting_point_position(point: int) -> Vector2:
	return particles[point].position

func _physics_process(delta: float) -> void:
	if connected:
		max_length = length * 2 * pressure
	for p: CableParticle in particles: # Verlet integration
		if p.is_pinned:
			continue
		var velocity: Vector2 = p.position - p.previous_position
		p.previous_position = p.position
		p.position += velocity + (gravity * (pressure * 2) * delta**2)
	for i: int in range(6): # apply constraints
		for j: int in range(particles.size() - 1):
			var p: CableParticle = particles[j]
			var next: CableParticle = particles[j + 1]
			var to_next: Vector2 = next.position - p.position
			var distance: float = to_next.length()
			if distance <= 0:
				continue
			var error: float = particle_spacing - distance
			var percent: float = (error / distance) / 2.0
			var offset: Vector2 = to_next * percent
			if !p.is_pinned:
				p.position -= offset
			if !next.is_pinned:
				next.position += offset

	# Update Line2D points
	clear_points()
	for p: CableParticle in particles:
		add_point(to_local(p.position))
