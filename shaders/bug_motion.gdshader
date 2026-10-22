shader_type canvas_item;

uniform float motion_phase = 0.0;
uniform int motion_style = 0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec2 point = UV;
	vec2 sample_point = point;
	float flank = smoothstep(0.12, 0.34, abs(point.x - 0.5));
	if (motion_style == 0) {
		float wing = flank * (1.0 - smoothstep(0.48, 0.72, point.y));
		sample_point.y += sin(motion_phase * 35.0 + point.x * 5.0) * 0.034 * wing;
	} else if (motion_style == 2) {
		float wing = flank * (1.0 - smoothstep(0.72, 0.92, point.y));
		sample_point.x -= sign(point.x - 0.5) * sin(motion_phase * 13.0) * 0.055 * wing;
	} else {
		float legs = flank * smoothstep(0.56, 0.78, point.y);
		float alternating = mod(floor(point.y * 7.0), 2.0) * 3.14159265;
		sample_point.x += sin(motion_phase * 19.0 + alternating) * 0.026 * legs;
		sample_point.y += cos(motion_phase * 19.0 + alternating) * 0.012 * legs;
	}
	COLOR = texture(TEXTURE, clamp(sample_point, vec2(0.0), vec2(1.0))) * sprite_tint;
}
