package raytracer

import "core:math"
import "core:math/linalg"

Dielectric :: struct {
	refraction_index: f64,
}

scatter_dielectric :: proc(
	mat: Dielectric,
	r_in: Ray,
	rec: Hit_Record,
) -> (
	srec: Scatter_Record,
	hit: bool,
) {
	srec.attenuation = Color{1, 1, 1}
	srec.skip_pdf = true
	ri := rec.front_face ? (1.0 / mat.refraction_index) : mat.refraction_index

	unit_dir := linalg.normalize(r_in.dir)
	cos_theta := min(linalg.dot(-unit_dir, rec.normal), 1.)
	sin_theta := math.sqrt_f64(1.0 - cos_theta * cos_theta)

	cannot_refract := ri * sin_theta > 1.0
	direction: Vec3

	if (cannot_refract || reflectance(cos_theta, ri) > random_f64()) {
		direction = reflect(unit_dir, rec.normal)
	} else {
		direction = refract(unit_dir, rec.normal, ri)
	}

	srec.skip_pdf_ray = new_ray(rec.p, direction, r_in.tm)

	return srec, true
}

reflect :: proc(v: Vec3, normal: Vec3) -> Vec3 {
	return v - 2 * linalg.dot(v, normal) * normal
}

refract :: proc(uv: Vec3, n: Vec3, etai_over_etat: f64) -> Vec3 {
	cos_theta := linalg.min(linalg.dot(-uv, n), 1.0)

	r_out_perp := etai_over_etat * (uv + cos_theta * n)
	r_out_parallel := -math.sqrt(abs(1.0 - linalg.length2(r_out_perp))) * n

	return r_out_perp + r_out_parallel
}

reflectance :: proc(cos, refraction_index: f64) -> f64 {
	// Schlick's approximation for reflectance.
	r0 := (1 - refraction_index) / (1 + refraction_index)
	r0 = r0 * r0
	return r0 + (1 - r0) * math.pow(1 - cos, 5)
}
