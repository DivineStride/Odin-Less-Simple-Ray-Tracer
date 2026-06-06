package raytracer

import "core:math"

aperture_from_fstop :: proc(focal_lenghth_mm: int, fstop: f64, focus_dist: f64) -> f64 {
	lens_radius := f64(focal_lenghth_mm) / (2 * fstop)

	return math.atan(lens_radius / focus_dist)
}

vfov_from_focal_length :: proc(focal_length_mm: int) -> f64 {
	return math.to_degrees(2 * math.atan(36.0 / (2 * f64(focal_length_mm))))
}
