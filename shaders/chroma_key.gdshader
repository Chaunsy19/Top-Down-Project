shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(0.0, 0.502, 0.502);
uniform float tolerance : hint_range(0.0, 0.5) = 0.12;
uniform float edge_softness : hint_range(0.001, 0.2) = 0.025;

void fragment() {
	vec4 sampled_color = texture(TEXTURE, UV);
	float key_distance = distance(sampled_color.rgb, key_color);
	sampled_color.a *= smoothstep(tolerance, tolerance + edge_softness, key_distance);
	COLOR = sampled_color * COLOR;
}
