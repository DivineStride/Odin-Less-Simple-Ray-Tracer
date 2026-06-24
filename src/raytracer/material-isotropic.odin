package raytracer

import "core:math"
Isotropic :: struct {
	tex: Texture,
}

make_isotropic :: proc {
	make_isotropic_texture,
	make_isotropic_color,
}

make_isotropic_texture :: proc(tex: Texture) -> Material {
	return Material(Isotropic{tex})
}

make_isotropic_color :: proc(albedo: Color) -> Material {
	return Material(Isotropic{solid_color(albedo)})
}

scatter_isotropic :: proc(
	iso: Isotropic,
	r: Ray,
	rec: Hit_Record,
) -> (
	srec: Scatter_Record,
	hit: bool,
) {
	srec.attenuation = texture_value(iso.tex, rec.u, rec.v, rec.p)
	srec.pdf_ptr = sphere_pdf()
	srec.skip_pdf = false
	return srec, true
}

isotropic_pdf :: proc(m: Material, r_in: Ray, rec: ^Hit_Record, scattered: Ray) -> f64 {
	return 1 / (4 * math.PI)
}
