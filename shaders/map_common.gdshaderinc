// Arazi ve bölge shader'larının ortak kodu. İkisi de AYNI çarpıtmayı kullanmalı ki sınırlar örtüşsün.

uniform vec2 map_cells = vec2(120.0, 80.0);
uniform float warp_strength = 1.0;
uniform sampler2D terrain_idx : filter_nearest, repeat_disable;   // R = arazi indeksi / 255
uniform sampler2D water_mask : filter_linear, repeat_disable;     // R = 1 su, 0 kara
uniform sampler2D palette : filter_nearest, repeat_disable;       // 256x2: renk / (su, stil)

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

// Hücre koordinatını gürültüyle büker: kare sınırlar organik kıvrımlara dönüşür.
vec2 warp_cell(vec2 cell) {
	vec2 q = vec2(fbm(cell * 0.45), fbm(cell * 0.45 + vec2(31.7, 11.3)));
	vec2 r = vec2(vnoise(cell * 1.3 + 5.0), vnoise(cell * 1.3 + 19.0));
	return cell + ((q - 0.5) * 1.6 + (r - 0.5) * 0.25) * warp_strength;
}

int terrain_at(vec2 cell) {
	vec2 c = clamp(floor(cell), vec2(0.0), map_cells - 1.0);
	return int(texture(terrain_idx, (c + 0.5) / map_cells).r * 255.0 + 0.5);
}

bool terrain_is_water(int t) {
	return texelFetch(palette, ivec2(t, 1), 0).r > 0.5;
}

float water_at(vec2 cell) {
	return texture(water_mask, cell / map_cells).r;
}

// Bulanıklaştırılmış su maskesi: 0.5 eşiği yumuşak kıyı çizgisini verir.
float water_smooth(vec2 cell, float r) {
	float s = water_at(cell) * 2.0;
	s += water_at(cell + vec2(r, 0.0));
	s += water_at(cell - vec2(r, 0.0));
	s += water_at(cell + vec2(0.0, r));
	s += water_at(cell - vec2(0.0, r));
	return s / 6.0;
}
