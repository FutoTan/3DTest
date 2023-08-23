shader_type sky;

uniform vec3 sky_color: source_color;
uniform vec3 horizon_color: source_color;

void sky() {
	float color = clamp(EYEDIR.y / 0.05, 0.0, 1.0);
	COLOR = mix(horizon_color, sky_color, color);
}
