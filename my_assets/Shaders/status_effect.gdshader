shader_type canvas_item;
render_mode unshaded, blend_mix;

// Status effect overlay shader for ORBITAL: The Last Engineer (Milestone 2)
// Combines vignette, edge tinting (hypoxia, frost, heatstroke, CO2 toxicity), and pulsing distortion.

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float radius : hint_range(0.0, 1.5) = 0.45;
uniform float softness : hint_range(0.01, 1.0) = 0.55;
uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 10.0) = 0.0;
uniform float distortion : hint_range(0.0, 0.1) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = UV;
	
	// Heat / Dizziness wave refraction
	float wave = 0.0;
	if (distortion > 0.0) {
		wave = sin(uv.y * 24.0 + TIME * 4.0) * distortion;
	}
	
	vec2 p = (uv + vec2(wave * 0.5, 0.0)) - vec2(0.5);
	float d = length(p) * 1.41421356; // 1.0 at corner
	
	float pulse = 1.0;
	if (pulse_speed > 0.0) {
		pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	}
	
	float mask = smoothstep(radius, radius + softness, d);
	float alpha = mask * strength * pulse * tint_color.a;
	
	vec4 base_col = tint_color;
	if (distortion > 0.0 && strength > 0.0) {
		vec4 screen_sample = textureLod(screen_texture, SCREEN_UV + vec2(wave, 0.0), 0.0);
		base_col = mix(screen_sample, tint_color, clamp(alpha * 0.75, 0.0, 1.0));
		alpha = max(alpha, strength * 0.3);
	}
	
	COLOR = vec4(base_col.rgb, clamp(alpha, 0.0, 1.0));
}
