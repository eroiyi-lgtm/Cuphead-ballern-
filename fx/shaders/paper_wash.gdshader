// Hintergrund-Ebenen: Aquarell-Flecken und Papierstruktur, leicht entsättigt.
// Weltfeste Koordinaten, damit die Flecken mit der Ebene mitwandern.
shader_type canvas_item;

uniform float strength : hint_range(0.0, 0.5) = 0.16;
uniform float desaturate : hint_range(0.0, 1.0) = 0.18;
uniform float scale = 0.0035;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec4 c = COLOR;
	float wash = noise(world_pos * scale) * 0.55 + noise(world_pos * scale * 3.1 + 17.0) * 0.3 + noise(world_pos * 0.08) * 0.15;
	c.rgb *= 1.0 - strength * 0.6 + strength * wash;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(lum), desaturate);
	COLOR = c;
}
