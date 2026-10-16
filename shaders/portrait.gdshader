shader_type canvas_item;
// Portre "boya" efekti: fırça dokusu, sol üstten ışık, sıcak/soğuk ton ayrımı ve kenar karartma.
// Portreler SubViewport içinde çizildiği için SCREEN_UV tüm portreyi 0..1 aralığında kapsar.

uniform float paint = 1.0;

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
		p = p * 2.07 + vec2(3.1, 7.7);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec4 c = COLOR;
	vec2 d = SCREEN_UV * 2.0 - 1.0;
	// fırça dokusu: yönlü (çapraz) gürültü
	vec2 q = vec2(d.x + d.y * 0.6, d.y - d.x * 0.6);
	float n = fbm(q * vec2(6.0, 22.0));
	float grain = vnoise(SCREEN_UV * 180.0);
	c.rgb *= mix(1.0, 0.9 + 0.17 * n + 0.04 * grain, paint);
	// ışık
	float light = clamp(0.55 - dot(d, normalize(vec2(0.55, 0.8))) * 0.55, 0.0, 1.0);
	c.rgb *= mix(1.0, 0.8 + 0.36 * light, paint);
	c.rgb = mix(c.rgb, c.rgb * vec3(1.06, 1.0, 0.9), light * 0.45 * paint);
	c.rgb = mix(c.rgb, c.rgb * vec3(0.88, 0.94, 1.1), (1.0 - light) * 0.4 * paint);
	// kenar karartma
	float r = length(d);
	c.rgb *= mix(1.0, 1.0 - smoothstep(0.55, 1.0, r) * 0.3, paint);
	COLOR = c;
}
