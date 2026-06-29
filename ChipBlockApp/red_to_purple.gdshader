shader_type canvas_item;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Remap red pixels (#D94A4A) to purple (#B641D9)
	// Uses original red channel as brightness so shading/edges are preserved
	float redness = c.r - c.b;
	if (redness > 0.2) {
		COLOR = vec4(c.r * 0.839, c.r * 0.300, c.r, c.a);
	} else {
		COLOR = c;
	}
}
