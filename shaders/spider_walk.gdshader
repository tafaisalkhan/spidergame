shader_type canvas_item;

uniform float gait_phase = 0.0;
uniform float gait_strength : hint_range(0.0, 1.0) = 0.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec2 point = UV;
	float side = sign(point.x - 0.5);
	float leg_area = smoothstep(0.12, 0.30, abs(point.x - 0.5));
	float leg_row = floor(point.y * 5.0);
	float alternating = mod(leg_row, 2.0) * 3.14159265;
	float step_cycle = gait_phase + alternating + (side > 0.0 ? 3.14159265 : 0.0);
	vec2 step_offset = vec2(sin(step_cycle) * 0.031, cos(step_cycle) * 0.019);
	vec2 sample_point = clamp(point - step_offset * leg_area * gait_strength, vec2(0.0), vec2(1.0));
	COLOR = texture(TEXTURE, sample_point) * sprite_tint;
}
