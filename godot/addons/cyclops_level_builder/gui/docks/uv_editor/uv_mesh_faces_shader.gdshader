shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform vec4 face_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX = vec3(UV.x, UV.y, 0);
	NORMAL = vec3(0, 1, 0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = (face_color * COLOR).rgb;
	ALPHA = (face_color * COLOR).a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
