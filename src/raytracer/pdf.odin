package raytracer

import "core:math"
import "core:math/linalg"

Cosine_Pdf :: struct {
	uvw: Onb,
}

Sphere_Pdf :: struct {}

Mixture_Pdf :: struct {
	p: [2]^Pdf,
}

Hittable_Pdf :: struct {
	objects: []^Hittable,
	origin:  Point3,
}

Pdf :: union {
	Sphere_Pdf,
	Cosine_Pdf,
	Hittable_Pdf,
	Mixture_Pdf,
}

pdf_value :: proc(p: ^Pdf, direction: Vec3) -> f64 {
	switch v in p {
	case Cosine_Pdf:
		uvw := v.uvw
		cos_theta := linalg.dot(linalg.normalize(direction), onb_w(&uvw))
		return math.max(0, cos_theta / math.PI)
	case Sphere_Pdf:
		return 1.0 / (4.0 * math.PI)
	case Hittable_Pdf:
		return hittable_pdf_value(v.objects, v.origin, direction)
	case Mixture_Pdf:
		return 0.5 * pdf_value(v.p[0], direction) + 0.5 * pdf_value(v.p[1], direction)
	}

	return 0
}

hittable_pdf_value :: proc(objects: []^Hittable, origin, direction: Vec3) -> f64 {
	if len(objects) == 0 do return 0

	weight := 1.0 / f64(len(objects))
	sum := 0.0

	for object in objects {
		#partial switch v in object {
		case Quad:
			sum += quad_pdf_value(v, origin, direction)
		case Sphere:
			sum += sphere_pdf_value(v, origin, direction)
		}

	}

	return sum
}

quad_pdf_value :: proc(object: Quad, origin, direction: Vec3) -> f64 {
	if rec, hit := hit_quad(object, new_ray(origin, direction), Interval{0.001, math.INF_F64});
	   !hit {
		return 0
	} else {
		distance_squared := rec.t * rec.t * linalg.length2(direction)
		cos := math.abs(linalg.dot(direction, rec.normal) / linalg.length(direction))

		return distance_squared / (cos * object.area)
	}
}

sphere_pdf_value :: proc(object: Sphere, origin, direction: Vec3) -> f64 {
	return 0
}

pdf_generate :: proc(p: ^Pdf) -> Vec3 {
	switch v in p {
	case Cosine_Pdf:
		uvw := v.uvw
		return onb_transform(&uvw, random_cosine_direction())
	case Sphere_Pdf:
		return random_unit_vector()
	case Hittable_Pdf:
		return hittable_random(v.objects, v.origin)
	case Mixture_Pdf:
		if random_f64() < 0.5 {
			return pdf_generate(v.p[0])
		} else {
			return pdf_generate(v.p[1])
		}
	}

	return {}
}

hittable_random :: proc(objects: []^Hittable, origin: Point3) -> Vec3 {
	n := len(objects)
	if n == 0 do return Vec3{1, 0, 0}

	object := objects[random_int(0, n)]
	#partial switch v in object {
	case Quad:
		p := v.Q + (random_f64() * v.u) + (random_f64() * v.v)
		return p - origin
	case Sphere:
		return Vec3{1, 0, 0}
	}
	return Vec3{1, 0, 0}
}

mixture_pdf :: proc(p0, p1: ^Pdf) -> Pdf {
	mix: Mixture_Pdf
	mix.p[0] = p0
	mix.p[1] = p1
	return mix
}

sphere_pdf :: proc() -> Pdf {
	return Sphere_Pdf{}
}

hittable_pdf :: proc(objects: []^Hittable, origin: Point3) -> Pdf {
	return Hittable_Pdf{objects, origin}
}

cosine_pdf :: proc(w: Vec3) -> Pdf {
	return Cosine_Pdf{onb(w)}
}
