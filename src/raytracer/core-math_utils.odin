package raytracer

import "core:math"
import "core:math/linalg"
import "core:math/rand"

Vec3 :: linalg.Vector3f64

degrees_to_radians :: proc(degrees: f64) -> f64 {
	return degrees * math.PI / 180.0
}

random_f64 :: proc() -> f64 {
	return rand.float64()
}

random_f64_range :: proc(min, max: f64) -> f64 {
	return rand.float64_range(min, max)
}

random_int :: proc(min, max: int) -> int {
	return rand.int_range(min, max)
}

near_zero :: proc(v: Vec3) -> bool {
	// Return true if the vector is close to zero in all dimensions
	s := 1e-8
	return abs(v.x) < s && abs(v.y) < s && abs(v.z) < s
}

random_vec3 :: proc() -> Vec3 {
	return Vec3{random_f64(), random_f64(), random_f64()}
}

random_vec3_range :: proc(min, max: f64) -> Vec3 {
	return Vec3{random_f64_range(min, max), random_f64_range(min, max), random_f64_range(min, max)}
}

sample_square :: proc() -> Vec3 {
	// Returns the vector to a random point in the [-.5, -.5] - [+.5, +.5] unit square
	return Vec3{random_f64() - 0.5, random_f64() - 0.5, 0}
}

random_unit_vector :: proc() -> Vec3 {
	for {
		p := random_vec3_range(-1, 1)
		lensq := linalg.dot(p, p)
		if 1e-160 < lensq && lensq <= 1 {
			return p / math.sqrt_f64(lensq)
		}
	}
}

random_on_hemisphere :: proc(normal: Vec3) -> Vec3 {
	on_unit_sphere := random_unit_vector()
	if linalg.dot(on_unit_sphere, normal) > 0.0 {
		return on_unit_sphere
	}
	return -on_unit_sphere
}
