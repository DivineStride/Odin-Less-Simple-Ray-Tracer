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

color_emitted :: proc(mat: ^Material, rec: ^Hit_Record, u, v: f64, p: Point3) -> (Color, bool) {
	diff, ok := mat.(Emissive)
	if !ok do return {}, false

	if !rec.front_face do return Color{0, 0, 0}, false

	return texture_value(diff.tex, u, v, p), ok
}

scatter_emissive :: proc(mat: Emissive, r_in: Ray, rec: Hit_Record) -> (Scatter_Record, bool) {
	return {}, false
}
