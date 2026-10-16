shader_type canvas_item;
// Krallık / bölge katmanı: yarı saydam dolgu + sınıra yakın koyulaşan renk + sınır çizgisi.

#include "res://shaders/map_common.gdshaderinc"

uniform sampler2D region_idx : filter_nearest, repeat_disable;
uniform sampler2D region_pal : filter_nearest, repeat_disable;   // 256x1
uniform bool fancy = true;

int region_at(vec2 cell) {
	vec2 c = clamp(floor(cell), vec2(0.0), map_cells - 1.0);
	return int(texture(region_idx, (c + 0.5) / map_cells).r * 255.0 + 0.5);
}

// Bölgesiz deniz hücresi kıyı sayılır; kıyı çizgisini zaten arazi çiziyor.
bool sea_gap(vec2 cell, int r) {
	return r == 0 && terrain_is_water(terrain_at(cell));
}

bool differs(vec2 a, int ra, vec2 b) {
	int rb = region_at(b);
	if (rb == ra) return false;
	if (fancy && (sea_gap(a, ra) || sea_gap(b, rb))) return false;
	return true;
}

int nonzero_neighbor(vec2 wc, int r, float d) {
	if (r != 0) return r;
	int n = region_at(wc + vec2(d, 0.0));
	if (n == 0) n = region_at(wc - vec2(d, 0.0));
	if (n == 0) n = region_at(wc + vec2(0.0, d));
	if (n == 0) n = region_at(wc - vec2(0.0, d));
	return n;
}

void fragment() {
	vec2 cell = UV * map_cells;
	float px = fwidth(cell.x);
	vec2 wc = fancy ? warp_cell(cell) : cell;
	int r = region_at(wc);

	float bw = max(0.1, px * 1.4);
	bool border = differs(wc, r, wc + vec2(bw, 0.0)) || differs(wc, r, wc - vec2(bw, 0.0))
			|| differs(wc, r, wc + vec2(0.0, bw)) || differs(wc, r, wc - vec2(0.0, bw));
	float nw = 0.9;
	bool near = r != 0 && (differs(wc, r, wc + vec2(nw, 0.0)) || differs(wc, r, wc - vec2(nw, 0.0))
			|| differs(wc, r, wc + vec2(0.0, nw)) || differs(wc, r, wc - vec2(0.0, nw)));

	bool hidden = false;
	if (fancy && r != 0) {
		// yumuşatılmış kıyıda denize taşan dolguyu gizle
		hidden = water_smooth(wc, 0.5) > 0.5 && !terrain_is_water(terrain_at(wc));
	}

	vec4 out_col = vec4(0.0);
	if (r != 0 && !hidden) {
		vec3 c = texelFetch(region_pal, ivec2(r, 0), 0).rgb;
		out_col = vec4(c, near ? 0.48 : 0.26);
	}
	if (border) {
		int br = nonzero_neighbor(wc, r, bw);
		vec3 c = texelFetch(region_pal, ivec2(br, 0), 0).rgb;
		out_col = vec4(c * 0.6, 0.85);
	}
	COLOR = out_col;
}
