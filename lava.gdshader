shader_type canvas_item;

uniform sampler2D parent_tex;
uniform vec2 inv_x;
uniform vec2 inv_y;
uniform vec2 inv_o;
uniform vec2 rect_pos;     // current frame's rect in the parent's local space
uniform vec2 rect_size;
uniform vec2 uv_pos;       // where the frame sits inside its sprite sheet (0..1)
uniform vec2 uv_size = vec2(1.0);
uniform vec2 flip;         // x = flip_h, y = flip_v
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.05;

// Global-X clip (only active when keep_left == true)
uniform float clip_global_x = 100.0;
uniform bool keep_left = false;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Keep pixels to the left of clip_global_x; do nothing when keep_left is false.
	if (keep_left && world_pos.x > clip_global_x) {
		discard;
	}

	vec2 local = inv_x * world_pos.x + inv_y * world_pos.y + inv_o;
	vec2 t = (local - rect_pos) / rect_size;

	if (t.x >= 0.0 && t.x <= 1.0 && t.y >= 0.0 && t.y <= 1.0) {
		if (flip.x > 0.5) t.x = 1.0 - t.x;
		if (flip.y > 0.5) t.y = 1.0 - t.y;
		float a = texture(parent_tex, uv_pos + t * uv_size).a;
		if (a > alpha_threshold) {
			discard;
		}
	}
}