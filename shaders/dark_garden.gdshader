shader_type canvas_item;

void fragment() {
	vec4 garden = texture(TEXTURE, UV);
	float brightness = dot(garden.rgb, vec3(0.299, 0.587, 0.114));
	vec3 muted = mix(garden.rgb, vec3(brightness), 0.68);
	vec3 scenery = muted * vec3(0.34, 0.37, 0.42) + vec3(0.04, 0.047, 0.055);
	COLOR = vec4(scenery, garden.a);
}
