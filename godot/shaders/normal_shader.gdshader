// NOTE: Shader automatically converted from Godot Engine 4.2.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode unshaded;
//render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;


void fragment() {
	ALBEDO = (NORMAL.rgb + 1.0) / 2.0;
}
