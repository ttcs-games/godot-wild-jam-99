extends Node2D

@export var box := Rect2(-100, -50, 200, 100)   # emitter box, local space
@export var max_particles := 300
@export var spawn_rate := 80.0                  # particles per second
@export var lifetime := 2.0
@export var spawn_speed := 80.0

@export var inside_accel := Vector2.ZERO
@export var outside_accel := Vector2(0, -400)
@export var inside_color := Color.WHITE
@export var outside_color := Color(1.0, 0.3, 0.2)

@export var particle_texture: Texture2D         # optional, otherwise draws circles
@export var particle_radius := 3.0

class Particle:
	var pos: Vector2
	var vel: Vector2
	var age := 0.0

var particles: Array[Particle] = []
var spawn_accum := 0.0


func _process(delta: float) -> void:
	# spawning
	spawn_accum += spawn_rate * delta
	while spawn_accum >= 1.0:
		spawn_accum -= 1.0
		if particles.size() < max_particles:
			_spawn()

	# updating (iterate backwards so removal is safe)
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p.age += delta
		if p.age >= lifetime:
			particles[i] = particles.back()
			particles.pop_back()
			continue

		var accel := inside_accel if box.has_point(p.pos) else outside_accel
		p.vel += accel * delta
		p.pos += p.vel * delta

	queue_redraw()


func _spawn() -> void:
	var p := Particle.new()
	p.pos = box.position + Vector2(randf() * box.size.x, randf() * box.size.y)
	p.vel = Vector2.from_angle(randf() * TAU) * spawn_speed
	particles.append(p)


func _draw() -> void:
	for p in particles:
		var col := inside_color if box.has_point(p.pos) else outside_color
		col.a *= 1.0 - p.age / lifetime   # fade out over lifetime
		if particle_texture:
			draw_texture(particle_texture, p.pos - particle_texture.get_size() * 0.5, col)
		else:
			draw_circle(p.pos, particle_radius, col)
