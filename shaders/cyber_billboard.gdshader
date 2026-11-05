shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 primary_color : source_color = vec3(0.0, 0.92, 1.0);
uniform vec3 secondary_color : source_color = vec3(1.0, 0.15, 0.65);
uniform int channel_id = 0;
uniform float emission_strength : hint_range(0.5, 6.0) = 2.4;
uniform sampler2D bg_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_bg_tex = false;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// Outer Metallic Bezel Frame
	float border_x = smoothstep(0.0, 0.025, uv.x) * smoothstep(1.0, 0.975, uv.x);
	float border_y = smoothstep(0.0, 0.035, uv.y) * smoothstep(1.0, 0.965, uv.y);
	float in_screen = border_x * border_y;

	// Dark rich background gradient
	vec3 bg = mix(vec3(0.02, 0.04, 0.09), vec3(0.06, 0.02, 0.12), uv.y);
	if (use_bg_tex) {
		vec3 tex_c = texture(bg_tex, uv).rgb;
		bg = mix(bg, tex_c * 0.85, 0.65);
	}

	vec3 gfx = bg;
	int ch = channel_id % 4;

	if (ch == 0) {
		// Channel 0: Cyber-Portal Perspective Grid & Glowing Core (like left foreground screen in reference)
		vec2 p = (uv - 0.5) * 2.0;
		float r = length(p);
		float a = atan(p.y, p.x);
		float rays = pow(abs(sin(a * 12.0 + t * 0.8)), 4.0) * smoothstep(1.2, 0.1, r);
		float rings = smoothstep(0.06, 0.0, abs(fract(r * 3.5 - t * 0.6) - 0.5));
		float core = exp(-r * 3.2);
		gfx += primary_color * (rays * 0.9 + rings * 0.55 + core * 1.4);
		gfx += secondary_color * smoothstep(0.45, 0.0, abs(p.y)) * 0.35;
	} else if (ch == 1) {
		// Channel 1: Neon Silhouette Portrait & Vertical Cyber-Glyphs (like pink/magenta vertical ad screens)
		vec2 p = uv - vec2(0.5, 0.58);
		float head = smoothstep(0.22, 0.19, length(p * vec2(1.2, 1.0)));
		float shoulders = smoothstep(0.42, 0.36, abs(uv.x - 0.5)) * step(0.55, uv.y);
		float visor = smoothstep(0.04, 0.01, abs(uv.y - 0.54)) * step(abs(uv.x - 0.5), 0.16);
		float halo = smoothstep(0.34, 0.30, abs(length(p * vec2(1.1, 1.0)) - 0.28));
		gfx = mix(bg, secondary_color * 0.55, clamp(head + shoulders, 0.0, 1.0));
		gfx += primary_color * (halo * 1.1 + visor * 1.8);
		// Side data bars
		float bar_col = step(0.82, uv.x) * step(uv.x, 0.93);
		float bar_seg = step(0.35, fract(uv.y * 18.0 - t * 1.5));
		gfx += primary_color * bar_col * bar_seg * 0.9;
	} else if (ch == 2) {
		// Channel 2: Synthwave Audio Spectrum Equalizer & Financial Telemetry Wave
		float cols = 20.0;
		float cid = floor(uv.x * cols);
		float c_uv = fract(uv.x * cols);
		float bar_w = smoothstep(0.08, 0.15, c_uv) * smoothstep(0.92, 0.85, c_uv);
		float h = 0.22 + 0.58 * (0.5 + 0.5 * sin(cid * 0.75 + t * 3.2) * cos(cid * 0.35 - t * 1.8));
		float inv_y = 1.0 - uv.y;
		float is_lit = step(inv_y, h) * step(0.12, inv_y);
		float seg = step(0.22, fract(inv_y * 24.0));
		vec3 bar_c = mix(primary_color, secondary_color, clamp(inv_y / 0.8, 0.0, 1.0));
		gfx += bar_c * bar_w * is_lit * seg * 1.15;
	} else {
		// Channel 3: Biotech Helix / Horizon Grid & Scrolling Data Banner
		vec2 p = uv * 2.0 - 1.0;
		float wave1 = smoothstep(0.06, 0.01, abs(p.y - 0.35 * sin(p.x * 4.5 + t * 2.2)));
		float wave2 = smoothstep(0.06, 0.01, abs(p.y + 0.35 * sin(p.x * 4.5 + t * 2.2)));
		float rungs = smoothstep(0.08, 0.02, abs(fract(p.x * 6.0 + t * 0.5) - 0.5)) * step(abs(p.y), 0.36);
		gfx += primary_color * wave1 * 1.3 + secondary_color * wave2 * 1.3;
		gfx += mix(primary_color, secondary_color, 0.5) * rungs * 0.65;
	}

	// Top & Bottom HUD Header/Footer Ticker Bars
	float header = step(uv.y, 0.12) * step(0.04, uv.y);
	float ticker = step(0.86, uv.y) * step(uv.y, 0.95);
	float ticker_blocks = step(0.3, hash21(vec2(floor(uv.x * 32.0 + t * 4.0), floor(uv.y * 12.0))));
	gfx = mix(gfx, primary_color * 0.9, header * 0.45);
	gfx += secondary_color * ticker * ticker_blocks * 0.85;

	// LED Pixel Matrix & Subtle Scanlines
	float scanline = 0.88 + 0.12 * sin(uv.y * 180.0 - t * 6.0);
	gfx *= scanline;

	// Outer glowing neon rim around the screen bezel
	float rim = smoothstep(0.04, 0.015, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
	vec3 bezel_col = vec3(0.03, 0.04, 0.05) + primary_color * rim * 1.2;

	vec3 final_col = mix(bezel_col, gfx * emission_strength, in_screen);
	ALBEDO = final_col;
}
