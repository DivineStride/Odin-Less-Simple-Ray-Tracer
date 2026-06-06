package raytracer

Diffuse :: struct {
	tex: Texture,
}

make_diffuse :: proc {
	make_diffuse_color,
	make_diffuse_texture,
}

make_diffuse_color :: proc(color: Color) -> Material {
	return Material(Diffuse{solid_color(color)})
}

make_diffuse_texture :: proc(tex: Texture) -> Material {
	return Material(Diffuse{tex})
}

color_emitted :: proc(mat: ^Material, u, v: f64, p: Point3) -> (Color, bool) {
	diff, ok := mat.(Diffuse)

	return texture_value(diff.tex, u, v, p), ok
}

scatter_diffuse :: proc(mat: Diffuse, r_in: Ray, rec: Hit_Record) -> (Color, Ray, bool) {
	return {}, {}, false
}
