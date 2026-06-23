package raytracer

import "core:math"
import "core:math/linalg"

Quad :: struct {
	bbox:    AaBb,
	normal:  Vec3,
	Q:       Point3,
	u, v, w: Vec3,
	D:       f64,
	area:    f64,
	mat:     ^Material,
}

build_quad :: proc(Q: Point3, u, v: Vec3, mat: ^Material) -> Quad {
	bbox: AaBb
	n := linalg.cross(u, v)
	normal: Vec3 = linalg.normalize(n)
	D := linalg.dot(normal, Q)
	w := n / linalg.dot(n, n)

	area := linalg.length(n)

	quad := Quad{bbox, normal, Q, u, v, w, D, area, mat}

	set_quad_bounding_box(&quad)

	return quad
}

hit_quad :: proc(quad: Quad, r: Ray, ray_t: Interval) -> (Hit_Record, bool) {
	// Step 1: Find plane that contains that quad
	denom := linalg.dot(quad.normal, r.dir)

	if (math.abs(denom) < 1e-8) {
		return {}, false
	}

	t := (quad.D - linalg.dot(quad.normal, r.origin)) / denom
	if !contains(ray_t, t) {
		return {}, false
	}

	// Step 2: Solve for the intersection of a ray and the quad-containing plane.
	// Ax + By + Cz + D = 0
	// t = ( D - n * P ) / n * d
	rec: Hit_Record
	intersection := ray_at(r, t)
	planar_hitpt_vector := intersection - quad.Q
	alpha := linalg.dot(quad.w, linalg.cross(planar_hitpt_vector, quad.v))
	beta := linalg.dot(quad.w, linalg.cross(quad.u, planar_hitpt_vector))


	if ok := is_quad_interior(alpha, beta, &rec); !ok {
		return {}, false
	}

	// Step 3: Determine if the hit point lies inside the quad.
	rec.t = t
	rec.p = intersection
	rec.mat = quad.mat
	rec.normal, rec.front_face = set_record_normal(r, quad.normal)

	return rec, true
}

set_quad_bounding_box :: proc(quad: ^Quad) {
	bbox_diagonal1 := aabb(quad.Q, quad.Q + quad.u + quad.v)
	bbox_diagonal2 := aabb(quad.Q + quad.u, quad.Q + quad.v)
	quad.bbox = aabb(bbox_diagonal1, bbox_diagonal2)
}

@(private)
is_quad_interior :: proc(alpha, beta: f64, rec: ^Hit_Record) -> bool {
	unit_interval := Interval{0, 1}

	if (!contains(unit_interval, alpha)) || !contains(unit_interval, beta) do return false

	rec.u = alpha
	rec.v = beta

	return true
}
