shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 steam_color : source_color = vec4(0.92, 0.94, 0.96, 0.22);
uniform float speed : hint_range(0.1, 3.0) = 0.8;
uniform float softness : hint_range(0.1, 2.0) = 0.6;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 2.0;
	float alpha = smoothstep(1.0, 0.1, dist);
	
	// Temporal turbulent swirl
	float swirl = sin(UV.y * 12.0 - TIME * speed * 2.5) * cos(UV.x * 12.0 + TIME * speed * 1.8);
	alpha *= clamp(0.7 + 0.3 * swirl, 0.0, 1.0);
	
	// Vertical rise fade
	alpha *= smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.45, UV.y);
	
	ALBEDO = steam_color.rgb;
	ALPHA = alpha * steam_color.a;
}
