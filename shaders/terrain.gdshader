shader_type canvas_item;
// Arazi katmanı. fancy=false iken klasik kare hücre görünümü.

#include "res://shaders/map_common.gdshaderinc"

uniform bool fancy = true;
uniform bool parchment = false;

const vec3 INK = vec3(0.16, 0.12, 0.08);

vec3 pal(int t) {
	return texelFetch(palette, ivec2(t, 0), 0).rgb;
}

int style_of(int t) {
	return int(texelFetch(palette, ivec2(t, 1), 0).g * 255.0 + 0.5);
}

float mortar(vec2 p, float w) {
	vec2 f = fract(p);
	float e = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	return 1.0 - smoothstep(w * 0.5, w, e);
}

vec3 land_detail(vec3 col, int style, vec2 cell) {
	if (style == 1) { // orman: ağaç tepeleri
		float b = fbm(cell * 1.4);
		col *= mix(0.8, 1.08, smoothstep(0.3, 0.7, b));
		col += vec3(0.03, 0.05, 0.0) * smoothstep(0.6, 0.8, fbm(cell * 3.0 + 4.0));
	} else if (style == 2) { // dağ / tepe: gölgelendirme
		// yumuşak sırtlar: düşük frekanslı yükseklikten ışık-gölge
		vec2 p = cell * 0.5;
		float h = vnoise(p) + 0.5 * vnoise(p * 2.1 + 3.0);
		float hx = vnoise(p + vec2(0.15, 0.0)) + 0.5 * vnoise((p + vec2(0.15, 0.0)) * 2.1 + 3.0);
		float hy = vnoise(p + vec2(0.0, 0.15)) + 0.5 * vnoise((p + vec2(0.0, 0.15)) * 2.1 + 3.0);
		float slope = ((h - hx) + (h - hy)) / 0.15;
		col *= 0.97 + clamp(slope * 0.18, -0.22, 0.22);
		col *= 0.95 + 0.08 * vnoise(cell * 3.0);
	} else if (style == 3) { // kum / çöl: kum tepeleri
		col *= 0.95 + 0.07 * sin(cell.y * 4.0 + cell.x * 0.8 + fbm(cell * 0.7) * 9.0);
	} else if (style == 4) { // kar
		col = mix(col, vec3(0.82, 0.88, 1.0), 0.25 * fbm(cell * 1.5));
	} else if (style == 5) { // kaldırım / taş zemin
		vec2 s = cell * 2.0;
		s.x += floor(s.y) * 0.5;
		float stone = 0.85 + 0.25 * hash21(floor(s));
		col = mix(col * stone, col * 0.55, mortar(s, 0.12));
	} else if (style == 6) { // ahşap zemin: tahtalar
		float y = cell.y * 3.0;
		float row = floor(y);
		float x = cell.x * 0.5 + hash21(vec2(row, 3.0)) * 7.0;
		float grain = sin(cell.x * 9.0 + vnoise(vec2(cell.x * 1.5, y * 6.0)) * 5.0);
		col *= 0.88 + 0.06 * grain + 0.16 * hash21(vec2(row, floor(x)));
		float seam = max(1.0 - smoothstep(0.03, 0.08, min(fract(y), 1.0 - fract(y))),
				1.0 - smoothstep(0.015, 0.03, min(fract(x), 1.0 - fract(x))));
		col = mix(col, col * 0.45, seam);
	} else if (style == 7) { // duvar: taş örgü
		vec2 s = cell * vec2(1.5, 3.0);
		s.x += floor(s.y) * 0.5;
		col = mix(col * (0.9 + 0.3 * hash21(floor(s))), col * 0.5, mortar(s, 0.1));
	} else if (style == 8) { // boşluk / kaya: tarama
		float hatch = smoothstep(0.4, 0.5, abs(fract((cell.x + cell.y) * 2.5) - 0.5) * 2.0);
		col = mix(col, col * 1.6 + 0.03, hatch * vnoise(cell * 1.3));
	} else if (style == 9) { // bataklık: su birikintileri
		float p = vnoise(cell * 2.2);
		col = mix(col, pal(2) * 0.75, smoothstep(0.62, 0.7, p) * 0.75);
	} else if (style == 10) { // lav: parlayan çatlaklar
		float c = abs(fbm(cell * 1.4) - 0.5);
		col = mix(vec3(1.0, 0.78, 0.25), col * 0.45, smoothstep(0.015, 0.07, c));
	} else if (style == 12) { // çatı kiremidi: sıralı, kaydırmalı kiremitler
		vec2 t = cell * vec2(2.2, 3.0);
		t.x += floor(t.y) * 0.5;
		vec2 f = fract(t);
		float edge = smoothstep(0.0, 0.18, f.y) * (1.0 - smoothstep(0.82, 1.0, f.y));
		float side = smoothstep(0.0, 0.08, f.x) * (1.0 - smoothstep(0.92, 1.0, f.x));
		col *= 0.78 + 0.22 * edge * side + 0.08 * hash21(floor(t));
		col *= 0.92 + 0.12 * (1.0 - f.y);
	} else if (style == 13) { // tarla: parsel parsel ekin sıraları
		vec2 plot = floor(cell / 7.0);
		float h = hash21(plot);
		float dir = h > 0.5 ? cell.x : cell.y;
		float rows = 0.5 + 0.5 * sin(dir * 5.5);
		vec3 crop = mix(vec3(0.62, 0.72, 0.32), vec3(0.85, 0.74, 0.38), hash21(plot + 7.0));
		col = mix(col, crop, 0.55) * (0.85 + 0.2 * rows);
	} else if (style == 11) { // çayır / ova
		col *= 0.96 + 0.06 * vnoise(cell * 4.0);
	}
	return col;
}

