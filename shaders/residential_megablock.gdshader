shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 concrete_color : source_color = vec3(0.48, 0.47, 0.45);
uniform vec3 spandrel_color : source_color = vec3(0.32, 0.34, 0.36);
uniform vec3 glass_dark : source_color = vec3(0.05, 0.08, 0.12);
uniform vec3 warm_light : source_color = vec3(1.0, 0.84, 0.52);
uniform vec3 cool_light : source_color = vec3(0.70, 0.88, 1.0);
uniform sampler2D concrete_albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D storefront_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_pbr_tex = false;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 local_pos;
varying vec3 local_normal;
varying vec2 bseed;

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	local_pos = VERTEX + vec3(500.0);
	local_normal = NORMAL;
	bseed = floor(MODEL_MATRIX[3].xz * 0.25);
}

void fragment() {
	vec3 n = abs(local_normal);
	bool is_roof = (n.y > 0.6);

	if (is_roof) {
		ALBEDO = vec3(0.15, 0.16, 0.18);
		ROUGHNESS = 0.88;
		METALLIC = 0.08;
	} else if (world_pos.y < 4.2) {
		// Ground-floor corner bodega / ramen bar / retail storefront
		float u = (n.x > 0.5) ? local_pos.z : local_pos.x;
		float shop_u = fract(u / 6.0);
		bool is_store = (shop_u > 0.14 && shop_u < 0.86 && world_pos.y > 0.55 && world_pos.y < 3.65);

		if (is_store) {
			vec2 s_uv = vec2((shop_u - 0.14) / 0.72, 1.0 - (world_pos.y - 0.55) / 3.10);
			vec3 s_col = use_pbr_tex ? texture(storefront_tex, s_uv).rgb : vec3(1.0, 0.90, 0.72);
			float mullion = step(0.016, abs(shop_u - 0.5));
			ALBEDO = s_col * 0.35 * mullion;
			ROUGHNESS = 0.08;
			METALLIC = 0.85;
			CLEARCOAT = 1.0;
			CLEARCOAT_ROUGHNESS = 0.04;
			EMISSION = s_col * 1.25 * mullion;
		} else {
			float damp = smoothstep(1.5, 0.0, world_pos.y);
			vec2 c_uv = vec2(u, world_pos.y) * 0.28;
			vec3 c_tex = use_pbr_tex ? texture(concrete_albedo_tex, c_uv).rgb : vec3(0.8);
			if (use_pbr_tex) {
				NORMAL_MAP = texture(concrete_normal_tex, c_uv).rgb;
			}
			ALBEDO = mix(concrete_color * 0.82, concrete_color * 0.45, damp) * (0.65 + 0.55 * c_tex);
			ROUGHNESS = 0.82;
			METALLIC = 0.08;
		}
	} else {
		float u = (n.x > 0.5) ? local_pos.z : local_pos.x;
		float floor_idx = floor(world_pos.y / 3.2) + bseed.y;
		float floor_y = mod(world_pos.y, 3.2);
		float unit_idx = floor(u / 3.4) + bseed.x;
		float unit_x = mod(u, 3.4);

		float seam_x = step(0.05, unit_x) * step(unit_x, 3.35);
		float seam_y = step(0.05, floor_y) * step(floor_y, 3.15);
		float is_panel = seam_x * seam_y;

		bool is_window = (unit_x > 0.65 && unit_x < 2.75 && floor_y > 0.75 && floor_y < 2.55);

		if (is_window) {
			vec2 p_uv = vec2((unit_x - 0.65) / 2.10, (floor_y - 0.75) / 1.80);
			float edge_dist = min(min(p_uv.x, 1.0 - p_uv.x), min(p_uv.y, 1.0 - p_uv.y));
			float embrasure_ao = smoothstep(0.0, 0.14, edge_dist);
			float center_mullion = step(0.022, abs(p_uv.x - 0.5));

			float rnd = hash21(vec2(unit_idx * 17.3, floor_idx * 9.1));
			float rnd_curtain = hash21(vec2(unit_idx * 31.7, floor_idx * 5.3));
			float is_lit = step(0.52, rnd);
			vec3 lit_c = (rnd > 0.78) ? cool_light : warm_light;

			// Interior apartment depth: ceiling lamp glow, side curtains & lower windowsill/sofa silhouette
			float curtain = smoothstep(0.12, 0.28, p_uv.x) * smoothstep(0.12, 0.28, 1.0 - p_uv.x);
			float blind_drop = (rnd_curtain > 0.5) ? 0.68 : 1.05;
			float blind_shade = (p_uv.y > blind_drop) ? (0.45 + 0.35 * sin(p_uv.y * 65.0)) : 1.0;
			float room_grad = (0.35 + 0.65 * p_uv.y) * step(0.20, p_uv.y) * mix(0.55, 1.0, curtain) * blind_shade;

			ALBEDO = mix(glass_dark * embrasure_ao, lit_c * room_grad * 0.32, is_lit) * center_mullion;
			ROUGHNESS = 0.07;
			METALLIC = 0.88;
			SPECULAR = 0.92;
			CLEARCOAT = 1.0;
			CLEARCOAT_ROUGHNESS = 0.04;
			EMISSION = is_lit * lit_c * room_grad * embrasure_ao * center_mullion * 1.35;
		} else {
			float runoff = smoothstep(0.6, 0.0, abs(unit_x - 1.7)) * smoothstep(0.75, 0.0, floor_y);
			vec3 panel_col = mix(concrete_color, spandrel_color, 0.35);
			panel_col = mix(panel_col, panel_col * 0.6, runoff * 0.42);
			if (use_pbr_tex) {
				vec2 c_uv = vec2(u, world_pos.y) * 0.28;
				panel_col *= (0.65 + 0.55 * texture(concrete_albedo_tex, c_uv).rgb);
				NORMAL_MAP = texture(concrete_normal_tex, c_uv).rgb;
			}
			ALBEDO = mix(vec3(0.16, 0.17, 0.19), panel_col, is_panel);
			ROUGHNESS = 0.76;
			METALLIC = 0.08;
		}
	}
}
