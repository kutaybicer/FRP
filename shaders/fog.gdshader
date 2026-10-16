shader_type canvas_item;
// Savaş sisi: doku R kanalı 0 = kapalı, 1/255 ve üstü = açık
uniform vec4 fog_color : source_color = vec4(0.07, 0.06, 0.05, 1.0);

void fragment() {
	float open = clamp(texture(TEXTURE, UV).r * 255.0, 0.0, 1.0);
	COLOR = vec4(fog_color.rgb, (1.0 - open) * COLOR.a);
}
