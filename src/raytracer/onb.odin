package raytracer

import "core:math"
import "core:math/linalg"

Onb :: struct {
	axis: [3]Vec3,
}

onb_u :: proc(onb: ^Onb) -> Vec3 {
	return onb.axis[0]
}

onb_v :: proc(onb: ^Onb) -> Vec3 {
	return onb.axis[1]
}

onb_w :: proc(onb: ^Onb) -> Vec3 {
	return onb.axis[2]
}

onb :: proc(n: Vec3) -> Onb {
	onb: Onb
	onb.axis[2] = linalg.normalize(n)
	a := math.abs(onb.axis[2].x) > 0.9 ? Vec3{0, 1, 0} : Vec3{1, 0, 0}
	onb.axis[1] = linalg.normalize(linalg.cross(onb.axis[2], a))
	onb.axis[0] = linalg.cross(onb.axis[2], onb.axis[1])

	return onb
}

onb_transform :: proc(onb: ^Onb, v: Vec3) -> Vec3 {
	return (v[0] * onb.axis[0]) + (v[1] * onb.axis[1]) + (v[2] * onb.axis[2])
}
