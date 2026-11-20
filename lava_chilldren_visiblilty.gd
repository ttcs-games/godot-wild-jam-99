extends AnimatedSprite2D

@export var children_to_hide: Array[CanvasItem]   

func _process(_delta: float) -> void:
	if sprite_frames == null:
		return
	var tex := sprite_frames.get_frame_texture(animation, frame)
	if tex == null:
		return

	# current frame's rectangle in local space
	var size := tex.get_size()
	var rect_pos := offset - (size * 0.5 if centered else Vector2.ZERO)

	# if the frame comes from a sprite sheet, find its region inside the sheet
	var sheet: Texture2D = tex
	var uv_pos := Vector2.ZERO
	var uv_size := Vector2.ONE
	if tex is AtlasTexture:
		var atlas_tex := tex as AtlasTexture
		sheet = atlas_tex.atlas
		var sheet_size := sheet.get_size()
		uv_pos = atlas_tex.region.position / sheet_size
		uv_size = atlas_tex.region.size / sheet_size

	var inv := global_transform.affine_inverse()
	var flip := Vector2(1.0 if flip_h else 0.0, 1.0 if flip_v else 0.0)

	for c in children_to_hide:
		var mat := c.material as ShaderMaterial
		if mat == null:
			continue
		mat.set_shader_parameter("parent_tex", sheet)
		mat.set_shader_parameter("inv_x", inv.x)
		mat.set_shader_parameter("inv_y", inv.y)
		mat.set_shader_parameter("inv_o", inv.origin)
		mat.set_shader_parameter("rect_pos", rect_pos)
		mat.set_shader_parameter("rect_size", size)
		mat.set_shader_parameter("uv_pos", uv_pos)
		mat.set_shader_parameter("uv_size", uv_size)
		mat.set_shader_parameter("flip", flip)
