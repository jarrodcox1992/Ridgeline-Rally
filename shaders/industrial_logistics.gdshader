shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 metal_color : source_color = vec3(0.35, 0.38, 0.42);
uniform vec3 rust_color : source_color = vec3(0.48, 0.22, 0.12);
uniform vec3 concrete_base_color : source_color = vec3(0.26, 0.28, 0.30);
uniform vec3 hazard_yellow : source_color = vec3(0.95, 0.78, 0.08);
uniform sampler2D iron_albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D iron_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_pbr_tex = false;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	local_pos = VERTEX + vec3(500.0);
	local_normal = NORMAL;
}

void fragment() {
	vec3 n = abs(local_normal);
	bool is_roof = (n.y > 0.6);
	
	if (is_roof) {
		// Industrial galvanized sheet metal roof with drainage seams
		float ribs = sin(local_pos.x * 24.0) * 0.5 + 0.5;
		ALBEDO = mix(vec3(0.25, 0.27, 0.29), vec3(0.18, 0.19, 0.21), ribs);
		METALLIC = 0.8;
		ROUGHNESS = 0.45;
	} else if (world_pos.y < 1.4) {
		// Heavy reinforced concrete loading dock foundation & splash zone
		float u = (n.x > 0.5) ? local_pos.z : local_pos.x;
		float panel_joint = step(0.03, fract(u / 4.0));
		float damp = smoothstep(1.4, 0.0, world_pos.y);
		vec3 base_col = mix(concrete_base_color * 0.7, concrete_base_color, panel_joint);
		ALBEDO = mix(base_col, base_col * 0.55, damp);
		ROUGHNESS = 0.85;
		METALLIC = 0.05;
	} else {
		// Corrugated industrial metal siding & freight overhead doors
		float u = (n.x > 0.5) ? local_pos.z : local_pos.x;
		
		// Check for overhead freight roll-up door bays every 14 metres
		float bay_pos = mod(u + 2.0, 14.0);
		bool is_bay_door = (bay_pos < 5.2 && world_pos.y < 5.4);
		
		if (is_bay_door) {
			// Overhead roll-up freight door with yellow/black hazard perimeter
			bool is_hazard_border = (bay_pos < 0.35 || bay_pos > 4.85 || world_pos.y > 5.0);
			if (is_hazard_border) {
				float stripe = fract((u + world_pos.y) * 2.0);
				float is_yellow = step(0.5, stripe);
				ALBEDO = mix(vec3(0.1, 0.1, 0.1), hazard_yellow, is_yellow);
				ROUGHNESS = 0.5;
				METALLIC = 0.2;
			} else {
				// Corrugated roll-up curtain
				float corrugation = sin(world_pos.y * 14.0);
				ALBEDO = vec3(0.22, 0.24, 0.26) * (0.90 + 0.12 * corrugation);
				METALLIC = 0.85;
				ROUGHNESS = 0.38;
			}
		} else {
			// Corrugated siding with 2K PBR corrugated iron texture & rust patina near foundation
			float rust_wear = smoothstep(3.5, 1.4, world_pos.y) * 0.45;
			vec3 siding_col = mix(metal_color, rust_color, rust_wear);
			if (use_pbr_tex) {
				vec2 i_uv = vec2(u, world_pos.y) * 0.18;
				siding_col *= (0.72 + 0.45 * texture(iron_albedo_tex, i_uv).rgb);
				NORMAL_MAP = texture(iron_normal_tex, i_uv).rgb;
			}
			ALBEDO = siding_col;
			METALLIC = mix(0.75, 0.2, rust_wear);
			ROUGHNESS = mix(0.42, 0.85, rust_wear);
		}
	}
}
