shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float bubble_alpha : hint_range(0.0, 1.0) = 1;

void fragment() {
	float mask = texture(TEXTURE, UV).a;
	vec4 screen = texture(screen_tex, SCREEN_UV);
	vec4 black = vec4(0.0, 0.0, 0.0, screen.a * bubble_alpha);
	COLOR = mix(screen, black, mask);
}