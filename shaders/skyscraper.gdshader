shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 facade_color : source_color = vec3(0.18, 0.20, 0.24);
uniform vec3 glass_color : source_color = vec3(0.06, 0.12, 0.18);
uniform vec3 spandrel_color : source_color = vec3(0.16, 0.18, 0.22);
uniform vec3 lit_color_1 : source_color = vec3(1.0, 0.90, 0.72); // Warm corporate office
uniform vec3 lit_color_2 : source_color = vec3(0.68, 0.88, 1.0);  // Cool LED tech lab
uniform vec3 lit_color_3 : source_color = vec3(1.0, 0.68, 0.38);  // Executive amber lounge
uniform float window_width = 2.4;
uniform float floor_height = 3.6;
uniform float frame_width = 0.20;
uniform float night_emission : hint_range(0.0, 5.0) = 1.35;
uniform sampler2D concrete_albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D storefront_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_pbr_tex = false;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_local_pos;
varying vec3 v_local_normal;
varying vec2 v_bseed;

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local_pos = VERTEX + vec3(500.0);
	v_local_normal = NORMAL;
	v_bseed = floor(MODEL_MATRIX[3].xz * 0.25);
}

void fragment() {
	float u = (abs(v_local_normal.x) > abs(v_local_normal.z)) ? v_local_pos.z : v_local_pos.x;
	vec2 wall_uv = vec2(u, v_world_pos.y) * 0.28;
	vec3 pbr_conc = use_pbr_tex ? texture(concrete_albedo_tex, wall_uv).rgb : vec3(0.75);

	if (abs(v_local_normal.y) > 0.7) {
		// Roof slab: weathered concrete & gravel ballast with PBR detail
		ALBEDO = vec3(0.16, 0.18, 0.20) * (0.7 + 0.5 * pbr_conc);
		METALLIC = 0.2;
		ROUGHNESS = 0.86;
		EMISSION = vec3(0.0);
	} else if (v_world_pos.y < 4.8) {
		// Ground-Floor Bustling Retail & Cafe Arcade with Illuminated Storefront Photography & Bronze Mullions
		vec2 shop_coord = vec2(u / 5.6, v_world_pos.y / 4.8);
		vec2 sf = fract(shop_coord);
		float is_display_glass = step(0.12, sf.x) * step(sf.x, 0.88) * step(0.08, sf.y) * step(sf.y, 0.86);

		float splash = smoothstep(1.4, 0.0, v_world_pos.y) * 0.45;
		vec3 pier_col = mix(facade_color * 0.9, facade_color * 0.45, splash) * (0.68 + 0.55 * pbr_conc);

		if (is_display_glass > 0.5) {
			vec2 s_uv = vec2((sf.x - 0.12) / 0.76, 1.0 - (sf.y - 0.08) / 0.78);
			vec3 store_img = use_pbr_tex ? texture(storefront_tex, s_uv).rgb : vec3(0.95, 0.82, 0.62);
			// Warm recessed storefront ceiling wash + vertical mullion divider
			float sub_mullion = step(0.018, abs(sf.x - 0.5));
			float ceiling_glow = smoothstep(0.2, 0.95, sf.y);
			ALBEDO = store_img * 0.38 * sub_mullion;
			METALLIC = 0.85;
			ROUGHNESS = 0.08;
			CLEARCOAT = 1.0;
			CLEARCOAT_ROUGHNESS = 0.04;
			EMISSION = store_img * (0.85 + 0.55 * ceiling_glow) * sub_mullion;
		} else {
			if (use_pbr_tex) {
				NORMAL_MAP = texture(concrete_normal_tex, wall_uv).rgb;
			}
			ALBEDO = pier_col;
			METALLIC = 0.25;
			ROUGHNESS = 0.72;
			EMISSION = vec3(0.0);
		}
	} else {
		// Tower & Podium Curtain Wall with Structural Spandrels, PBR Concrete Frame & 3D Interior Room Mapping
		float v = v_world_pos.y;
		vec2 win_coord = vec2(u / window_width, v / floor_height);
		vec2 f = fract(win_coord);
		vec2 win_id = floor(win_coord) + v_bseed;

		float spandrel_ratio = 0.85 / floor_height;
		bool is_spandrel = (f.y > (1.0 - spandrel_ratio));

		if (is_spandrel) {
			// Structural floor slab spandrel with architectural ventilation louvers & PBR normal map
			float louver = sin(f.y * 42.0) * 0.14;
			float panel_seam = step(0.03, f.x) * step(f.x, 0.97);
			if (use_pbr_tex) {
				NORMAL_MAP = texture(concrete_normal_tex, wall_uv).rgb;
			}
			ALBEDO = spandrel_color * (0.85 + louver) * (0.72 + 0.45 * pbr_conc) * (0.75 + 0.25 * panel_seam);
			METALLIC = 0.65;
			ROUGHNESS = 0.48;
			EMISSION = vec3(0.0);
		} else {
			float fx = frame_width * 0.5;
			float fy = frame_width * 0.35;
			float win_h = 1.0 - spandrel_ratio;
			float is_glass = step(fx, f.x) * step(f.x, 1.0 - fx) * step(fy, f.y) * step(f.y, win_h - fy);

			if (is_glass < 0.5) {
				// Extruded structural aluminum/concrete vertical mullion
				if (use_pbr_tex) {
					NORMAL_MAP = texture(concrete_normal_tex, wall_uv).rgb;
				}
				ALBEDO = facade_color * (0.70 + 0.50 * pbr_conc);
				METALLIC = 0.55;
				ROUGHNESS = 0.52;
				EMISSION = vec3(0.0);
			} else {
				// Normalized interior pane coordinates [0..1]
				vec2 p_uv = vec2((f.x - fx) / (1.0 - 2.0 * fx), (f.y - fy) / (win_h - 2.0 * fy));

				// Deep window embrasure ambient occlusion around perimeter frame
				float edge_u = min(p_uv.x, 1.0 - p_uv.x);
				float edge_v = min(p_uv.y, 1.0 - p_uv.y);
				float embrasure_ao = smoothstep(0.0, 0.12, min(edge_u, edge_v));

				// Per-window randomized interior properties
				float h = hash21(win_id);
				float h_blind = hash21(win_id + vec2(13.7, 29.3));
				float h_furn = hash21(win_id + vec2(41.2, 7.9));

				// Venetian Blinds covering upper portion of some windows
				float blind_drop = (h_blind > 0.45) ? mix(0.62, 0.92, fract(h_blind * 7.3)) : 1.05;
				float in_blind = step(blind_drop, p_uv.y);
				float blind_slat = 0.65 + 0.35 * sin(p_uv.y * 78.0);

				// Interior Room Depth: ceiling fluorescent fixture at top, back wall gradient, desk & partition silhouettes
				float ceiling_strip = smoothstep(0.68, 0.96, p_uv.y) * step(0.18, p_uv.x) * step(p_uv.x, 0.82);
				float wall_grad = mix(0.28, 0.85, p_uv.y);
				float partition_pos = mix(0.25, 0.75, h_furn);
				float has_partition = 1.0 - 0.55 * smoothstep(0.08, 0.0, abs(p_uv.x - partition_pos)) * step(p_uv.y, 0.72);
				float desk_silhouette = step(0.24, p_uv.y); // Dark office desk & monitor silhouette across lower 24% of window

				vec3 lit_col = lit_color_1;
				if (h > 0.84) {
					lit_col = lit_color_2;
				} else if (h > 0.66) {
					lit_col = lit_color_3;
				}

				// 45% of rooms actively illuminated; others show dark reflective architectural curtain-wall glass
				float is_lit = step(0.55, h);
				float interior_lum = (wall_grad * has_partition * desk_silhouette + ceiling_strip * 0.75);
				interior_lum = mix(interior_lum, interior_lum * 0.42 * blind_slat, in_blind);

				// Subtle daytime interior visibility even in unlit offices
				vec3 dark_room = glass_color * (0.55 + 0.45 * p_uv.y) * desk_silhouette * embrasure_ao;
				vec3 lit_room = lit_col * interior_lum * embrasure_ao;

				ALBEDO = mix(dark_room, lit_room * 0.35, is_lit);
				METALLIC = 0.90;
				ROUGHNESS = 0.06;
				SPECULAR = 0.95;
				CLEARCOAT = 1.0;
				CLEARCOAT_ROUGHNESS = 0.04;
				EMISSION = is_lit * lit_room * night_emission;
			}
		}
	}
}
