shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.88, 0.93, 1.0, 0.15);
uniform vec4 edge_highlight : source_color = vec4(1.0, 1.0, 1.0, 0.4);
uniform float edge_width : hint_range(0.0, 10.0) = 2.0;
uniform float corner_radius_tl : hint_range(0.0, 1.0) = 0.3;
uniform float corner_radius_tr : hint_range(0.0, 1.0) = 0.3;
uniform float corner_radius_bl : hint_range(0.0, 1.0) = 0.3;
uniform float corner_radius_br : hint_range(0.0, 1.0) = 0.3;
uniform float edge_smoothness : hint_range(0.5, 3.0) = 1.0;
uniform float grain_strength : hint_range(0.0, 0.15) = 0.04;

float rounded_box(vec2 p, vec2 b, vec4 r) {
	// r.x = TL, r.y = TR, r.z = BL, r.w = BR
	r.xy = (p.x > 0.0) ? r.yw : r.xz;
	r.x  = (p.y > 0.0) ? r.y  : r.x;
	vec2 q = abs(p) - b + r.x;
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float dx = dFdx(UV.x);
	float dy = dFdy(UV.y);
	dx = sign(dx) * max(abs(dx), 0.0001);
	dy = sign(dy) * max(abs(dy), 0.0001);

	vec2 size = clamp(abs(vec2(1.0 / dx, 1.0 / dy)), vec2(1.0), vec2(4096.0));
	vec2 half_size = size * 0.5;
	vec2 centered = UV * size - half_size;

	float max_r = min(half_size.x, half_size.y);
	vec4 r = vec4(corner_radius_tl, corner_radius_tr, corner_radius_bl, corner_radius_br) * max_r;
	float sdf = rounded_box(centered, half_size, r);
	float alpha = 1.0 - smoothstep(-edge_smoothness, edge_smoothness, sdf);

	if (alpha < 0.001) {
		discard;
	}

	// Animated grain — movement sells the light diffusion
	float grain = hash(UV * 800.0 + vec2(TIME * 0.5, TIME * 0.3)) * grain_strength;

	vec3 color = tint.rgb + grain;

	// Outer rim highlight
	float edge = 1.0 - smoothstep(0.0, edge_width, -sdf);
	edge *= step(sdf, 0.0);
	color = mix(color, edge_highlight.rgb, edge * edge_highlight.a);

	// Inner shadow band just inside the rim
	float inner_edge = 1.0 - smoothstep(edge_width, edge_width * 3.0, -sdf);
	inner_edge *= step(sdf, 0.0);
	color -= vec3(inner_edge * 0.04);

	// Top sheen
	color += vec3(smoothstep(0.4, 0.0, UV.y) * 0.06);

	// Bottom darkening
	color -= vec3(smoothstep(0.6, 1.0, UV.y) * 0.05);

	COLOR = vec4(color, tint.a * alpha);
}
