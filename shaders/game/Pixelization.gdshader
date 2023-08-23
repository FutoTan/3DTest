shader_type spatial;
render_mode cull_front;

varying vec2 PIXEL_SIZE;

uniform float depth_threshold: hint_range(0, 1, 0.01) = 0.1;
uniform float normal_threshold: hint_range(0, 1, 0.01) = 0.5;
uniform float steep_angle_threshold: hint_range(0, 1, 0.01) = 0.1;
uniform float steep_angle_scale: hint_range(0, 5, 1) = 1;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;


float getDepth(vec2 uv, mat4 inv_matrix) {
	float depth = texture(depth_texture, uv).x;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = inv_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	
	PIXEL_SIZE = 1.0 / VIEWPORT_SIZE;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 uv_topright = uv + PIXEL_SIZE;
	vec2 uv_bottomleft = uv;
	vec2 uv_topleft = uv + vec2(0, PIXEL_SIZE.y);
	vec2 uv_bottomright = uv + vec2(PIXEL_SIZE.x, 0);
	
	float depth = getDepth(uv, INV_PROJECTION_MATRIX);
	float depth_topright = getDepth(uv_topright, INV_PROJECTION_MATRIX);
	float depth_topleft = getDepth(uv_topleft, INV_PROJECTION_MATRIX);
	float depth_bottomright = getDepth(uv_bottomright, INV_PROJECTION_MATRIX);
	float depth_bottomleft = getDepth(uv_bottomleft, INV_PROJECTION_MATRIX);
	
	float depth_diff1 = abs(depth_topright - depth_bottomleft);
	float depth_diff2 = abs(depth_topleft - depth_bottomright);
	float robert_result1 = sqrt(depth_diff1 * depth_diff1 + depth_diff2 * depth_diff2);
	
	vec4 normal = texture(normal_roughness_texture, uv);
	vec4 normal_topright = texture(normal_roughness_texture, uv_topright);
	vec4 normal_topleft = texture(normal_roughness_texture, uv_topleft);
	vec4 normal_bottomright = texture(normal_roughness_texture, uv_bottomright);
	vec4 normal_bottomleft = texture(normal_roughness_texture, uv_bottomleft);

	vec3 normal_diff1 = abs(normal_topright.rgb - normal_bottomleft.rgb);
	vec3 normal_diff2 = abs(normal_topleft.rgb - normal_bottomright.rgb);
	float robert_result2 = sqrt(dot(normal_diff1, normal_diff1) + dot(normal_diff2, normal_diff2));
	
	vec3 re_normal = 2.0 * normal.xyz - 1.0;
	vec3 re_position = -2.0 * CAMERA_POSITION_WORLD + 1.0;
	
	float robert_step1 = step(depth * depth_threshold * (smoothstep(steep_angle_threshold, 2, dot(re_normal, re_position)) * steep_angle_scale + 1.0), robert_result1);
	float robert_step2 = step(normal_threshold, robert_result2);
	
	float alpha = max(robert_step1, robert_step2);
	float coefficient = robert_step1 > 0.0 ? 1.0 - 0.4 * robert_step1 : 1.0 + 0.05 * robert_step2;
	
	ALBEDO = texture(screen_texture, uv).rgb * coefficient;
	ALPHA = alpha;
}
