shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 water_base_color : source_color = vec3(0.02, 0.03, 0.04);
uniform float iridescence_strength : hint_range(0.0, 2.0) = 0.85;

varying vec3 v_world_pos;
varying vec3 v_normal;

// Cosine rainbow palette for thin-film hydrocarbon interference (Newton's rings)
vec3 rainbow(float t) {
	return 0.5 + 0.5 * cos(6.28318 * (vec3(1.0, 1.0, 1.0) * t + vec3(0.0, 0.33, 0.67)));
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - v_world_pos);
	float NdotV = clamp(dot(v_normal, view_dir), 0.0, 1.0);
	
	// Thin-film interference varies with view angle and surface spatial variation
	float film_thickness = sin(v_world_pos.x * 2.8 + v_world_pos.z * 3.4) * 0.5 + 0.5;
	float fringe = fract(film_thickness * 2.2 + (1.0 - NdotV) * 1.6);
	vec3 oil_color = rainbow(fringe);
	
	ALBEDO = mix(water_base_color, oil_color * 0.35, iridescence_strength * 0.4);
	METALLIC = 0.95;
	ROUGHNESS = 0.04;
	SPECULAR = 1.0;
	EMISSION = oil_color * iridescence_strength * 0.4 * (1.0 - NdotV);
}
