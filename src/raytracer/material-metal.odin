package raytracer

import "core:fmt"
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

scatter_metal :: proc(
	mat: Metal,
	r_in: Ray,
	rec: Hit_Record,
) -> (
	srec: Scatter_Record,
	hit: bool,
) {
	reflected := linalg.reflect(r_in.dir, rec.normal)
	reflected = linalg.normalize(reflected) + (mat.fuzz * random_unit_vector())

	srec.attenuation = texture_value(mat.tex, rec.u, rec.v, rec.p)
	srec.skip_pdf = true
	srec.skip_pdf_ray = new_ray(rec.p, reflected, r_in.tm)

	// Removes precision banding
	above_surface := linalg.dot(srec.skip_pdf_ray.dir, rec.normal) > 0

	return srec, above_surface
}
