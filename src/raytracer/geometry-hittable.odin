package raytracer

import "core:math/linalg"

Hittable :: union {
	Sphere,
	Quad,
	Bvh_Node,
	Instance,
	Constant_Medium,
}

Hit_Record :: struct {
	p:          Point3,
	normal:     Vec3,
	mat:        ^Material,
	t:          f64,
	u, v:       f64,
	front_face: bool,
}

hittable_new :: proc(h: Hittable) -> ^Hittable {
	p := new(Hittable)
	p^ = h
	return p
}

hit_single :: proc(h: Hittable, r: Ray, ray_t: Interval) -> (Hit_Record, bool) {
	switch v in h {
	case Sphere:
		return hit_sphere(v, r, ray_t)
	case Bvh_Node:
		return hit_bvh(v, r, ray_t)
	case Quad:
		return hit_quad(v, r, ray_t)
	case Instance:
		return hit_instance(v, r, ray_t)
	case Constant_Medium:
		return hit_constant_medium(v, r, ray_t)
	}
	return {}, false
}

hit_world :: proc(world: []Hittable, r: Ray, ray_t: Interval) -> (Hit_Record, bool) {
	closest := ray_t.max
	rec: Hit_Record
	hit_anything := false

	for object in world {
		if hr, ok := hit_single(object, r, Interval{ray_t.min, closest}); ok {
			closest = hr.t
			rec = hr
			hit_anything = true
		}
	}

	return rec, hit_anything
}

set_record_normal :: proc(r: Ray, outward_normal: Vec3) -> (Vec3, bool) {
	front_face := linalg.dot(r.dir, outward_normal) < 0
	normal := front_face ? outward_normal : -outward_normal

	return normal, front_face
}

get_bbox :: proc(h: ^Hittable) -> AaBb {
	switch v in h {
	case Sphere:
		return v.bbox
	case Bvh_Node:
		return v.bbox
	case Quad:
		return v.bbox
	case Instance:
		return v.bbox
	case Constant_Medium:
		return v.bbox
	}
	return {}
}