void fragment() {
	vec2 cell = UV * map_cells;
	vec3 col;
	if (!fancy) {
		col = pal(terrain_at(cell));
	} else {
		vec2 wc = warp_cell(cell);
		int t = terrain_at(wc);
		float m = water_smooth(wc, 0.5);
		float far = (water_smooth(wc, 1.5) + water_smooth(wc, 3.0)) * 0.5;
		float fw_m = fwidth(m);
		float fw_far = fwidth(far);
		bool water = m > 0.5;
		// kıyı yumuşatması hücreyle çelişirse: suda sığ su, karada kumsal
		if (water != terrain_is_water(t)) {
			t = water ? 2 : 3;
		}
		col = pal(t);
		if (water) {
			col = mix(pal(2) * 1.1, col, smoothstep(0.55, 0.97, far));
			float rip = 0.0;
			for (int i = 0; i < 2; i++) {
				float lv = 0.62 + float(i) * 0.12;
				rip += 1.0 - smoothstep(0.0, fw_far * 1.3, abs(far - lv));
			}
			col = mix(col, col * 1.3 + 0.04, clamp(rip, 0.0, 1.0) * 0.45);
			col *= 0.94 + 0.12 * fbm(cell * 0.7);
		} else {
			col *= 0.92 + 0.14 * fbm(cell * 0.6);
			col = land_detail(col, style_of(t), cell);
		}
		// mürekkep kıyı çizgisi (ekranda sabit kalınlık)
		float ink = 1.0 - smoothstep(0.0, fw_m * 1.6, abs(m - 0.5));
		col = mix(col, INK, ink * 0.85);
	}
	if (parchment) {
		// sepya + kağıt: renkleri kağıt tonuna yaklaştır, lekeler ve kenar yanığı ekle
		vec3 paper_col = vec3(0.89, 0.81, 0.62);
		float lum = dot(col, vec3(0.3, 0.59, 0.11));
		vec3 sepia = paper_col * (0.45 + 0.75 * lum);
		col = mix(col, sepia, 0.6);
		float paper = fbm(cell * 0.35) * 0.6 + fbm(cell * 4.0) * 0.4;
		col *= 0.84 + 0.24 * paper;
		col = mix(col, col * vec3(0.8, 0.68, 0.5), smoothstep(0.62, 0.8, fbm(cell * 0.2 + 7.0)) * 0.5);
		vec2 e = min(UV, 1.0 - UV) * map_cells;
		col *= mix(0.45, 1.0, smoothstep(0.0, 14.0, min(e.x, e.y)));
	}
	COLOR = vec4(col, 1.0);
}
