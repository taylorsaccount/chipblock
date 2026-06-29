shader_type canvas_item;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Tritanopia correction: shift blue toward red, reduce blue channel
	float r = clamp(c.r + c.b * 0.4, 0.0, 1.0);
	float g = c.g;
	float b = clamp(c.b * 0.6, 0.0, 1.0);
	COLOR = vec4(r, g, b, c.a);
}
