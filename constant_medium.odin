package raytracer

import "core:math"
import "core:math/linalg"

Constant_Medium :: struct {
	bbox:            AaBb,
	boundary:        ^Hittable,
	phase_function:  ^Material,
	neg_inv_density: f64,
}

build_constant_medium :: proc {
	build_constant_medium_tex,
	build_constant_medium_color,
}

build_constant_medium_tex :: proc(
	boundary: ^Hittable,
	density: f64,
	tex: Texture,
	materials: ^[dynamic]^Material,
) -> Constant_Medium {
	phase := new(Material)
	phase^ = make_isotropic(tex)
	append(materials, phase)

	return Constant_Medium{get_bbox(boundary), boundary, phase, (-1 / density)}
}

build_constant_medium_color :: proc(
	boundary: ^Hittable,
	density: f64,
	albedo: Color,
	materials: ^[dynamic]^Material,
) -> Constant_Medium {
	phase := new(Material)
	phase^ = make_isotropic(albedo)
	append(materials, phase)

	return Constant_Medium{get_bbox(boundary), boundary, phase, (-1 / density)}
}

hit_constant_medium :: proc(
	bound: Constant_Medium,
	r: Ray,
	ray_t: Interval,
) -> (
	Hit_Record,
	bool,
) {
	rec1, hit1 := hit_single(bound.boundary^, r, INTERVAL_UNIVERSE)
	if !hit1 do return {}, false

	rec2, hit2 := hit_single(bound.boundary^, r, Interval{rec1.t + 0.0001, math.INF_F64})
	if !hit2 do return {}, false

	if rec1.t < ray_t.min do rec1.t = ray_t.min
	if rec2.t > ray_t.max do rec2.t = ray_t.max

	if rec1.t >= rec2.t do return {}, false

	if rec1.t < 0 do rec1.t = 0

	ray_length := linalg.length(r.dir)
	distance_inside_boundary := (rec2.t - rec1.t) * ray_length
	hit_distance := bound.neg_inv_density * math.ln(random_f64())

	if hit_distance > distance_inside_boundary do return {}, false

	rec: Hit_Record
	rec.t = rec1.t + hit_distance / ray_length
	rec.p = ray_at(r, rec.t)

	rec.normal = Vec3{1, 0, 0} // Arbitrary
	rec.front_face = true // Also bit_array
	rec.mat = bound.phase_function

	return rec, true
}
