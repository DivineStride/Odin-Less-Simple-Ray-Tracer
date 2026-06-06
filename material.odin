package raytracer

Material :: union {
	Lambertian,
	Oren_Nayar,
	Burley,
	Metal,
	Dielectric,
	Diffuse,
	Isotropic,
}

scatter :: proc(
	mat: ^Material,
	r_in: Ray,
	rec: Hit_Record,
) -> (
	attenuation: Color,
	scattered: Ray,
	ok: bool,
) {
	switch m in mat {
	case Lambertian:
		return scatter_lambertian(m, r_in, rec)
	case Oren_Nayar:
		return scatter_oren_nayar(m, r_in, rec)
	case Burley:
		return scatter_burley(m, r_in, rec)
	case Metal:
		return scatter_metal(m, r_in, rec)
	case Dielectric:
		return scatter_dielectric(m, r_in, rec)
	case Diffuse:
		return scatter_diffuse(m, r_in, rec)
	case Isotropic:
		return scatter_isotropic(m, r_in, rec)
	}

	return {}, {}, false
}
