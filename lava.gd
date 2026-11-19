extends AnimatedSprite2D

@onready var particles: GPUParticles2D = $Bubble

var _base_scale_min: float = 1.0
var _base_scale_max: float = 1.0
var _base_emission_extents: Vector3 = Vector3.ZERO
var _material: ParticleProcessMaterial

func _ready() -> void:
	_material = particles.process_material as ParticleProcessMaterial
	if _material != null:
		_base_scale_min = _material.scale_min
		_base_scale_max = _material.scale_max
		_base_emission_extents = _material.emission_box_extents

	frame_changed.connect(_update_particle_anchor)
	animation_changed.connect(_update_particle_anchor)
	_update_particle_anchor()

func _update_particle_anchor() -> void:
	if sprite_frames == null or animation.is_empty():
		return

	var tex := sprite_frames.get_frame_texture(animation, frame)
	if tex == null:
		return

	var tex_size := tex.get_size() * scale
	var local_anchor: Vector2

	if centered:
		local_anchor = Vector2(0.0, tex_size.y * 0.5) + offset
	else:
		local_anchor = Vector2(tex_size.x * 0.5, tex_size.y) + offset

	if particles.top_level:
		particles.global_position = to_global(local_anchor)
	else:
		particles.position = local_anchor

	_sync_particle_scale()

func _sync_particle_scale() -> void:
	if _material == null:
		return

	# Use average X/Y scale (or scale.y / scale.x depending on your sprite's aspect behavior)
	var uniform_scale := (absf(scale.x) + absf(scale.y)) * 0.5
	_material.scale_min = _base_scale_min * uniform_scale
	_material.scale_max = _base_scale_max * uniform_scale

	if _base_emission_extents != Vector3.ZERO:
		_material.emission_box_extents = Vector3(
			_base_emission_extents.x * absf(scale.x),
			_base_emission_extents.y * absf(scale.y),
			_base_emission_extents.z
		)

func _process(delta: float) -> void:
	print(particles.position)
