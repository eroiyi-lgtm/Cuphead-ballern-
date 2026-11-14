// Figuren-Material: Boiling Lines (Linien zittern mit 12 fps wie neu gezeichnet), Treffer-Blitz
// und Zerlaufen zu Tinte in einem Material. Kinder nutzen use_parent_material.
shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.11, 0.12, 0.16, 1.0);
uniform float boil_px = 2.0;        // Verschiebung in Textur-Pixeln
uniform float boil_fps = 12.0;      // "on twos"
uniform float boil_scale = 0.06;

varying vec2 local_pos;
varying vec4 v_color;

void vertex() {
	local_pos = VERTEX;
	v_color = COLOR;
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
	float frame = floor(TIME * boil_fps);
	vec2 n = vec2(noise(local_pos * boil_scale + frame * 7.13), noise(local_pos * boil_scale + 31.7 + frame * 3.71)) - 0.5;
	vec4 c = texture(TEXTURE, UV + n * 2.0 * boil_px * TEXTURE_PIXEL_SIZE) * v_color;
	c.rgb = mix(c.rgb, flash_color.rgb, flash_amount);
	if (dissolve > 0.0) {
		float d = noise(local_pos * 0.06) * 0.6 + clamp((local_pos.y + 300.0) / 600.0, 0.0, 1.0) * 0.4;
		if (d < dissolve - 0.08) {
			discard;
		}
		c.rgb = mix(ink_color.rgb, c.rgb, smoothstep(dissolve - 0.08, dissolve, d));
	}
	COLOR = c;
}
