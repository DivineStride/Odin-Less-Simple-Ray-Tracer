package raytracer

import "core:fmt"
import "core:math"

Color :: Vec3

linear_to_gamma :: proc(linear_component: f64) -> f64 {
	if linear_component > 0 {
		return math.sqrt_f64(linear_component)
	}

	return 0
}

color_to_xrgb :: proc(pixel_color: Color, ev_scale: f64) -> u32 {
	r := pixel_color.x * ev_scale
	g := pixel_color.y * ev_scale
	b := pixel_color.z * ev_scale

	// Apply a linear to gamma transform for gamma 2
	r = linear_to_gamma(r)
	g = linear_to_gamma(g)
	b = linear_to_gamma(b)

	// Translate the [0, 1] component values to the byte range [0, 255]
	intensity := Interval{0.000, 0.999}
	rbyte := u32(256 * clamp(intensity, r))
	gbyte := u32(256 * clamp(intensity, g))
	bbyte := u32(256 * clamp(intensity, b))

	return (rbyte << 16) | (gbyte << 8) | bbyte
}

write_color :: proc(pixel_color: Color, ev_scale: f64) {
	r := pixel_color.x * ev_scale
	g := pixel_color.y * ev_scale
	b := pixel_color.z * ev_scale

	// Apply a linear to gamma transform for gamma 2
	r = linear_to_gamma(r)
	g = linear_to_gamma(g)
	b = linear_to_gamma(b)

	// Translate the [0, 1] component values to the byte range [0, 255]
	intensity := Interval{0.000, 0.999}

	rbyte := int(256 * clamp(intensity, r))
	gbyte := int(256 * clamp(intensity, g))
	bbyte := int(256 * clamp(intensity, b))

	fmt.printfln("%d %d %d", rbyte, gbyte, bbyte)
}
