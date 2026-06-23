package raytracer

import "core:math"
import "core:math/linalg"

Lambertian :: struct {
	tex:       Texture,
	roughness: f64,
}

Oren_Nayar :: struct {
	tex:       Texture,
	roughness: f64,
}

Burley :: struct {
	tex:       Texture,
	roughness: f64,
}

make_lambertian :: proc {
	make_lambertian_color,
	make_lambertian_texture,
}

make_lambertian_color :: proc(color: Color, roughness: f64 = 1) -> Material {
	return Material(Lambertian{solid_color(color), roughness})
}

make_lambertian_texture :: proc(tex: Texture, roughness: f64 = 1) -> Material {
	return Material(Lambertian{tex, roughness})
}

scatter_lambertian :: proc(
	mat: Lambertian,
	ray_in: Ray,
	rec: Hit_Record,
) -> (
	srec: Scatter_Record,
	hit: bool,
) {
	srec.attenuation = texture_value(mat.tex, rec.u, rec.v, rec.p)
	srec.pdf_ptr = cosine_pdf(rec.normal)
	srec.skip_pdf = false

	return srec, true
}

make_oren_nayar :: proc {
	make_oren_nayar_color,
	make_oren_nayar_texture,
}

make_oren_nayar_color :: proc(color: Color, roughness: f64) -> Material {
	return Material(Oren_Nayar{solid_color(color), roughness})
}

make_oren_nayar_texture :: proc(tex: Texture, roughness: f64) -> Material {
	return Material(Oren_Nayar{tex, roughness})
}

// Extra Experimentations
scatter_oren_nayar :: proc(
	mat: Oren_Nayar,
	r_in: Ray,
	rec: Hit_Record,
) -> (
	srec: Scatter_Record,
	hit: bool,
) {
	// Use Lambertian default scatter direction
	uvw := onb(rec.normal)
	scatter_dir := onb_transform(&uvw, random_cosine_direction())
	if near_zero(scatter_dir) {
		scatter_dir = rec.normal
	}

	view_dir := linalg.normalize(-r_in.dir)
	light_dir := linalg.normalize(scatter_dir)

	sigma2 := mat.roughness * mat.roughness
	A := 1.0 - (sigma2 / (2.0 * (sigma2 + 0.33)))
	B := 0.45 * sigma2 / (sigma2 + 0.09)

	// Project view and light onto the tangent plane
	n_dot_v := math.max(linalg.dot(rec.normal, view_dir), 0.0)
	n_dot_l := math.max(linalg.dot(rec.normal, light_dir), 0.0)

	// Azimuthal component: cos(phi_r - phi_i)
	// Project L and V onto the tangent plane and find the cosine between them
	view_perp := linalg.normalize(view_dir - n_dot_v * rec.normal)
	light_perp := linalg.normalize(light_dir - n_dot_l * rec.normal)
	cos_phi_diff := math.max(0.0, linalg.dot(light_perp, view_perp))

	// The larger angle is alpha, smaller is Lambertian
	alpha := math.acos(min(n_dot_l, n_dot_v))
	beta := math.acos(max(n_dot_l, n_dot_v))

	factor := A + B * cos_phi_diff * math.sin(alpha) * math.tan(beta)
	srec.attenuation = texture_value(mat.tex, rec.u, rec.v, rec.p) * factor
	scattered := new_ray(rec.p, scatter_dir, r_in.tm)
	srec.pdf_ptr = cosine_pdf(rec.normal)
	srec.skip_pdf = false

	return srec, true
}

make_burley :: proc {
	make_burley_color,
	make_burley_texture,
}

make_burley_color :: proc(color: Color, roughness: f64) -> Material {
	return Material(Burley{solid_color(color), roughness})
}

make_burley_texture :: proc(tex: Texture, roughness: f64) -> Material {
	return Material(Burley{tex, roughness})
}

scatter_burley :: proc(
	mat: Burley,
	r_in: Ray,
	rec: Hit_Record,
) -> (
	srec: Scatter_Record,
	hit: bool,
) {
	uvw := onb(rec.normal)
	scatter_dir := onb_transform(&uvw, random_cosine_direction())
	if near_zero(scatter_dir) {
		scatter_dir = rec.normal
	}

	view_dir := linalg.normalize(-r_in.dir)
	light_dir := linalg.normalize(scatter_dir)
	half_vec := linalg.normalize(view_dir + light_dir)

	n_dot_l := max(linalg.dot(rec.normal, light_dir), 0.0)
	n_dot_v := max(linalg.dot(rec.normal, view_dir), 0.0)
	l_dot_h := max(linalg.dot(light_dir, half_vec), 0.0)

	fd90 := 0.5 + 2.0 * mat.roughness * l_dot_h * l_dot_h

	schlick :: proc(cos_theta, f90: f64) -> f64 {
		t := 1.0 - cos_theta
		return 1.0 + (f90 - 1.0) * math.pow(t, 5)
	}

	fd := schlick(n_dot_l, fd90) * schlick(n_dot_v, fd90)

	srec.attenuation = texture_value(mat.tex, rec.u, rec.v, rec.p) * fd
	scattered := new_ray(rec.p, scatter_dir, r_in.tm)
	srec.pdf_ptr = cosine_pdf(rec.normal)
	srec.skip_pdf = false

	return srec, true
}

diffuse_pdf :: proc(material: Material, r_in: Ray, rec: ^Hit_Record, scattered: Ray) -> f64 {
	cos_theta := linalg.dot(rec.normal, linalg.vector_normalize(scattered.dir))
	return cos_theta < 0 ? 0 : cos_theta / math.PI
}
