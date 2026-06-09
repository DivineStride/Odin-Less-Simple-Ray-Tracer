package raytracer

import "core:math"
import "core:math/linalg"

Sphere :: struct {
	center: Ray,
	radius: f64,
	mat:    ^Material,
	bbox:   AaBb,
}

build_sphere :: proc {
	build_stationary_sphere,
	build_moving_sphere,
}

build_stationary_sphere :: proc(
	static_center: Point3,
	sphere_radius: f64,
	mat: ^Material,
) -> Sphere {
	radius := math.max(0, sphere_radius)
	rvec := Vec3{radius, radius, radius}
	bbox := aabb(static_center - rvec, static_center + rvec)

	return Sphere{new_ray(static_center, Point3{0, 0, 0}), radius, mat, bbox}

}

build_moving_sphere :: proc(
	center1, center2: Point3,
	sphere_radius: f64,
	mat: ^Material,
) -> Sphere {
	center := new_ray(center1, center2 - center1)
	radius := math.max(0, sphere_radius)

	rvec := Vec3{radius, radius, radius}
	box1 := aabb(ray_at(center, 0) - rvec, ray_at(center, 0) + rvec)
	box2 := aabb(ray_at(center, 1) - rvec, ray_at(center, 1) + rvec)
	bbox := aabb_union(box1, box2)

	return Sphere{new_ray(center1, center2 - center1), radius, mat, bbox}
}

get_sphere_uv :: proc(p: Point3) -> (u, v: f64) {
	// p: a given point on sphere of radius one, centered at the origin.
	// u: returned value [0, 1] of angle around the Y axis from X=-1.
	// v: returned value [0,1] of angle from Y=-1 to Y=+1.
	//     <1  0  0> yields <0.50 0.50>     <-1  0  0> yields <0.00 0.50>
	//     <0  1  0> yields <0.50 1.00>     < 0 -1  0> yields <0.50 0.00>
	//     <0  0  1> yields <0.25 0.50>     < 0  0 -1> yields <0.75 0.50>

	theta := math.acos(-p.y)
	phi := math.atan2(-p.z, p.x) + math.PI

	u = phi / (2 * math.PI)
	v = theta / math.PI

	return u, v
}

hit_sphere :: proc(s: Sphere, r: Ray, ray_t: Interval) -> (Hit_Record, bool) {
	current_center := ray_at(s.center, r.tm)
	oc: Vec3 = current_center - r.origin
	a: f64 = linalg.dot(r.dir, r.dir)
	h := linalg.dot(r.dir, oc)
	c := linalg.dot(oc, oc) - s.radius * s.radius
	discriminant := h * h - a * c

	if (discriminant < 0) {
		return {}, false
	}

	sqrtd := math.sqrt(discriminant)

	// Find the nearest root that lies in the acceptable range
	root := (h - sqrtd) / a
	if (!surrounds(ray_t, root)) {
		root = (h + sqrtd) / a
		if (!surrounds(ray_t, root)) {
			return {}, false
		}
	}

	rec: Hit_Record
	rec.t = root
	rec.p = ray_at(r, rec.t)
	rec.mat = s.mat

	outward_normal := (rec.p - current_center) / s.radius
	rec.u, rec.v = get_sphere_uv(outward_normal)
	// set face normal
	rec.normal, rec.front_face = set_record_normal(r, outward_normal)

	return rec, true
}
