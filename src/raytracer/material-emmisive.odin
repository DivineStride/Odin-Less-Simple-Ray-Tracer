package raytracer

Emissive :: struct {
	tex: Texture,
}

make_emissive :: proc {
	make_emissive_color,
	make_emissive_texture,
}

make_emissive_color :: proc(color: Color) -> Material {
	return Material(Emissive{solid_color(color)})
}

make_emissive_texture :: proc(tex: Texture) -> Material {
	return Material(Emissive{tex})
}

color_emitted :: proc(mat: ^Material, u, v: f64, p: Point3) -> (Color, bool) {
	diff, ok := mat.(Emissive)

	return texture_value(diff.tex, u, v, p), ok
}

scatter_emissive :: proc(mat: Emissive, r_in: Ray, rec: Hit_Record) -> (Color, Ray, bool) {
	return {}, {}, false
}
