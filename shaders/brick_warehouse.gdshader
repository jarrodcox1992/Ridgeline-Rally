shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 brick_color_primary : source_color = vec3(0.42, 0.18, 0.12);
uniform vec3 brick_color_secondary : source_color = vec3(0.28, 0.12, 0.09);
uniform vec3 mortar_color : source_color = vec3(0.55, 0.53, 0.50);
uniform vec3 window_lit_color : source_color = vec3(1.0, 0.82, 0.45);
uniform vec3 soot_color : source_color = vec3(0.08, 0.08, 0.09);
uniform sampler2D brick_albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D brick_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete_albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_pbr_tex = false;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 local_pos;
varying vec3 local_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	local_pos = VERTEX + vec3(500.0);
	local_normal = NORMAL;
}

void fragment() {
	vec3 n = abs(local_normal);
	vec2 wall_uv = vec2((n.x > 0.5) ? local_pos.z : local_pos.x, world_pos.y);
	
	// Brick coursing dimensions in metres
	float brick_w = 0.28;
	float brick_h = 0.10;
	
	// Ground floor retail / loading bay zone (y < 4.5m)
	bool is_ground_floor = (world_pos.y < 4.5);
	// Roof cornice zone
	bool is_roof = (n.y > 0.6);
	
	if (is_roof) {
		// Dark gravel tar roof
		ALBEDO = vec3(0.12, 0.13, 0.14);
		ROUGHNESS = 0.85;
		METALLIC = 0.1;
	} else if (is_ground_floor) {
		// Weathered concrete base / rust-stained warehouse foundation
		float stone_block = step(0.04, fract(wall_uv.x / 1.6)) * step(0.04, fract(wall_uv.y / 1.2));
		vec3 base_stone = mix(vec3(0.22, 0.23, 0.24), vec3(0.32, 0.30, 0.28), stone_block);
		
		// Corrugated roll-up warehouse bay doors every 12 metres
		float bay_pos = mod(wall_uv.x + 2.0, 12.0);
		if (bay_pos < 4.2 && world_pos.y > 0.2 && world_pos.y < 3.8) {
			float ribs = sin(world_pos.y * 36.0);
			ALBEDO = vec3(0.18, 0.20, 0.22) * (0.8 + 0.25 * ribs);
			METALLIC = 0.85;
			ROUGHNESS = 0.45;
		} else {
			vec3 tex_c = use_pbr_tex ? texture(concrete_albedo_tex, wall_uv * 0.35).rgb : vec3(1.0);
			ALBEDO = base_stone * mix(vec3(1.0), tex_c * 1.35, 0.65);
			ROUGHNESS = 0.75;
			METALLIC = 0.05;
		}
	} else {
		// Multi-pane factory warehouse windows
		// Floor height ~3.6m, window width ~2.2m
		float floor_idx = floor(world_pos.y / 3.6);
		float floor_y = mod(world_pos.y, 3.6);
		float col_idx = floor(wall_uv.x / 3.8);
		float col_x = mod(wall_uv.x, 3.8);
		
		bool is_window_slot = (col_x > 0.8 && col_x < 3.0 && floor_y > 0.9 && floor_y < 2.9);
		
		if (is_window_slot) {
			// Iron muntin window grid (3 panes wide x 4 panes tall)
			vec2 pane_uv = vec2((col_x - 0.8) / 2.2, (floor_y - 0.9) / 2.0);
			float grid_x = fract(pane_uv.x * 3.0);
			float grid_y = fract(pane_uv.y * 4.0);
			bool is_muntin = (grid_x < 0.08 || grid_x > 0.92 || grid_y < 0.08 || grid_y > 0.92);
			
			if (is_muntin) {
				// Black painted structural iron frame
				ALBEDO = vec3(0.08, 0.09, 0.10);
				METALLIC = 0.85;
				ROUGHNESS = 0.35;
			} else {
				// Glass pane: daytime reflection, night warm interior glow
				float room_rnd = hash21(vec2(col_idx * 13.1, floor_idx * 7.7));
				float lit_intensity = (room_rnd > 0.42) ? 1.0 : 0.04;
				
				ALBEDO = vec3(0.06, 0.08, 0.10);
				ROUGHNESS = 0.12;
				METALLIC = 0.9;
				EMISSION = window_lit_color * lit_intensity * 1.8;
			}
		} else {
			// Brick coursing with staggered running bond
			float row = floor(wall_uv.y / brick_h);
			float x_offset = (mod(row, 2.0) == 0.0) ? 0.0 : (brick_w * 0.5);
			vec2 b_coord = vec2(wall_uv.x + x_offset, wall_uv.y);
			
			float mort_x = step(0.018, mod(b_coord.x, brick_w));
			float mort_y = step(0.014, mod(b_coord.y, brick_h));
			float is_brick = mort_x * mort_y;
			
			float b_hash = hash21(vec2(floor(b_coord.x / brick_w), row));
			vec3 var_brick = mix(brick_color_primary, brick_color_secondary, b_hash);
			
			// Soot and water runoff stains below window openings
			float runoff = smoothstep(0.7, 0.0, abs(col_x - 1.9)) * smoothstep(0.9, 0.0, floor_y);
			var_brick = mix(var_brick, soot_color, runoff * 0.45);
			
			vec3 proc_brick = mix(mortar_color, var_brick, is_brick);
			if (use_pbr_tex) {
				vec3 pbr_b = texture(brick_albedo_tex, wall_uv * 0.45).rgb;
				ALBEDO = mix(proc_brick, pbr_b * brick_color_primary * 2.4, 0.65) * (1.0 - runoff * 0.35);
				NORMAL_MAP = texture(brick_normal_tex, wall_uv * 0.45).rgb;
			} else {
				ALBEDO = proc_brick;
			}
			ROUGHNESS = mix(0.92, 0.82, is_brick);
			METALLIC = 0.02;
		}
	}
}
