shader_type canvas_item;
render_mode unshaded;

// Basic outline color (black)
uniform vec4 base_outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 flash_color : source_color;
// Fear color gradient
uniform sampler2D gradient;
// Percent from bottom that black outline is replaced with fear gradient color
uniform float fear_progress : hint_range(0.0, 1.0) = 0.0;
// Outline will flash black and white if NPC is scared
uniform bool flashing;
uniform float flash_freq : hint_range(0.1, 100) = 5.0;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 outline_color = base_outline_color;
	float size_x = 1.0/float(textureSize(TEXTURE, 0).x);
	float size_y = 1.0/float(textureSize(TEXTURE, 0).y);
	vec4 sprite_color = texture(TEXTURE, UV);
	float alpha = -4.0 * sprite_color.a;
	alpha += texture(TEXTURE, UV + vec2(size_x, 0)).a;
	alpha += texture(TEXTURE, UV + vec2(-size_x, 0)).a;
	alpha += texture(TEXTURE, UV + vec2(0, size_y)).a;
	alpha += texture(TEXTURE, UV + vec2(0, -size_y)).a;
	float height = 1.0 - UV.y;
	if (height < fear_progress) {
		outline_color = texture(gradient, vec2(height, 0));
	}
	if (flashing) {
		float flash_threshold = flash_freq / 2.0;
		bool is_white =mod( TIME ,flash_freq) > flash_threshold;
		
		if (is_white) {
			outline_color = flash_color;
		}
	}
	vec4 final_color = mix(sprite_color, outline_color, clamp(alpha, 0.0, 1.0));
	COLOR = vec4(final_color.rgb, clamp(abs(alpha) + sprite_color.a, 0.0, 1.0));
}

