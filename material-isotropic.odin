package raytracer

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

scatter_isotropic :: proc(iso: Isotropic, r: Ray, rec: Hit_Record) -> (Color, Ray, bool) {
	scattered := new_ray(rec.p, random_unit_vector(), r.tm)
	attenuation := texture_value(iso.tex, rec.u, rec.v, rec.p)
	return attenuation, scattered, true
}
