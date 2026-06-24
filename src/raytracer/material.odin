package raytracer

Material :: union {
	Lambertian,
	Oren_Nayar,
	Burley,
	Metal,
	Dielectric,
	Emissive,
	Isotropic,
}

Scatter_Record :: struct {
	attenuation:  Color,
	pdf_ptr:      Pdf,
	skip_pdf:     bool,
	skip_pdf_ray: Ray,
}

scatter :: proc(mat: ^Material, r_in: Ray, rec: Hit_Record) -> (srec: Scatter_Record, ok: bool) {
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
	case Emissive:
		return scatter_emissive(m, r_in, rec)
	case Isotropic:
		return scatter_isotropic(m, r_in, rec)
	}

	return {}, false
}

scatter_pdf :: proc(material: ^Material, r_in: Ray, rec: ^Hit_Record, scattered: Ray) -> f64 {
	switch m in material {
	case Lambertian:
		return diffuse_scattering_pdf(m, r_in, rec, scattered)
	case Oren_Nayar:
		return oren_nayar_scattering_pdf(m, r_in, rec, scattered)
	case Burley:
		return burley_scattering_pdf(m, r_in, rec, scattered)
	case Isotropic:
		return isotropic_pdf(m, r_in, rec, scattered)
	case Dielectric, Metal, Emissive:
		return 0
	}

	return 0
}
