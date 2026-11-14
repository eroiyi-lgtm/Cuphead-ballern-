// Figuren-Material: Treffer-Aufblitzen (hit_flash) + Zerlaufen zu Tinte (ink_dissolve) in einem
// Material, damit pro Figur nur ein Shader aktiv ist. Kinder nutzen use_parent_material.
shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.11, 0.12, 0.16, 1.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
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
	c.rgb = mix(c.rgb, flash_color.rgb, flash_amount);
	if (dissolve > 0.0) {
		// von oben nach unten zerlaufen, mit Noise-Rand
		float n = noise(local_pos * 0.06) * 0.6 + clamp((local_pos.y + 300.0) / 600.0, 0.0, 1.0) * 0.4;
		float edge = smoothstep(dissolve - 0.08, dissolve, n);
		if (n < dissolve - 0.08) {
			discard;
		}
		c.rgb = mix(ink_color.rgb, c.rgb, edge);
	}
	COLOR = c;
}
