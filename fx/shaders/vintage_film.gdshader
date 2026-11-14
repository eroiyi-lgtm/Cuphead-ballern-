// Vollbild-PostFX, ein Pass, ein Screen-Read: Sepia-Gradierung, Filmkorn (24 fps), vertikale Kratzer,
// Staubflecken, Vignette, Helligkeits-Flackern ±3 %, Bild-Wackeln 0,5–1 px.
// Stärken kommen aus den Optionen (SaveData.film_strength / screen_wobble) über fx/post_fx.gd.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float sepia_amount : hint_range(0.0, 1.0) = 0.35;
uniform float grain_amount : hint_range(0.0, 0.3) = 0.07;
uniform float scratch_amount : hint_range(0.0, 1.0) = 0.5;
uniform float dust_amount : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_amount : hint_range(0.0, 1.5) = 0.55;
uniform float flicker_amount : hint_range(0.0, 0.1) = 0.03;
uniform float wobble_px : hint_range(0.0, 2.0) = 0.8;
uniform float fps = 24.0;
uniform vec3 tone_dark : source_color = vec3(0.110, 0.122, 0.165);
uniform vec3 tone_light : source_color = vec3(0.914, 0.863, 0.753);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float frame = floor(TIME * fps);
	vec2 jitter = (vec2(hash(vec2(frame, 1.0)), hash(vec2(frame, 2.0))) - 0.5) * 2.0 * wobble_px * SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV + jitter;
	vec3 c = textureLod(screen_tex, uv, 0.0).rgb;

	// Sepia-Gradierung: Luminanz auf Tinte→Pergament abbilden, Farbe teilweise erhalten
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, mix(tone_dark, tone_light, lum), sepia_amount);

	// Filmkorn
	vec2 grain_uv = floor(SCREEN_UV / SCREEN_PIXEL_SIZE / 2.0);
	c += (hash(grain_uv + frame * 13.7) - 0.5) * grain_amount;

	// Vertikale Kratzer
	for (int i = 0; i < 2; i++) {
		float fi = float(i);
		float on = step(1.0 - scratch_amount * 0.5, hash(vec2(frame, 20.0 + fi)));
		float x = hash(vec2(frame, 10.0 + fi));
		float w = SCREEN_PIXEL_SIZE.x * 1.5;
		float line = on * (1.0 - smoothstep(0.0, w, abs(SCREEN_UV.x - x)));
		line *= step(0.3, hash(vec2(floor(SCREEN_UV.y * 30.0), frame + fi)));
		c = mix(c, tone_light, line * 0.45);
	}

	// Staubflecken
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float on = step(1.0 - dust_amount * 0.4, hash(vec2(frame, 40.0 + fi)));
		vec2 center = vec2(hash(vec2(frame, 50.0 + fi)), hash(vec2(frame, 60.0 + fi)));
		float r = 0.0015 + 0.004 * hash(vec2(frame, 70.0 + fi));
		float d = length((SCREEN_UV - center) * vec2(1.0 / aspect, 1.0));
		c = mix(c, tone_dark, on * (1.0 - smoothstep(r * 0.5, r, d)) * 0.8);
	}

	// Vignette
	float v = length((SCREEN_UV - 0.5) * vec2(1.0, 0.8)) * 1.4;
	c *= 1.0 - vignette_amount * smoothstep(0.45, 1.05, v);

	// Helligkeits-Flackern
	c *= 1.0 + (hash(vec2(frame, 5.0)) - 0.5) * 2.0 * flicker_amount;

	COLOR = vec4(c, 1.0);
}
