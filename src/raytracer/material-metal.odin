package raytracer

import "core:math/linalg"

Metal :: struct {
	tex:  Texture,
	fuzz: f64,
}

make_metal :: proc {
	make_metal_color,
	make_metal_texture,
}

make_metal_color :: proc(color: Color, fuzz: f64) -> Material {
	return Material(Metal{solid_color(color), fuzz})
}

make_metal_texture :: proc(tex: Texture, fuzz: f64) -> Material {
	return Material(Metal{tex, fuzz})
}

scatter_metal :: proc(mat: Metal, r_in: Ray, rec: Hit_Record) -> (Color, Ray, bool) {
	unit_dir := linalg.normalize(r_in.dir)
	reflected := linalg.reflect(unit_dir, rec.normal)
	reflected = linalg.normalize(reflected) + (mat.fuzz * random_unit_vector())
	scattered := new_ray(rec.p, reflected, r_in.tm)

	above_surface := linalg.dot(scattered.dir, rec.normal) > 0
	attenuation := texture_value(mat.tex, rec.u, rec.v, rec.p)

	return attenuation, scattered, above_surface
}
