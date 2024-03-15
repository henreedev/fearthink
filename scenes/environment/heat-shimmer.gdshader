shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float force : hint_range(0.0, 1.0) =  0.26;
uniform bool debug = false;
uniform float scale : hint_range(0.0, 1.0) = 0.01;
void fragment() {
	if (debug) {
		COLOR = texture(TEXTURE, UV);
	} else {
		float mask = texture(TEXTURE, UV).a;
		vec2 disp = normalize(UV) * force * mask * scale;
		COLOR = texture(SCREEN_TEXTURE, SCREEN_UV - disp);
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
